<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.10">
  <actions/>
  <description/>
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
    <script>
@Library("liferay-sdlc-jenkins-lib")

import java.io.File;
import java.net.URL;
import java.util.Base64;
import jenkins.model.*;
import hudson.FilePath;

import org.liferay.sdlc.FileOperations;

node ("lfrgs-google-lms") {
    def githubOrganization = "#{_GITHUB_ORGANIZATION_}";
    def githubProjectName = "#{_GITHUB_REPOSITORY_NAME_}";
   
    stage("Cleanup") {
        step([$class: 'WsCleanup'])
    }
   
    stage('Package') {
        timestamps {
            def fops = new FileOperations();
            def bundle_build_number = 0;
    
            if(target_build == "latest") 
                // Get the last successful build number for download that build's bundle zip
                bundle_build_number = Jenkins.instance.getItem("${githubProjectName}-build").lastSuccessfulBuild.number
            else 
                bundle_build_number = target_build
    
            bundle_artifact = "${githubProjectName}-${bundle_build_number}"
            bundle_artifact_zip = "${bundle_artifact}.zip"
    
            echo "Downloading bundle with build number ${bundle_build_number} (${NexusHostUrl}/repository/jenkins-build/${bundle_build_number}/${bundle_artifact_zip}) to ${bundle_artifact_zip}"
    
            // download to local file
            fp = fops.downloadTo("${NexusHostUrl}/repository/jenkins-build/${bundle_build_number}/${bundle_artifact_zip}", bundle_artifact_zip);
            
            fops.mkdir(bundle_artifact);
    
            unzip zipFile: bundle_artifact_zip, dir: bundle_artifact;
    
            fops.remove(bundle_artifact_zip);
    
            // Add in configs for specified environment
            fops.copyRecursive("configs/liferay", bundle_artifact);
    
            zip zipFile: bundle_artifact_zip, dir: bundle_artifact

            fops.remove(bundle_artifact);
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
</flow-definition>
