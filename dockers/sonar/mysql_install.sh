#!/bin/bash

set -x 

debconf-set-selections <<< 'mysql-server mysql-server/root_password password r3m3mb3r' 
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password r3m3mb3r' 

apt-get -y install mysql-server
/etc/init.d/mysql stop

# moves directory so we can let the user provide an external mount dir
mv -v /var/lib/mysql /opt/
mkdir /var/lib/mysql

