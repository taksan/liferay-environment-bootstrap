FROM openjdk:8

MAINTAINER DevOps @ Objective <devops@objective.com.br>

ENV TASKBOARD_HOME=/opt/taskboard 

# Http port
EXPOSE 8080

RUN set -x \
	&& mkdir -p $TASKBOARD_HOME \
	&& mkdir -p /opt/taskboard_config

WORKDIR $TASKBOARD_HOME
COPY start.sh $TASKBOARD_HOME/
COPY taskboard.war $TASKBOARD_HOME/

VOLUME /opt/taskboard_config
ENTRYPOINT ["./start.sh"]
