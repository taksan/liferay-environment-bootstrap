#!/bin/bash

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

cd $(dirname $(readlink -f $0))
echo "Starting Dashing"
export DATA_DIR=/opt/dashboard_config
chown -R 1000:1000 $DATA_DIR 
if [[ ! -e $DATA_DIR/projects.yml ]]; then
    echo "If you wish, you can configure a volume to an external configuration directory starting docker with: -v /path/to/external/data:$DATA_DIR"
fi
if [[ ! -e $DATA_DIR/jenkins.yml ]]; then
    echo "jenkins.yml missing"
    exit 1
fi

stdbuf -o 0 smashing start 2>&1 | tee -a $DATA_DIR/smashing.log
