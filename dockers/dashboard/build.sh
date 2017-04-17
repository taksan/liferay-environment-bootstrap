#!/bin/bash

set -e

git clone http://builder:rhdes@gitlab/devops/liferay_dashing.git
rm -rf liferay_dashing/.git
tar czf liferay_dashing.tar.gz liferay_dashing
sudo docker build --no-cache=true -t 'liferay-smashing' .
rm -rf liferay_dashing liferay_dashing.tar.gz
