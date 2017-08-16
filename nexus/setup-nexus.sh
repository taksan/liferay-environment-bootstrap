#!/bin/bash

set -e

export NEXUS=http://localhost:8081
#export NEXUS=https://gs-nexus-liferay-uat.objective.com.br

echo "Type the nexus admin password:"
read -s PASSWORD
export PASSWORD

./delete.sh findassets || true
./delete.sh setupsdlc  || true
./create-from-groovy.sh findassets findassets.groovy
./create-from-groovy.sh setupsdlc  setupsdlc.groovy
