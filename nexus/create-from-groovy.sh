#!/bin/bash

name=$1
groovy=$2

printf "Creating Integration API Script from $groovy\n\n"

curl -v -u admin:$PASSWORD --header "Content-Type: application/json" "$NEXUS/service/siesta/rest/v1/script/" -d \
"
{
  \"name\": \"$name\",
  \"type\": \"groovy\",
  \"content\": \"$(cat $groovy |sed 's/$/\\n/g'|tr '\n' ' '|sed 's/"/\\"/g')\"
}"

