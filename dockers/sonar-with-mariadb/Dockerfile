FROM openjdk:8

MAINTAINER Gabriel Takeuchi <gabriel.takeuchi@objective.com.br>

ENV SONAR_VERSION=6.3 \
    SONARQUBE_HOME=/opt/sonarqube 

# Http port
EXPOSE 9000 3306 33060

RUN apt-get update

RUN wget http://downloads.mariadb.com/MariaDB/mariadb-10.1.22/repo/debian/mariadb-10.1.22-debian-jessie-amd64-debs.tar

COPY sonar_install.sh /tmp
RUN /tmp/sonar_install.sh

COPY mysql_install.sh /tmp
RUN /tmp/mysql_install.sh

VOLUME "$SONARQUBE_HOME/data"
VOLUME /var/lib/mysql

WORKDIR $SONARQUBE_HOME
COPY run.sh $SONARQUBE_HOME/bin/
ENTRYPOINT ["./bin/run.sh"]
