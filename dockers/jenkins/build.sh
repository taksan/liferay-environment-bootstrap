#sudo docker build --no-cache=true -t 'liferay-jenkins' .
export SCRIPT_HASH=$(./hashCalculator.groovy bootstrap_setup_config.xml)
export GLOBALS_SCRIPT_HASH=$(./hashCalculator.groovy bootstrap_globals_config.xml)
envsubst < scriptApproval.tpl > scriptApproval.xml
sudo docker build -t 'liferay-jenkins' .
