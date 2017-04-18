<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.10">
  <actions/>
  <description>
    This jobs uploads the build to nexus.<br/>

    {team:#{_JIRA_KEY_}}
  </description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.26.0">
      <projectUrl>https://github.com/#{_GITHUB_ORGANIZATION_}/#{_GITHUB_REPOSITORY_NAME_}/</projectUrl>
      <displayName/>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty plugin="gitlab-plugin@1.4.5">
      <gitLabConnection/>
    </com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty>
    <com.sonyericsson.rebuild.RebuildSettings plugin="rebuild@1.25">
      <autoRebuild>false</autoRebuild>
      <rebuildDisabled>false</rebuildDisabled>
    </com.sonyericsson.rebuild.RebuildSettings>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers/>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.27">
    <script>#!gradle
properties([
  parameters([
    choice(choices: "10", description: 'Select the desired fix pack version number.', name: 'fix_pack_version'), 
    choice(choices: "NONE\n213\n150", description: 
    '''Select whether or not a support patch should be applied.''', name: 'patch_number')]), 
  pipelineTriggers([])])
  
def gradlew(args)
{
    if (isUnix()) sh "./gradlew " + args else bat "call gradlew " + args
}

node {
  def githubOrganization = "#{_GITHUB_ORGANIZATION_}";
  def githubProjectName = "#{_GITHUB_REPOSITORY_NAME_}";
  
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
                [credentialsId: '#{_GITHUB_CREDENTIALS_ID_}', 
                url: "https://github.com/${githubOrganization}/${githubProjectName}.git"]]])
  }   
  stage('Package') {
        // Build Liferay bundle with custom code and common configurations
        version_name="fix-pack-$fix_pack_version"

        if (patch_number != "NONE")
            version_name="fix-pack-${fix_pack_version}-patch-${patch_number}"
            
        timestamps {
            gradlew "-Pliferay.workspace.bundle.url=${NexusHostUrl}/repository/patched-bundle/patched-bundle-${version_name}.zip -Pliferay.workspace.environment=vanilla distBundleZip --no-daemon"
            new File("${workspace}/build",JOB_NAME+".zip").renameTo("${workspace}/build/${githubProjectName}-${build_number}.zip");
        }
  }   
  stage('Nexus Upload') {
       nexusProtocol = NexusHostUrl.split(":")[0];
       nexusIpPort = NexusHostUrl.replaceFirst("^.*?://","")
       nexusArtifactUploader artifacts: [[artifactId: githubProjectName, classifier: '', file: "build/${githubProjectName}-${build_number}.zip", type: 'zip']], 
             credentialsId: 'jiraCredentials', 
             groupId: '/', 
             nexusUrl: NEXUS_HOST,
             nexusVersion: 'nexus3',
             protocol: 'http',
             repository: 'jenkins-build',
             version: build_number
  }
}
</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
</flow-definition>
