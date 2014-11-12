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
# Makefile for automated provisioning and test runs.
#
# AUTHOR: Markus Deutschl <deutschl.markus@gmail.com>
# COPYRIGHT: Copyright (c) 2014 Markus Deutschl
# LICENSE: http://unlicense.org/ PD
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

package_manager		:= aptitude -y
install			:= $(package_manager) install
purge			:= $(package_manager) purge
refresh			:= $(package_manager) update
update			:= $(package_manager) upgrade

# Output folder for the benchmark logs.
folder_results		:= results
# Folder containing the Lua test files for sysbench.
folder_tests		:= tests
# Schema containing tables for populating test data.
schema_data		:= data
# Schema for the actual benchmarks.
schema_test		:= test
# The database user sysbench will use.
sysbench_db_user	:= root
# Number of threads for the benchmark.
sysbench_threads	:= 8
# Maximum number of requests performed by sysbench (0 = unlimited).
sysbench_max_requests	:= 0
# Maximum amount of time the benchmark will run (seconds).
sysbench_max_time	:= 10
# Concatenated sysbench options common to prepare and run commands.
sysbench_options	:= --mysql-db=$(schema_test) --mysql-user=$(sysbench_db_user) --test=
# Concatenated sysbench options for benchmark runs
sysbench_options_bench	:= --num-threads=$(sysbench_threads) --max-requests=$(sysbench_max_requests) --max-time=$(sysbench_max_time) $(sysbench_options)

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

# TODO: move into shell script.
define run_test
  # Check if there's a test to run.
  [ '$(1)' != '' ]

  $(eval test_name:=$(1:.lua=))

  @echo 'Starting test: $(test_name).'

  @echo 'Setting up test schema ($(schema_test)).'
  mysql -e 'DROP SCHEMA IF EXISTS `$(schema_test)`;'
  mysql -e 'CREATE SCHEMA `$(schema_test)`;'

  @echo 'Creating output directory.'
  mkdir -p $(folder_results)/$(test_name)

  @echo 'Preparing test data.'
  sysbench $(sysbench_options)$(folder_tests)/$1 prepare

  @echo 'Performing benchmark with parameters: Threads $(sysbench_threads), Maximum requests $(sysbench_max_requests), Maximum runtime $(sysbench_max_time).'
  sysbench $(sysbench_options_bench)$(folder_tests)/$1 run > $(folder_results)/$(test_name)/benchmark.log 2>&1
endef

# ------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

all: update install-all

benchmark:
	# TODO: make shell script conducting the benchmarks.

clean:
	$(purge) -y purge php5-common php5-cli php5-mysqlnd software-properties-common mariadb-server mariadb-common sysbench
	rm -f /etc/apt/sources.list.d/mariadb.list
	rm -f /etc/apt/sources.list.d/percona.list
	$(refresh)
	rm -Rf $(folder_results)

install-all: install-php install-mariadb install-sysbench

install-mariadb:
	$(install) software-properties-common
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	cp package-repositories/mariadb.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/mariadb.list
	$(refresh)
	$(install) mariadb-server

install-php:
	$(install) php5-common php5-cli php5-mysqlnd

# http://www.ubuntuupdates.org/ppa/percona_server_with_xtradb?dist=trusty
install-sysbench:
	gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
	gpg -a --export CD2EFD2A | apt-key add -
	cp package-repositories/percona.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/percona.list
	$(refresh)
	$(install) sysbench

update:
	$(refresh)
	$(update)
