FROM ubuntu:16.04

MAINTAINER Gabriel Takeuchi <gabriel.takeuchi@objective.com.br>

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV SONAR_VERSION=6.3
ENV SONARQUBE_HOME=/opt/sonarqube

# Http port
EXPOSE 9000 3306 33060

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        unzip \
        openjdk-8-jdk=8u131-b11-2ubuntu1.16.04.3

COPY mysql_install.sh /tmp
RUN /tmp/mysql_install.sh

COPY sonar*xml /tmp/

COPY sonar_install.sh /tmp/
RUN /tmp/sonar_install.sh

RUN rm -rf /var/lib/apt/lists/*

VOLUME "$SONARQUBE_HOME/data"
VOLUME /var/lib/mysql

WORKDIR $SONARQUBE_HOME
COPY run.sh $SONARQUBE_HOME/bin/
ENTRYPOINT ["./bin/run.sh"]
