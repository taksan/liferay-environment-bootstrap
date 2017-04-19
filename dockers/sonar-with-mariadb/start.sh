#chcon -Rt svirt_sandbox_file_t /opt/sonar-data /opt/sonar-mysql
docker rm lf-sonar-mdb
docker run -p 9000:9000 --name lf-sonar-mdb -p 3306:3306 -v /opt/sonar-data:/opt/sonarqube/data  -v /opt/sonar-mariadb:/var/lib/mysql --rm -it devopsobj/sonar-with-mariadatabase
