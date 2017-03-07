#!groovy

import groovy.transform.Field
import groovy.json.*

@Field final ORGANIZATION = "wiredlabs";
@Field final GITHUB_API_ENDPOINT = "https://api.github.com/orgs/${ORGANIZATION}"
@Field final GITHUB_REPOS_API_ENDPOINT = "https://api.github.com/repos/${ORGANIZATION}"
@Field final GITHUB_CREDENTIALS_ID = "githubCredentials";
@Field final JIRA_CREDENTIALS_ID = "jiraCredentials";

properties([disableConcurrentBuilds(),
	[$class: 'ParametersDefinitionProperty', 
		parameterDefinitions: [
			[$class: 'StringParameterDefinition', 
				description: 'Jira key for the project', 
				name : 'JiraKey'], 
			[$class: 'StringParameterDefinition', 
				description: 'Project name', 
				name : 'JiraProjectName'], 
			[$class: 'StringParameterDefinition', 
				description: "Github Repo Name. The repo will become github.com/${ORGANIZATION}/<given name>", 
				name: 'GithubRepoName'], 
			[$class: 'StringParameterDefinition', 
				description: 'Project Description', 
				name: 'ProjectDescription'],
			[$class: 'ExtensibleChoiceParameterDefinition', 
				choiceListProvider: [$class: 'SystemGroovyChoiceListProvider', 
					usePredefinedVariables: true,
					scriptText: """
						import groovy.json.JsonSlurper;
						import java.net.URL;
						import java.util.Base64;

						final user = "admin";
						final password = "admin";
						final JIRA_ENDPOINT = jenkins.getGlobalNodeProperties()[0].getEnvVars().get("JIRA_REST_ENDPOINT")+"/api/latest";
						final wildcard = "."; // latest jira is .

						auth = Base64.getEncoder().encodeToString((user + ":" + password).getBytes());
						users = new JsonSlurper().parseText(new URL("\${JIRA_ENDPOINT}/user/search?startAt=0&maxResults=1000&username=\${wildcard}").getText(requestProperties: ['Authorization': "Basic \${auth}"]))

						return users.collect{"\${it.key} | \${it.displayName} "} 
					"""
					], 
					description: 'Choose the jira user that will lead the project', 
					editable: false, 
					name: 'TeamLeader',
			]
		]
	]
])

def createGithubProject(leaderMail, jiraProjectName, githubProjectName, description)
{
	def repoName = createGithubRepo(githubProjectName, description);
	def fullRepoName = "${ORGANIZATION}/$repoName"

	File projDir = new File(workspace, "proj");
	execCmd("rm -rf proj")

	clone (fullRepoName, projDir);
	File jenkinsFile = new File(projDir, "Jenkinsfile");
	jenkinsFile << updateTemplateVariables("Jenkinsfile.tpl", [
		_JIRA_PROJECT_NAME_      : jiraProjectName,
		_GITHUB_REPOSITORY_NAME_ : repoName,
		_GITHUB_ORGANIZATION_    : ORGANIZATION,
		_LEADER_MAIL_            : leaderMail
	])

	File buildGradle = new File(projDir, "build.gradle");
	buildGradle << updateTemplateVariables("build.gradle.tpl", [
		_JIRA_PROJECT_NAME_      : jiraProjectName,
		_GITHUB_REPOSITORY_NAME_ : githubProjectName
	]);
	push(projDir);
}


def createJiraProject(jiraKey, jiraName, description, lead)
{
	lead = lead.split("\\|")[0].trim();
	def req=[
		key                      : jiraKey,
		name					 : jiraName,
		description	             : description,
		type                     : "business",
		projectTemplateKey       : "com.atlassian.jira-core-project-templates:jira-core-project-management",
		lead                     : lead,
		issueTypeScheme          : 10100,
		workflowScheme           : 10100,
		issueTypeScreenScheme    : 10000,
		fieldConfigurationScheme : 10000,
		notificationScheme       : 10100,
		permissionScheme         : 10000,
		customFields             : [10000]
/*
		assigneeType            : "PROJECT_LEAD",
		issueTypeScheme         : "19882",
		workflowScheme          : "17180",
		issueTypeScreenScheme   : "14450",
		fieldConfigurationScheme: "13600",
		permissionScheme        : "11770",
		notificationScheme      : "13250",
		customFields            : [ 17737, 18629, 18624, 18521, 18522, 18523, 18626, 18623, 18620, 18625, 18635, 18642, 18627, 18630, 18520, 18621, 18622 ]
*/
	]
	def json = new JsonBuilder(req).toPrettyString()
	def response;
	try {
		response = httpRequest acceptType: 'APPLICATION_JSON', authentication: JIRA_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${JIRA_REST_ENDPOINT}/projectbuilder/1.0/project"
	}catch(Exception e) {
		println "Could not create jira project. The request was:"
		println json
		println "The response was:"
		println response;
		throw e;
	}
}

def createGithubRepo(githubProjectName, description)
{
	try {
		response = httpRequest acceptType: 'APPLICATION_JSON', authentication: GITHUB_CREDENTIALS_ID, url: "${GITHUB_REPOS_API_ENDPOINT}/${githubProjectName}"
		if (response.status == 200) {
			println "Github repo ${githubProjectName} already exists"
			return githubProjectName
		}
	} catch(Exception e) {
		// probably means the project doesn't exist, move on
	}
	def req = [
	  name	      : githubProjectName,
	  description : description,
	  private     : false,
	  has_issues  : true,
	  has_wiki    : true
	]

	def json = new JsonBuilder(req).toPrettyString()
	try {
		response = httpRequest acceptType: 'APPLICATION_JSON', authentication: GITHUB_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${GITHUB_API_ENDPOINT}/repos"
	}catch(Exception e) {
		println "Could not create github project. The request was:"
		println json
		println "The response was:"
		println response.content
		throw e;
	
	}

	return req.name;
}

def updateTemplateVariables(templateName, varMap)
{
	def txt = new File(workspace, templateName).text;
	for (e in varMap) {
		txt = txt.replace("#{"+e.key+"}", e.value);
	}
	return txt;
}

def execCmd(args){
	sh args
}

def clone(repo, dir) {
	withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: GITHUB_CREDENTIALS_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
		execCmd("git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${repo}.git ${dir.name}")
	}
}

def push(dir) {
	execCmd("cd ${dir.name} && git add * && git -c 'user.name=autocreator' -c 'user.email=autocreator@nomail' commit -m 'Project setup' && git push origin master")
}

node {
	stage('Checkout') {
		checkout scm
	}

	stage("Parameter existence validation") {
		try {
			println "JiraKey = $JiraKey"
			println "JiraProjectName = $JiraProjectName"
			println "GithubRepoName = $GithubRepoName"
			println "ProjectDescription = $ProjectDescription"
			println "TeamLeader = $TeamLeader"
		}
		catch (MissingPropertyException e) {
			println "Some of the parameters are missing. It might be due to obsolete JenkinsFile. Retry your build"
			return;
		}  
	}

	stage("Github Project Creation") {
		createGithubProject(TeamLeader, JiraKey, GithubRepoName, ProjectDescription);
	}

	stage("Jira Project Creation") {
		createJiraProject(JiraKey, GithubRepoName, ProjectDescription, TeamLeader);
	}

//	createProjectInTaskboard();

//	createDashingConfiguration();

}
