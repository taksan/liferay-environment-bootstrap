#!/bin/bash

set -x -e

apt-get install -y software-properties-common python-software-properties

debconf-set-selections <<< 'mysql-server mysql-server/root_password password r3m3mb3r' 
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password r3m3mb3r' 

apt-get update
apt-get -y install mysql-server-5.7
apt-get -y install mysql-client-5.7

/etc/init.d/mysql stop

# moves directory so we can let the user provide an external mount dir
mv -v /var/lib/mysql /opt/
mkdir /var/lib/mysql

