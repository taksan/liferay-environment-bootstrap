FROM ubuntu:xenial

ENV JENKINS_HOME=/var/lib/jenkins/

RUN mkdir -p $JENKINS_HOME \
    mkdir -p $JENKINS_HOME/setup

COPY jenkins_install.sh /tmp/

RUN /tmp/jenkins_install.sh

VOLUME $JENKINS_HOME

RUN mkdir -p /opt/jenkins

COPY run.sh setup.sh *.tpl scriptApprovals.xml /opt/jenkins/

WORKDIR /opt/jenkins

ENTRYPOINT ["./run.sh"]
