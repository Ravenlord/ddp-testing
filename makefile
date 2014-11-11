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
# Configuration file for TLS session ticket rotation program.
#
# AUTHOR: Markus Deutschl <deutschl.markus@gmail.com>
# COPYRIGHT: Copyright (c) 2014 Markus Deutschl
# LICENSE: http://unlicense.org/ PD
# ------------------------------------------------------------------------------

all: update install-all

clean:
	aptitude -y purge php5-common php5-cli php5-mysqlnd software-properties-common mariadb-server mariadb-common sysbench
	rm -f /etc/apt/sources.list.d/mariadb.list
	rm -f /etc/apt/sources.list.d/percona.list
	aptitude -y update

install-all: install-php install-mariadb install-sysbench

install-mariadb:
	aptitude -y install software-properties-common
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
	cp mariadb.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/mariadb.list
	aptitude -y update
	aptitude -y install mariadb-server

install-php:
	aptitude -y install php5-common php5-cli php5-mysqlnd

# http://www.ubuntuupdates.org/ppa/percona_server_with_xtradb?dist=trusty
install-sysbench:
	gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
	gpg -a --export CD2EFD2A | apt-key add -
	cp percona.list /etc/apt/sources.list.d/
	chmod 644 /etc/apt/sources.list.d/percona.list
	aptitude -y update
	aptitude -y install sysbench

update:
	aptitude -y update
	aptitude -y upgrade
