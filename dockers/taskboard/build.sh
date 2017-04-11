#!/bin/bash

set -e

TASKBOARD_VERSION=0.0.4

if [[ ! -e taskboard.war ]]; then
	curl -o taskboard.war http://repo:8080/archiva/repository/internal/br/com/objective/taskboard/${TASKBOARD_VERSION}/taskboard-${TASKBOARD_VERSION}.war
fi
sudo docker build -t 'devopsobj/objective-taskboard' .
