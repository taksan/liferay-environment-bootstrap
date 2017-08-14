<?xml version='1.0' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.10">
  <actions/>
  <description>This job deploys the build in a server</description>
  <displayName>#{_JIRA_PROJECT_NAME_} Bundle Deploy</displayName>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>TargetBuild</name>
          <description>If left empy, it will use the latest succesful build.</description>
          <defaultValue></defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>DeployServerIp</name>
          <description>If you're using a custom deploy mechanism implemented in gradle task deployApplication, you can leave this empty. Anyway, this value will be accessible by the gradle task through the DeployServerIp environment variable if you want to take it in consideration.</description>
          <defaultValue></defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers/>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.29">
    <script>@Library("liferay-sdlc-jenkins-lib")

import org.liferay.sdlc.FileOperations;
import org.liferay.sdlc.CredentialsManager;
import static org.liferay.sdlc.SDLCPrUtilities.*
import static org.liferay.sdlc.BuildUtils.*;

node ("#{_GITHUB_REPOSITORY_NAME_}") {
    def githubOrganization = "#{_GITHUB_ORGANIZATION_}";
    def githubProjectName = "#{_GITHUB_REPOSITORY_NAME_}";
    def githubCredentialsId = "#{_GITHUB_CREDENTIALS_ID_}"
    def jiraKey = "#{_JIRA_KEY_}"

    stage("Cleanup") {
        step([$class: 'WsCleanup'])
    }
    
    stage('Checkout') { // for display purposes
      checkout(
          [$class: 'GitSCM', branches: [[name: '*/master']], 
          doGenerateSubmoduleConfigurations: false, 
          extensions: [
              [$class: 'CleanBeforeCheckout'], 
              [$class: 'LocalBranch', localBranch: 'master'], 
              [$class: 'IgnoreNotifyCommit']
            ],
            submoduleCfg: [], 
            userRemoteConfigs: [
                [credentialsId: githubCredentialsId,
                url: "https://github.com/${githubOrganization}/${githubProjectName}.git"]]])
    }       
    
    def credId = "creds_for_server_${DeployServerIp}";
    def cm = new CredentialsManager();
    stage("Deploy Server Validation") {
        if (DeployServerIp != '') {
            cm.createSshPrivateKeyIfNeeded(
                credId,
                "Could not find credentials to access server $DeployServerIp. Click on the link below to provide them. Don't use a private key protected by password, as it's not supported.",
                "Credentials for deploy server ${DeployServerIp}")
        }
    }    
   
    stage('Package') {
        timestamps {
            def fops = new FileOperations();
            def bundle_build_number = 0;
    
            if(TargetBuild == "") 
                // Get the last successful build number for download that build's bundle zip
                bundle_build_number = lastBuildNumber("${githubProjectName}-bundle-build");
            else 
                bundle_build_number = TargetBuild
    
            bundle_artifact_dir = "${githubProjectName}-${bundle_build_number}"
            bundle_artifact_zip = "${bundle_artifact_dir}.zip"
    
            echo "Downloading bundle with build number ${bundle_build_number} (${NexusHostUrl}/repository/jenkins-build/${bundle_build_number}/${bundle_artifact_zip}) to ${bundle_artifact_zip}"
    
            // download to local file
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: "nexusCredentials", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASSWORD']]) {
                fops.downloadToWithAuth("${NexusHostUrl}/repository/jenkins-build/${jiraKey}/${githubProjectName}/${bundle_build_number}/${bundle_artifact_zip}", 
                                         bundle_artifact_zip, 
                                         env.NEXUS_USER, 
                                         env.NEXUS_PASSWORD);
            }
            
            // Add in configs for specified environment
            fops.mkdir(bundle_artifact_dir);
    
            unzip zipFile: bundle_artifact_zip, dir: bundle_artifact_dir;
    
            fops.remove(bundle_artifact_zip);
    
            fops.copyRecursive("configs/liferay", bundle_artifact_dir);
    
            zip zipFile: bundle_artifact_zip, dir: bundle_artifact_dir
        }
        
        stage ("Deploy") {
            try {
                gradlew "deployApplication 2&gt;errors.txt"
                println "Applicatin deployed successfully"
                return;
            }
            catch (Exception e) {
                errors = readFile "errors.txt"
                if (!errors.contains("Task 'deployApplication' not found")) {
                    // deploy task exists, but failed
                    error(errors)
                }
            }
            println "gradlew has no deployApplication task, falling back to default ssh mechanism"
            
            // if we get to this point, deployApplication task isn't implemented
            if (DeployServerIp == "") {
                error("Can't deploy, deploy server ip address not provided")
            }
            sshagent (credentials: [credId]) {
                // just make sure there's a directory to copy the artifact and that it's clean
                ssh "$DeployServerIp", """
                    rm -rf /tmp/deploy_install
                    mkdir /tmp/deploy_install
                """
                // transfer the artifact
                scp bundle_artifact_zip, "$DeployServerIp:/tmp/deploy_install"
                // run the deploy script
                ssh "$DeployServerIp", """
                    set -e
                    cd /tmp/deploy_install
                    # extracts the install script
                    unzip ${bundle_artifact_zip} install_project_bundle.sh
                    # executes the install script
                    chmod +x install_project_bundle.sh
                    ./install_project_bundle.sh
                    rm -f ${bundle_artifact_zip}
                """
            }
        }
    }
}</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
</flow-definition>
