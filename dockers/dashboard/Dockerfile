FROM ubuntu

MAINTAINER DevOps @ Objective <devops@objective.com.br>

ENV DASHBOARD_HOME=/opt/liferay_dashing
RUN apt-get update \
	&& apt-get install -y ruby ruby-dev libmysqlclient-dev libssl-dev openssl gcc make g++ unzip curl nodejs \
	&& gem install smashing \
	&& gem install bundle

# Http port
EXPOSE 3030

WORKDIR $DASHBOARD_HOME
COPY liferay_dashing.tar.gz /opt/

RUN set -x \
	&& cd /opt/ \
	&& tar xvzf liferay_dashing.tar.gz \
	&& rm -f liferay_dashing.tar.gz \
	&& mkdir dashboard_config \
	&& cd $DASHBOARD_HOME \
	&& bundle install

VOLUME /opt/dashboard_config

COPY start.sh $DASHBOARD_HOME

ENTRYPOINT ["./start.sh"]
