apt-get update
apt-get install -y wget groovy curl gettext git vim less apache2

a2enmod ext_filter
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite 
a2enmod headers 

wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins --allow-unauthenticated


