#!/bin/bash

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
# Makefile for automated provisioning and test runs on Debian-based systems.
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

# RAM size in kB.
memory_size		:= $(shell cat /proc/meminfo | grep -i memtotal | tr -s ' ' | cut -d' ' -f2)
# InnoDB buffer pool size, approx. 75% of RAM size.
innodb_buffer_size	:= $(shell echo 'scale=0; $(memory_size) / 4 * 3' | bc)
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
sysbench_threads	:= 4
# Maximum number of requests performed by sysbench (0 = unlimited).
sysbench_max_requests	:= 0
# Maximum amount of time a single benchmark will run (seconds).
sysbench_max_time	:= 30

# ------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

# Default: Install prerequisites and run benchmarks.
all: install-all benchmark

# Run all the benchmarks
benchmark:
	cp assets/image.png /tmp/
	chmod 777 /tmp/image.png
	cp assets/description.txt /tmp/
	chmod 777 /tmp/description.txt
	./run_tests.sh -d $(folder_tests) -n $(sysbench_threads) -o $(folder_results) -r $(sysbench_max_requests) -s $(schema_test) -t $(sysbench_max_time) -x $(schema_data)

# Uninstall everything and tidy up.
clean:
	$(purge) software-properties-common mariadb-server mariadb-common sysbench
	rm -f /etc/apt/sources.list.d/mariadb.list
	rm -f /etc/apt/sources.list.d/percona.list
	$(refresh)
	rm -Rf $(folder_results)

# Install all prerequisites.
install-all: update install-mariadb install-sysbench

# Unattended MariaDB installation.
# http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
# https://downloads.mariadb.org/mariadb/repositories/#mirror=tweedo&distro=Debian&distro_release=wheezy&version=10.1
install-mariadb:
	$(install) software-properties-common
	apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
	cp package-repositories/mariadb.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/mariadb.list
	$(refresh)
	echo 'mariadb-server	mysql-server/root_password	password  ' | debconf-set-selections
	echo 'mariadb-server	mysql-server/root_password_again	password  ' | debconf-set-selections
	$(install) mariadb-server
	sed -e 's/##INNODB_BUFFER_POOL_SIZE##/$(innodb_buffer_size)k/' config/my.ini > /etc/mysql/my.cnf
	service mysql restart

# Sysbench installation.
# http://www.ubuntuupdates.org/ppa/percona_server_with_xtradb?dist=trusty
install-sysbench:
	gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
	gpg -a --export CD2EFD2A | apt-key add -
	cp package-repositories/percona.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/percona.list
	$(refresh)
	$(install) sysbench

# Update the operating system and pre-installed packages.
update:
	$(refresh)
	$(update)
