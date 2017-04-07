#!/bin/bash

cd $(dirname $(readlink -f $0))
echo "Starting Dashing"
export DATA_DIR=/opt/dashboard_config
chown -R 1000:1000 $DATA_DIR 
if [[ ! -e $DATA_DIR/projects.yml ]]; then
    echo "If you wish, you can configure a volume to an external configuration directory starting docker with: -v /path/to/external/data:$DATA_DIR"
fi
stdbuf -o 0 smashing start 2>&1 | tee -a /var/log/smashing.log
