#!/bin/bash
set -e

function main()
{
    chown -R jenkins:jenkins .

    waitUntilJenkinsIsReadyToSetup

    service jenkins stop
    waitUntilJenkinsStop

    wget http://updates.jenkins-ci.org/latest/http_request.hpi -O $JENKINS_HOME/plugins/http_request.hpi

    setJenkinsDescription instructions_step1.txt
    mkdir -p $JENKINS_HOME/jobs/BOOTSTRAP_SETUP
    cp bootstrap_setup_config.xml $JENKINS_HOME/jobs/BOOTSTRAP_SETUP/config.xml
    chown -R jenkins:jenkins $JENKINS_HOME/

    service jenkins start
    waitUntilJenkinsIsReadyToSetup

    echo "Visit jenkins URL at http://localhost:8080 and perform the initial setup. The initial password is:"
    echo
    echo "      $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
    echo 
    echo " # When asked to 'Customize Jenkins', choose 'Install suggested plugins'"
    echo " # After the plugins are installed, fill out the admin information and finally click on 'Save and Finish'"
    echo " # Jenkins will be restarted after you save, so make sure you refresh it until you get the login page"
    echo

    waitUntilConfigurationIsComplete

    sleep 5
    echo "Initial setup complete, restarting jenkins"
    service jenkins stop
    waitUntilJenkinsStop
    rm -f /var/log/jenkins/jenkins.log

    setJenkinsDescription instructions_step2.txt

    cp scriptApproval.xml $JENKINS_HOME/scriptApproval.xml
    service jenkins start

    waitUntilSetupJobIsExecuted

    service jenkins stop
    waitUntilJenkinsStop

    setJenkinsDescription instructions_step3.txt

    rm -rf $JENKINS_HOME/jobs/BOOTSTRAP_SETUP
}

function waitUntilSetupJobIsExecuted(){
    while [[ ! -e /opt/jenkins/setup-complete ]]; do 
        sleep 1
    done
}

function waitUntilJenkinsStop()
{
    if [[ ! -e /var/run/jenkins/jenkins.pid ]]; then
        return
    fi
    JENKINS_PID=$(cat /var/run/jenkins/jenkins.pid)
    while kill -0 $JENKINS_PID 2>/dev/null; do
        sleep 1
    done
}

function setJenkinsDescription() {
(
    sed '/<description>/,/<\/description>/d' -i $JENKINS_HOME/config.xml

    IFS=
    while read A; do 
        if [[ $A =~ .*[^/]hudson.model.AllView* ]]; then 
            echo $A
            echo "<description>"
            cat "$1"
            echo "</description>"
        else 
            echo "$A"; 
        fi; 
    done > /tmp/config.xml < $JENKINS_HOME/config.xml
    echo $A >> /tmp/config.xml
    cp /tmp/config.xml $JENKINS_HOME/config.xml
)
}

function waitUntilConfigurationIsComplete()
{
    ADMIN_CONFIG_FILE=$JENKINS_HOME/users/admin/config.xml
    INITIAL_MD5=$(md5sum $ADMIN_CONFIG_FILE)
    while true; do
        if [[ ! -e $ADMIN_CONFIG_FILE ]]; then
            echo $ADMIN_CONFIG_FILE not found
            break;
        fi
        NEW_MD5=$(md5sum $ADMIN_CONFIG_FILE)
        if [[ ! $INITIAL_MD5 == $NEW_MD5 ]]; then
            if grep -q email $ADMIN_CONFIG_FILE; then 
                break;
            fi
            INITIAL_MD5=$NEW_MD5
        fi
        sleep 5
    done
}

function waitUntilJenkinsReady() {
    while ! grep -q "com.cloudbees.plugins.credentials.SystemCredentialsProvider <init>" /var/log/jenkins/jenkins.log; do
        sleep 1
    done
}

function waitUntilJenkinsIsReadyToSetup() {
    echo "## Waiting until jenkins is ready for setup"
    while ! grep -q "/var/lib/jenkins/secrets/initialAdminPassword" /var/log/jenkins/jenkins.log; do
        sleep 1
    done
}

main "$@"
