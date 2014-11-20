#!/usr/bin/env sh

# ------------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Test runner for sysbench benchmarks
#
# AUTHOR: Markus Deutschl <deutschl.markus@gmail.com>
# COPYRIGHT: Copyright (c) 2014 Markus Deutschl
# LICENSE: http://unlicense.org/ PD
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# Print usage information.
#
# RETURN:
# 0 - Printing successful.
# 1 - Printing failed.
usage()
{
cat << EOT
Usage: ${0##*/} [options]... [tests]...
Run sysbench tests in a specified folder.

Tests: Overrides -d option. A list of .lua test files to execute.

Options:
-d Directory containing the test files, defaults to 'tests/'.
   Files named 'common.lua' are considered shared common properties
   for tests and are not executed.
   If a file named 'provision.lua' exists, it will be used to create the
   prerequisites of the test suite with an additional prepare command.
-n The number of thread sysbench will use, defaults to 8.
-o Output directory for benchmark logs, defaults to 'results/'.
-p The password sysbench will use for the database connection, defaults to none.
   It is highly recommended to use a user account with no password, since
   mysql client commands are run, which will prompt for a password otherwise.
-r Maximum requests sysbench will perform (0 = unlimited), defaults to 0.
-s The test database schema sysbench will use, defaults to 'test'.
-t Maximum time in seconds sysbench will run (0 = unlimited), defaults to 60.
-u The database user sysbench will use, defaults to 'root'.
-x The database schema used for populating test data, defaults to 'data'.
-h|? Print this text and exit.
Usage example: \`sh run_tests -d tests -t 300 --\`
EOT
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

# Directory containing sysbench test files.
DIR='tests/'
# Just a delimiter line for neat output.
LINE='--------------------------------------------------------------------------------'
# Number of threads used by sysbench
NUM_THREADS=8
# Output directory for log files
OUTPUT_DIR='results/'
# Database password for sysbench.
PASS=''
# Execute provisioning step and cleanup or not.
PROVISION=false
# Maximum number of requests performed by sysbench.
REQUESTS=0
# Database schema used for tests.
SCHEMA='test'
# Database schema used for populating test data.
SCHEMA_DATA='data'
# Concatenated options for sysbench runs.
SYSBENCH_OPTIONS=''
# Sysbench schema parameter.
SYSBENCH_SCHEMA='--mysql-db='
# Sysbench data schema parameter.
SYSBENCH_SCHEMA_DATA='--schema-data='
# List of test files to execute.
TESTS=''
# Maximum time in seconds the tests will run.
TIME=60
# Database user for sysbench.
USER='root'

# ------------------------------------------------------------------------------
# Program
# ------------------------------------------------------------------------------

# Check exit / return code of every command / function and bail if non-zero.
set -e

# Parse options.
while getopts 'd:hn:o:p:r:s:t:u:x:' OPTION
do
  case "${OPTION}" in
    d) DIR="${OPTARG}" ;;
    h|[?]) usage && exit 0 ;;
    n) NUM_THREADS="${OPTARG}" ;;
    o) OUTPUT_DIR="${OPTARG}" ;;
    p) PASS="${OPTARG}" ;;
    r) REQUESTS="${OPTARG}" ;;
    s) SCHEMA="${OPTARG}" ;;
    t) TIME="${OPTARG}" ;;
    u) USER="${OPTARG}" ;;
    x) SCHEMA_DATA="${OPTARG}" ;;
  esac
  # Remove parsed option from input.
  shift $(( $OPTIND - 1 ))
done

# Welcome message.
echo "\n${LINE}"
echo "Starting sysbench test suite runner."
echo "${LINE}\n"
echo "Test suite location: ${DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Number of threads per test: ${NUM_THREADS}"
echo "Maximum requests per test: ${REQUESTS}"
echo "Maximum runtime per test: ${TIME}"

# Prepare sysbench options.
DIR="${DIR%/}/"
OUTPUT_DIR="${OUTPUT_DIR%/}/"
[ -n "${NUM_THREADS}" ] && NUM_THREADS="--num-threads=${NUM_THREADS}"
[ -n "${PASS}" ] && MYSQL_PASS=" -p" && PASS="--mysql-password=${PASS}"
[ -n "${REQUESTS}" ] && REQUESTS="--max-requests=${REQUESTS}"
[ -n "${SCHEMA}" ] && SYSBENCH_SCHEMA="${SYSBENCH_SCHEMA}${SCHEMA}"
[ -n "${TIME}" ] && TIME="--max-time=${TIME}"
[ -n "${USER}" ] && MYSQL_USER=" -u ${USER}" && USER="--mysql-user=${USER}"
[ -n "${SCHEMA_DATA}" ] && SYSBENCH_SCHEMA_DATA="${SYSBENCH_SCHEMA_DATA}${SCHEMA_DATA}"

SYSBENCH_OPTIONS="${SYSBENCH_SCHEMA} ${SYSBENCH_SCHEMA_DATA} ${USER} --mysql-socket=/var/run/mysqld/mysqld.sock --test="

# Prepare test case names. If we have arguments, interpret them as test cases to execute.
# Otherwise, take test cases from test directory.
if [ $# -gt 0 ]; then
  # We have arguments, just put them into the tests "array".
  TESTS=$@
  echo "Found argument(s), entering single test mode."
else
  # Obtain the tests list from the test directory with their correct path.
  TESTS=$(ls ${DIR}*.lua)
  PROVISION=true
  echo "No arguments specified, entering bulk mode with provisioning."
fi

# Check if test suite provisioning file exists and execute the prepare step.
if [ ${PROVISION} = true -a -f "${DIR}provision.lua" ]; then
  echo "Found provisioning file 'provision.lua', starting test suite preparations."
  echo "Creating test data schema: ${SCHEMA_DATA}"
  mysql ${MYSQL_USER}${MYSQL_PASS} -e "DROP SCHEMA IF EXISTS ${SCHEMA_DATA};"
  mysql ${MYSQL_USER}${MYSQL_PASS} -e "CREATE SCHEMA ${SCHEMA_DATA};"
  # This is needed for convenience.
  mysql ${MYSQL_USER}${MYSQL_PASS} -e "CREATE SCHEMA IF NOT EXISTS ${SCHEMA};"
  echo "Preparing test data"
  sysbench ${SYSBENCH_OPTIONS}${DIR}provision.lua prepare > /dev/null 2>&1
fi

# Process all tests specified either from directory or arguments.
for TEST in ${TESTS}
do
  TEST_NAME=$(basename ${TEST})
  if [ ${TEST_NAME} != 'common.lua' -a ${TEST_NAME} != 'provision.lua' ]; then
    echo "\n${LINE}"
    echo ${TEST}
    echo "${LINE}\n"
    echo "Starting test: ${TEST}"
    echo "Creating test schema: ${SCHEMA}"
    mysql ${MYSQL_USER}${MYSQL_PASS} -e "DROP SCHEMA IF EXISTS ${SCHEMA};"
    mysql ${MYSQL_USER}${MYSQL_PASS} -e "CREATE SCHEMA ${SCHEMA};"
    echo "Preparing benchmark"
    sysbench ${SYSBENCH_OPTIONS}${TEST} prepare > /dev/null 2>&1
    mkdir -p ${OUTPUT_DIR}${TEST_NAME}
    echo "Restarting MySQL server"
    service mysql restart
    echo "Running benchmark"
    sysbench ${NUM_THREADS} ${REQUESTS} ${TIME} ${SYSBENCH_OPTIONS}${TEST} run > ${OUTPUT_DIR}${TEST_NAME}/benchmark.log 2>&1
    echo "Cleaning up test schema: ${SCHEMA}"
    mysql ${MYSQL_USER}${MYSQL_PASS} -e "DROP SCHEMA IF EXISTS ${SCHEMA};"
    echo "Completed test: ${TEST}"
  fi
done

echo "\n${LINE}"
echo "Test suite completed."
echo "${LINE}\n"

# Only clean up data schema if it was created by the test runner.
if [ ${PROVISION} = true -a -f "${DIR}provision.lua" ]; then
  echo "Cleaning up test data schema: ${SCHEMA_DATA}"
  mysql ${MYSQL_USER}${MYSQL_PASS} -e "DROP SCHEMA IF EXISTS ${SCHEMA_DATA};"
fi
echo "Success, all done!\n"
