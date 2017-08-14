#!/bin/bash

name=$1

printf "Deleting Integration API Script $name\n\n"

curl -v -X DELETE -u admin:$PASSWORD  "$NEXUS/service/siesta/rest/v1/script/$name"
