mkdir -p /opt/sonar-data /opt/sonar-mysql
#chcon -Rt svirt_sandbox_file_t /opt/sonar-data /opt/sonar-mysql
docker run -p 9000:9000 --name lf-sonar -p 3306:3306 -v /opt/sonar-data:/opt/sonarqube/data  -v /opt/sonar-mysql:/var/lib/mysql -it devopsobj/sonar-with-database
