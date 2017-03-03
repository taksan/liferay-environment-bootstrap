#!groovy

import groovy.transform.Field
import groovy.json.*

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
                description: 'Github Repo Name', 
                name: 'GithubRepoName'], 
            [$class: 'StringParameterDefinition', 
                description: 'Project Description', 
                name: 'ProjectDescription'] 
        ]
    ]   
])

@Field final ORGANIZATION = "wiredlabs";
@Field final JIRA_API_ENDPOINT   = "http://localhost:8081/rest/api/2"
@Field final GITHUB_API_ENDPOINT = "https://api.github.com/orgs/${ORGANIZATION}/"
@Field final CREDENTIALS_ID = "githubCredentials";

def main()
{
	def repoName = createGithubProject(TeamLeader, JiraKey, GithubRepoName, ProjectDescription);

	createJiraProject(JiraKey, GithubRepoName, ProjectDescription, TeamLeader);

//	createProjectInTaskboard();

//	createDashingConfiguration();
}

def createGithubProject(leaderMail, jiraProjectName, githubProjectName, description)
{
	def repoName = createGithubRepo(githubProjectName, description);

	File projDir = new File("proj");
	clone (repoName, projDir);
	File jenkinsFile = new File(projDir, "Jenkinsfile");
	jenkinsFile << updateTemplateVariables("Jenkinsfile.tpl", [
		_JIRA_PROJECT_NAME_      : jiraProjectName,
		_GITHUB_REPOSITORY_NAME_ : repoName,
		_GITHUB_ORGANIZATION_    : ORGANIZATION,
		_LEADER_MAIL_            : leaderMail
	])

	File buildGradle = new File(projDir, "build.gradle");
	buildGradle << updateTemplateVariables("build.gradle.tpl", [
		_JIRA_PROJECT_NAME_     : jiraProjectName,
		_GITHUB_REPOSITORY_NAME_: githubProjectName
	]);

	push(repoName, projDir);
}


def createJiraProject(jiraKey, jiraName, description, lead)
{
	def req=[
		key                     : jiraKey,
		name                    : jiraName,
		projectTypeKey          : "business",
		projectTemplateKey      : "com.atlassian.jira-core-project-templates:jira-core-project-management",
		description             : description,
		lead                    : lead,
		assigneeType            : "PROJECT_LEAD",
		issueTypeScheme         : "19882",
		workflowScheme          : "17180",
		issueTypeScreenScheme   : "14450",
		fieldConfigurationScheme: "13600",
		permissionScheme        : "11770",
		notificationScheme      : "13250"
	]
	def json = new JsonBuilder(req).toPrettyString()
	httpRequest acceptType: 'APPLICATION_JSON', authentication: jiraAuthentication, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${JIRA_API_ENDPOINT}/project"
}

def createGithubRepo(githubProjectName, description)
{
	def req = [
	  name        : githubProjectName,
	  description : description,
	  private     : false,
	  has_issues  : true,
	  has_wiki    : true
	]

	def json = new JsonBuilder(req).toPrettyString()
	httpRequest acceptType: 'APPLICATION_JSON', authentication: githubAuthentication, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${GITHUB_API_ENDPOINT}/repos"

	return req.name;
}

def updateTemplateVariables(templateName, varMap)
{
	def txt = new File(templateName).text;
	for (e in varMap) {
		txt = txt.replace("#{"+e.key+"}", e.value);
	}
	return txt;
}

def execCmd(args){
	println args.execute().getText();
}

def clone(repo, dir) {
	withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: CREDENTIALS_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
    	execCmd("git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@:github.com/${repo}.git ${dir.name}")
	}
}

def push(repo, dir) {
	withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: CREDENTIALS_ID, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
    	execCmd("cd ${dir.name} && git push https://${GIT_USERNAME}:${GIT_PASSWORD}@:github.com/${repo}.git")
	}
}

main()
