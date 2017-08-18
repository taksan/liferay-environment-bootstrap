#!/bin/bash

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

TASKBOARD_DATA=/opt/taskboard_config

cd $(dirname $(readlink -f $0))
if [[ ! -e $TASKBOARD_DATA/application-dev.properties ]]; then
	echo "You should provide application-dev.properties file to configure the taskboard. Run docker with -v /path/to/configuration:/opt/taskboard_config"
	exit 1
fi
TS=$(date +%Y%m%d%H%M%S)
cp $TASKBOARD_DATA/taskboard.log $TASKBOARD_DATA/taskboard.log.$TS

WAR_PATH=$(pwd)
cd $TASKBOARD_DATA
java $TASKBOARD_XMX_XMS -cp $TASKBOARD_DATA:$WAR_PATH/taskboard.war org.springframework.boot.loader.WarLauncher --server.port=8082 | tee  $TASKBOARD_DATA/taskboard.log
