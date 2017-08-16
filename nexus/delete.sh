#!/bin/bash

set -e
name=$1

printf "Deleting Integration API Script $name\n\n"

curl --fail-early -s -X DELETE -u admin:$PASSWORD  "$NEXUS/service/siesta/rest/v1/script/$name"
