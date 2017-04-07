#!/bin/bash

cd $(dirname $(readlink -f $0))
if [[ ! -e /opt/taskboard_config/application-dev.properties ]]; then
	echo "You should provide application-dev.properties file to configure the taskboard. Run docker with -v /path/to/configuration:/opt/taskboard_config"
	exit 1
fi
java -cp taskboard.war:/opt/taskboard_config org.springframework.boot.loader.WarLauncher | tee /opt/taskboard_config/taskboard.log
