docker run -p 9000:9000 --name sonar-maria -p 3307:3306 -v /opt/sonar-maria-data:/opt/sonarqube/data -it devopsobj/sonar-with-mariadatabase
