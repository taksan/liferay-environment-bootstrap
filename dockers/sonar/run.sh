#!/bin/bash

set -e

function startmysql()
{
	/etc/init.d/mysql start

	echo "Starting MySQL"
	while ! mysqladmin ping -h"localhost" --silent; do
		echo -n .
    	sleep 1
	done
    echo
	echo "Startup complete"
}

function readpassword()
{
    local DEFAULT_PASS=$2
	local PASSWORD_CONFIRMED=false
    local PASSWORD CONFIRMATION
	while ! $PASSWORD_CONFIRMED; do
		read -s -p "Type password (default=$DEFAULT_PASS) "  PASSWORD
		echo 
		if [[ -z "$PASSWORD" ]]; then
            if [[ -z "$DEFAULT_PASS" ]]; then
                echo "Password should not be empty"
                continue
            fi
			echo "Empty password given. Setting password to the defaul value: $DEFAULT_PASS"
            PASSWORD=$2
			PASSWORD_CONFIRMED=true
		else
			read -s -p "Confirm the password: " CONFIRMATION
			echo
		fi  
		[[ "$PASSWORD" == "$CONFIRMATION" ]] && PASSWORD_CONFIRMED=true
		if ! $PASSWORD_CONFIRMED; then
			echo "Passwords don't match"
		fi  
	done
    eval "$1=$PASSWORD"exec 
}

if [ "${1:0:1}" != '-' ]; then
  exec "$@"
fi

if [[ ! -e /var/lib/mysql/mysql ]]; then
    DEFAULT_PASSWORD=r3m3mb3r
    echo "## First time execution... preparing MySQL"
    # setup mysql for first run, which might be on a mapped volume
    cp -rf /opt/mysql/* /var/lib/mysql/
    chown -R mysql:mysql /var/lib/mysql/
    rm -rf /opt/mysql

    echo "## Type the root password"
    readpassword MYSQL_ROOT_PASSWORD $DEFAULT_PASSWORD

    startmysql

    mysql=( mysql -uroot -hlocalhost --password=$DEFAULT_PASSWORD )


    if [[ ! -z "$MYSQL_ROOT_PASSWORD" ]]; then
        echo $MYSQL_ROOT_PASSWORD > /etc/mysql.root.password
        mysqladmin -u root -p"$DEFAULT_PASSWORD" password $(cat /etc/mysql.root.password)
    fi

else
    # this might either be true because of an external directory setup or because this is a docker start
	startmysql
fi 
mysql=( mysql -uroot -hlocalhost --password=$(cat /etc/mysql.root.password))


SONARQUBE_JDBC_URL=jdbc:mysql://localhost:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true

cd $SONARQUBE_HOME
FIRST_TIME=false
if [[ ! -e sonar.password ]]; then
    echo "## Sonar setup"
    FIRST_TIME=true
    echo "## Type sonar user's password (user will be sonar)"
    readpassword SONAR_PASSWORD sonar

    echo "CREATE USER 'sonar'@'%' IDENTIFIED BY '$SONAR_PASSWORD' ;" | "${mysql[@]}"
    echo $SONAR_PASSWORD > $SONARQUBE_HOME/sonar.password
fi

SONAR_PASSWORD=$(cat sonar.password)
if [[ -e /var/log/sonar.log ]]; then
    mv /var/log/sonar.log /var/log/sonar.log.$(date +%Y%m%d%H%M%S)
fi
java -jar lib/sonar-application-$SONAR_VERSION.jar \
  -Dsonar.log.console=true \
  -Dsonar.jdbc.username="sonar" \
  -Dsonar.jdbc.password="$SONAR_PASSWORD" \
  -Dsonar.jdbc.url="$SONARQUBE_JDBC_URL" \
  -Dsonar.web.javaAdditionalOpts="$SONARQUBE_WEB_JVM_OPTS -Djava.security.egd=file:/dev/./urandom" \
  "$@" | tee /var/log/sonar.log &

if $FIRST_TIME; then
    echo "## Waiting sonar startup"
    while ! grep -q "SonarQube is up" /var/log/sonar.log; do
        sleep 1
    done
    echo
    echo "## Sonar ready. Setting up quality profiles..."
    echo "1. Fetching..."
    LANGUAGES="java js web"
    for L in $LANGUAGES; do
        curl -s -u admin:'R3m3mb3r1!' -X GET "http://cloud-10-0-40-8.liferay.com/api/qualityprofiles/export?language=$L" > /tmp/sonar-$L-way.xml
    done
    echo "2. restoring"
    for F in /tmp/sonar-*; do
        echo "Restroing $F"
        curl -s -X POST -u admin:admin "http://localhost:9000/api/qualityprofiles/restore" --form backup=@$F
    done
    echo "## Quality profile setup complete"
    echo "Sonar basic setup complete." 
    cat << EOF
        #########################################################
        # Access sonar at http://localhost:9000                 #
        #                                                       #
        # Admin user and password:                              #
        #                          admin/admin                  #
        #                                                       #
        # Access sonar and change the password if you wish      #
        #                                                       #
        # To complete setup, access the following URL:          #
        #                                                       #
        #    http://localhost:9000/settings/?category=web       #
        #                                                       #
        # And enter the following in the 'File suffixes' input: #
        #                                                       #
        #   .html,.xhtml,.rhtml,.shtml,.jsp,.jspf               #
        #                                                       #
        #########################################################
EOF
fi

fg