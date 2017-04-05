FROM ubuntu:xenial

ENV JENKINS_HOME=/var/lib/jenkins/

RUN mkdir -p $JENKINS_HOME \
    mkdir -p $JENKINS_HOME/setup

COPY jenkins_install.sh /tmp/

RUN /tmp/jenkins_install.sh

VOLUME $JENKINS_HOME

RUN mkdir -p /opt/jenkins

RUN echo -n

COPY run.sh setup.sh install-control.sh *.tpl scriptApproval.xml *.txt *.xml /opt/jenkins/

COPY 001-jenkins-guide.conf /etc/apache2/sites-enabled/

COPY down.html /var/www/html/

WORKDIR /opt/jenkins

ENTRYPOINT ["./run.sh"]
