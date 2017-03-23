#!/bin/bash

cd $(dirname $(readlink -f $0))
echo "Starting Dashing"
export DATA_DIR=/opt/dashboard_config
stdbuf -o 0 smashing start 2>&1 | tee -a /var/log/smashing.log
