cd resources
export SCRIPT_HASH=$(./hashCalculator.groovy bootstrap_setup_config.xml)
export GLOBALS_SCRIPT_HASH=$(./hashCalculator.groovy bootstrap_globals_config.xml)
envsubst < scriptApproval.tpl > scriptApproval.xml
cd ..

#sudo docker build --no-cache=true -t 'liferay-jenkins' .
sudo docker build -t 'devopsobj/liferay-jenkins' .
