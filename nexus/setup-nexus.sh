export NEXUS=https://gs-nexus.liferay.com

./delete.sh findassets || true
./create-from-groovy.sh findassets findassets.groovy
