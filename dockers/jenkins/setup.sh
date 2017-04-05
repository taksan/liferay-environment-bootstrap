#!/bin/bash
set -e

function main()
{
    chown -R jenkins:jenkins .

    # wait first jenkins start to let it create default directories
    waitUntilJenkinsIsReadyToSetup

    stopAndWaitUntilFullyStopped
    fixGlobalNode
    sed 's/8080/8090/' -i /etc/default/jenkins
    sed 's/Listen 80/Listen 8080/' -i /etc/apache2/ports.conf
    service apache2 start >/dev/null 2>&1

    REQUIRED_PLUGINS="http_request.hpi uno-choice.hpi scriptler.hpi role-strategy.hpi"
    for P in $REQUIRED_PLUGINS; do
        echo "Installing required plugin : $P"
        wget -q http://updates.jenkins-ci.org/latest/$P -O $JENKINS_HOME/plugins/$P
    done

    cp instructions_step1.txt current_instructions.txt

    mkdir -p $JENKINS_HOME/jobs/BOOTSTRAP_SETUP
    mkdir -p $JENKINS_HOME/jobs/BOOTSTRAP_GLOBALS_SETUP
    cp bootstrap_setup_config.xml $JENKINS_HOME/jobs/BOOTSTRAP_SETUP/config.xml
    cp bootstrap_globals_config.xml $JENKINS_HOME/jobs/BOOTSTRAP_GLOBALS_SETUP/config.xml
    chown -R jenkins:jenkins $JENKINS_HOME/

    service jenkins start >/dev/null 2>&1
    waitUntilJenkinsIsReadyToSetup

    touch ready_to_setup

    cat /var/lib/jenkins/secrets/initialAdminPassword > initialAdminPassword

    echo "Visit jenkins URL at http://localhost:8080 and perform the initial setup."
    echo

    waitUntilConfigurationIsCompleteAndAdminIsCreated

    touch /var/www/html/adminUserExists

    echo "Initial setup complete, restarting jenkins"
    stopAndWaitUntilFullyStopped
    rm -f /var/log/jenkins/jenkins.log
    rm -f /var/www/html/adminUserExists

    setJenkinsDescription instructions_step2.txt

    cp scriptApproval.xml $JENKINS_HOME/scriptApproval.xml
    service jenkins start >/dev/null 2>&1

    waitUntilSetupJobIsExecuted
    sleep 5

    echo "Setup complete, restarting jenkins one lasts time"

    stopAndWaitUntilFullyStopped

    setJenkinsDescription instructions_step3.txt

    rm -rf $JENKINS_HOME/jobs/BOOTSTRAP_*

    sed 's/8090/8080/' -i /etc/default/jenkins
    service apache2 stop >/dev/null 2>&1
}

function waitUntilSetupJobIsExecuted(){
    while [[ ! -e /opt/jenkins/setup-complete ]]; do 
        sleep 1
    done
}

function stopAndWaitUntilFullyStopped()
{
    service jenkins stop >/dev/null 2>&1
    if [[ ! -e /var/run/jenkins/jenkins.pid ]]; then
        return
    fi
    JENKINS_PID=$(cat /var/run/jenkins/jenkins.pid)
    while kill -0 $JENKINS_PID 2>/dev/null; do
        sleep 1
    done
}

function fixGlobalNode()
{
(
    IFS=
    while read A; do 
        if [[ $A =~ .*globalNodeProperties* ]]; then 
cat <<EOF
  <globalNodeProperties>
    <hudson.slaves.EnvironmentVariablesNodeProperty>
      <envVars serialization="custom">
        <unserializable-parents/>
        <tree-map>
          <default>
            <comparator class="hudson.util.CaseInsensitiveComparator"/>
          </default>
          <int>0</int>
        </tree-map>
      </envVars>
    </hudson.slaves.EnvironmentVariablesNodeProperty>
  </globalNodeProperties>
EOF
        else
            echo "$A"
        fi
    done > /tmp/config.xml < $JENKINS_HOME/config.xml
    echo $A >> /tmp/config.xml
    cp /tmp/config.xml $JENKINS_HOME/config.xml
)
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

function waitUntilConfigurationIsCompleteAndAdminIsCreated()
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
