<?xml version="1.0" encoding="UTF-8"?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.12">
  <actions/>
  <description/>
  <properties>
    <org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig plugin="pipeline-model-definition@1.0.1">
      <dockerLabel/>
      <registry plugin="docker-commons@1.6"/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig>
  </properties>
  <folderViews class="jenkins.branch.MultiBranchProjectViewHolder" plugin="branch-api@2.0.6">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric plugin="cloudbees-folder@5.18">
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="jenkins.branch.MetadataActionFolderIcon" plugin="branch-api@2.0.6">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </icon>
  <orphanedItemStrategy class="com.cloudbees.hudson.plugins.folder.computed.DefaultOrphanedItemStrategy" plugin="cloudbees-folder@5.18">
    <pruneDeadBranches>true</pruneDeadBranches>
    <daysToKeep>0</daysToKeep>
    <numToKeep>0</numToKeep>
  </orphanedItemStrategy>
  <triggers/>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.0.6">
    <data>
      <jenkins.branch.BranchSource>
        <source class="org.jenkinsci.plugins.github_branch_source.GitHubSCMSource" plugin="github-branch-source@2.0.3">
          <id>${SCM_SOURCE_ID}</id>
          <checkoutCredentialsId>SAME</checkoutCredentialsId>
          <scanCredentialsId>githubCredentials</scanCredentialsId>
          <repoOwner>${ORGANIZATION}</repoOwner>
          <repository>${GithubRepoName}</repository>
          <includes>*</includes>
          <excludes/>
          <buildOriginBranch>true</buildOriginBranch>
          <buildOriginBranchWithPR>false</buildOriginBranchWithPR>
          <buildOriginPRMerge>true</buildOriginPRMerge>
          <buildOriginPRHead>false</buildOriginPRHead>
          <buildForkPRMerge>true</buildForkPRMerge>
          <buildForkPRHead>false</buildForkPRHead>
        </source>
        <strategy class="jenkins.branch.DefaultBranchPropertyStrategy">
          <properties class="empty-list"/>
        </strategy>
      </jenkins.branch.BranchSource>
    </data>
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </sources>
  <factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>