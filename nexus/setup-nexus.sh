#!/bin/bash

set -e

export NEXUS=${1:?}

echo "Type the nexus admin password:"
read -s PASSWORD
export PASSWORD

./delete.sh findassets || true
./delete.sh setupsdlc  || true
./create-from-groovy.sh findassets findassets.groovy
./create-from-groovy.sh setupsdlc  setupsdlc.groovy
