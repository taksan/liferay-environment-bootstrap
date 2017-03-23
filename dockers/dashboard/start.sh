#!/bin/bash

cd $(dirname $(readlink -f $0))
echo "Starting Dashing"
export DATA_DIR=/opt/dashboard_config
if [[ ! -e $DATA_DIR/projects.json ]]; then
    echo "If you wish, you can configure a volume to an external configuration directory starting docker with: -v /path/to/external/data:$DATA_DIR"
fi
stdbuf -o 0 smashing start 2>&1 | tee -a /var/log/smashing.log
