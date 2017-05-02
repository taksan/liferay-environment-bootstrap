#!/bin/bash

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi


cd $(dirname $(readlink -f $0))
if [[ ! -e /opt/taskboard_config/application-dev.properties ]]; then
	echo "You should provide application-dev.properties file to configure the taskboard. Run docker with -v /path/to/configuration:/opt/taskboard_config"
	exit 1
fi
java -cp /opt/taskboard_config:taskboard.war org.springframework.boot.loader.WarLauncher --server.port=8082 | tee /opt/taskboard_config/taskboard.log
