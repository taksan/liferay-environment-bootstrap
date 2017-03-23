#!/bin/bash

set -x -e 
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE 

cd /opt 
curl -o sonarqube.zip -fSL https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip 
curl -o sonarqube.zip.asc -fSL https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc 
gpg --batch --verify sonarqube.zip.asc sonarqube.zip 
unzip sonarqube.zip 
mv sonarqube-$SONAR_VERSION sonarqube
rm sonarqube.zip* 
rm -rf $SONARQUBE_HOME/bin/*

PLUGINS_DIR=$SONARQUBE_HOME/extensions/plugins
curl -L -o $PLUGINS_DIR/sonar-build-breaker-plugin-2.1.jar https://github.com/SonarQubeCommunity/sonar-build-breaker/releases/download/2.1/sonar-build-breaker-plugin-2.1.jar
curl -L -o $PLUGINS_DIR/sonar-github-plugin-1.4.0.699.jar https://sonarsource.bintray.com/Distribution/sonar-github-plugin/sonar-github-plugin-1.4.0.699.jar
curl -L -o $PLUGINS_DIR/sonar-web-plugin-2.5-RC1.jar https://github.com/SonarSource/sonar-web/releases/download/2.5-RC1/sonar-web-plugin-2.5-RC1.jar
