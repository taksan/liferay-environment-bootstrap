#!/bin/bash

set -x 

apt-get install -y software-properties-common python-software-properties

debconf-set-selections <<< 'mysql-server mysql-server/root_password password r3m3mb3r' 
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password r3m3mb3r' 

add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe'
apt-get update
apt-get -y --force-yes install mysql-server-5.6
apt-get -y --force-yes install mysql-client-5.6

/etc/init.d/mysql stop

# moves directory so we can let the user provide an external mount dir
mv -v /var/lib/mysql /opt/
mkdir /var/lib/mysql

