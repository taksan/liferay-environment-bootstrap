<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.10">
  <actions/>
  <description>
This job uploads the build to nexus.
  </description>
  <displayName>#{_JIRA_PROJECT_NAME_} Bundle Build</displayName>
  <keepDependencies>false</keepDependencies>
  <properties>
      <hudson.model.ParametersDefinitionProperty><parameterDefinitions>
        <hudson.model.ChoiceParameterDefinition>
          <name>versionName</name>
          <description>Select the desired fix pack version/patch version.</description>
          <choices class="java.util.Arrays$ArrayList">
            <a class="string-array"><string>fix-pack-13</string></a>
          </choices></hudson.model.ChoiceParameterDefinition>
      </parameterDefinitions></hudson.model.ParametersDefinitionProperty>
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
@Library("liferay-sdlc-jenkins-lib") _

properties([
  parameters([
    [$class: 'DropdownAutocompleteParameterDefinition', name: 'PatchVersion', description: 'Select the desired fix  pach/patch version.',
        dataProvider: [$class: 'GroovyDataProvider', sandbox: true, script: '''
return requestBuilder
    .url("${NexusHostUrl}/service/siesta/rest/v1/script/findassets/run")
    .credentials("nexusCredentials")
    .header("Content-Type","text/plain")
    .body(["repoName":"patched-bundle","pattern":"%.zip"])
    .post().contentsJson.result.replace("/repository/patched-bundle/","").replace(".zip", "")
        '''], 
        defaultValue: '',  displayExpression: '', name: 'versionName', valueExpression: '']
    ])])


node ("#{_GITHUB_REPOSITORY_NAME_}") {
  def githubOrganization = "#{_GITHUB_ORGANIZATION_}";
  def githubProjectName = "#{_GITHUB_REPOSITORY_NAME_}";
  def githubCredentialsId = "#{_GITHUB_CREDENTIALS_ID_}"

  def buildNumber = build_number
  
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
  stage('Package') {
        if (versionName == null)
            error("Provide the versionName");
                
        timestamps {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: "nexusCredentials", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASSWORD']]) {
                gradle "-Pliferay.workspace.bundle.url=${NexusHostUrl}/repository/patched-bundle/${versionName}.zip -Pliferay.workspace.environment=vanilla distBundleZip --no-daemon"
                renameTo "build/${JOB_NAME}.zip", "build/${githubProjectName}-${buildNumber}.zip"
            }
        }
  }
  stage('Nexus Upload') {
       nexusProtocol = NexusHostUrl.split(":")[0];
       nexusIpPort = NexusHostUrl.replaceFirst("^.*?://","")
       nexusArtifactUploader artifacts: [[artifactId: githubProjectName, classifier: '', file: "build/${githubProjectName}-${buildNumber}.zip", type: 'zip']],  
             credentialsId: 'nexusCredentials',
             groupId: '/#{_JIRA_KEY_}', 
             nexusUrl: nexusIpPort,
             nexusVersion: 'nexus3',
             protocol: 'http',
             repository: 'jenkins-build',
             version: buildNumber
  }
}
</script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
</flow-definition>
