#!/bin/bash

set -e

URL=$(curl -s "http://autotelebuild:8080/job/taskboard_github/api/xml?xpath=/mavenModuleSet/description" | sed "s/.*href='\([^']*\).*/\1/g")

curl -o taskboard.war "$URL"

sudo docker build -t 'devopsobj/objective-taskboard' .
sudo docker push devopsobj/objective-taskboard
