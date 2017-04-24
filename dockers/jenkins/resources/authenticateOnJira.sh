#!/bin/bash

set -e

JIRA="https://issues.liferay.com"
cd $(dirname $(readlink -f $0))

if [ "$U" == "admin" ] && [ "$P" == "$(cat _admin_password_)" ]; then
   exit 0
fi

# ensures the user can authenticate
curl -v -H "Content-Type: application/json" $JIRA/rest/auth/1/session -d'{"username":"'$U'","password":"'$P'"}'

# retrieves the projects the user has access to and store locally 
mkdir -p userProjects 
curl -u "$U:$P" "$JIRA/rest/api/2/project" | ./groups_extractor.py > userProjects/${U}.projects 2>/tmp/auth.log

