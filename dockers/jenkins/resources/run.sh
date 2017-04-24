#!/bin/bash
set -e

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

COMPLETE_FILE=$JENKINS_HOME/docker_setup_complete

service jenkins start

if [[ ! -e $COMPLETE_FILE ]]; then
    ./setup.sh
    service jenkins restart
    touch $COMPLETE_FILE
fi

tail -f /var/log/jenkins/jenkins.log
