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
curl -L -o $PLUGINS_DIR/sonar-csharp-plugin-5.10.0.1344.jar https://sonarsource.bintray.com/Distribution/sonar-csharp-plugin/sonar-csharp-plugin-5.10.0.1344.jar
curl -L -o $PLUGINS_DIR/sonar-scm-git-plugin-1.2.jar https://sonarsource.bintray.com/Distribution/sonar-scm-git-plugin/sonar-scm-git-plugin-1.2.jar
curl -L -o $PLUGINS_DIR/sonar-scm-svn-plugin-1.4.0.522.jar https://sonarsource.bintray.com/Distribution/sonar-scm-svn-plugin/sonar-scm-svn-plugin-1.4.0.522.jar
curl -L -o $PLUGINS_DIR/sonar-javascript-plugin-3.0.0.4962.jar https://sonarsource.bintray.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-3.0.0.4962.jar
curl -L -o $PLUGINS_DIR/sonar-java-plugin-4.9.0.9858.jar https://sonarsource.bintray.com/Distribution/sonar-java-plugin/sonar-java-plugin-4.9.0.9858.jar
