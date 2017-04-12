#!/bin/bash

set -x -e

tar xf mariadb-10.1.22-debian-jessie-amd64-debs.tar
cd mariadb-10.1.22-debian-jessie-amd64-debs
./setup_repository

apt-get update 

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server mysql-server/root_password password r3m3mb3r'
debconf-set-selections <<< 'mariadb-server mysql-server/root_password_again password r3m3mb3r'
apt-get install -y --force-yes mariadb-server 

# moves directory so we can let the user provide an external mount dir
mv -v /var/lib/mysql /opt/
mkdir /var/lib/mysql

