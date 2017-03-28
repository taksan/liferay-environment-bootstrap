#!groovy

import groovy.transform.Field
import groovy.json.*
import java.util.Base64;

@Field final ORGANIZATION = "wiredlabs";
@Field final GITHUB_REPOS_API_ENDPOINT = "repos/${ORGANIZATION}"
@Field final GITHUB_CREDENTIALS_ID = "githubCredentials";
@Field final JIRA_CREDENTIALS_ID = "jiraCredentials";
@Field final TASKBOARD_AUTH_ID = "taskboardCredentials"

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

def createGithubProject(leaderMail, jiraProjectName, repoName, description)
{
    def created = createGithubRepo(repoName, description);
    if (!created) {
        // project already exists, add missing jenkins file
        addJenkinsfileForExistingProjects(repoName, jiraProjectName, leaderMail);
    	return;
    }

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
    	_GITHUB_REPOSITORY_NAME_ : repoName
    ]);
    push(projDir);
}

def createJiraProject(jiraKey, jiraName, description, lead)
{
    lead = lead.split("\\|")[0].trim();
    def json = asJson([
    	key                      : jiraKey,
    	name					 : jiraName,
    	description	             : description,
    	projectTypeKey           : "business",
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
    ]);

    try {
    	httpRequest acceptType: 'APPLICATION_JSON', authentication: JIRA_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, 
    		url: "${JIRA_REST_ENDPOINT}/projectbuilder/1.0/project", consoleLogResponseBody: true
    }catch(Exception e) {
    	println "Could not create jira project. Failed request body"
    	println json
    	throw e;
    }
}


/**
 * @returns true if a new repository was created. false otherwise
 * @throws IllegalStateException if the repository wasn't created due to some failure
 */
def createGithubRepo(repoName, description)
{
    if (checkRepoExists(repoName)) {
        println "Github repo ${repoName} already exists"
        return false;
    }

    try {
        githubPostRequest "orgs/${ORGANIZATION}/repos",
            [
                  name	      : repoName,
                  description : description,
                  private     : false,
                  has_issues  : true,
                  has_wiki    : true
            ];
    }catch(Exception e) {
    	println "Could not create github project. The request was:"
    	println json
    	throw e;
    }

    return true;
}

def addJenkinsfileForExistingProjects(repoName, jiraProjectName, leaderMail)
{
    if (checkFileExists("Jenkinsfile", repoName)) {
        println "Jenkinsfile already present in repo ${repoName}. Nothing to do here."
        return; 
    }
    println "Jenkinsfile missing in project. Adding.."

    // file is missing, we need to up it there
    File projDir = new File(workspace, "proj");
    projDir.mkdirs();
  	File jenkinsFile = new File(projdir, "Jenkinsfile");
    jenkinsFile << updateTemplateVariables("Jenkinsfile.tpl", [
    	_JIRA_PROJECT_NAME_      : jiraProjectName,
    	_GITHUB_REPOSITORY_NAME_ : repoName,
    	_GITHUB_ORGANIZATION_    : ORGANIZATION,
    	_LEADER_MAIL_            : leaderMail
    ])

    addFileInRepo(jenkinsFile, repoName) 
}

def checkRepoExists(repoName) {
    response = githubGetRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}"
    if (response.status == 404) 
        return false;
    if (response.status > 400)
        throw new IllegalStateException(response.content)
    return true;
}

def checkFileExists(fileName, repoName) {
    response = githubGetRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}/contents/${fileName}"
    if (response.status == 404)
        return false;
    if (response.status > 400)
        throw new IllegalStateException(response.content)
    return true;
}

def addFileInRepo(file, repoName) {
    response = githubPutRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}/contents/${file.name}",
        [
            message: "Jenkinsfile automatically added",
            content:  Base64.getEncoder().encodeToString(file.text.bytes),
            name: "jenkins"
        ]
    if (response.status > 400)
        throw new IllegalStateException(response.content)
}

def githubGetRequest(serviceEndpoint) {
    return githubRequest(serviceEndpoint, "GET", "")
}

def githubPostRequest(serviceEndpoint, data) {
    return githubRequest(serviceEndpoint, "POST", asJson(data))
}

def githubPutRequest(serviceEndpoint, data) {
    return githubRequest(serviceEndpoint, "PUT", asJson(data))
}


def githubRequest(serviceEndpoint, mode, json) {
    resp = httpRequest acceptType: 'APPLICATION_JSON', authentication: GITHUB_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: mode, requestBody: json, url: "https://api.github.com/$serviceEndpoint",
    				consoleLogResponseBody: true, validResponseCodes: "100:599"
    return resp;                    
}


def createDashingConfiguration(jiraKey)
{
    def json = asJson([project: jiraKey])
    
    httpRequest acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${DASHING_END_POINT}/project",
    			consoleLogResponseBody: true
}

def updateTaskboardConfiguration(jiraKey)
{
    httpRequest acceptType: 'APPLICATION_JSON', authentication: TASKBOARD_AUTH_ID, httpMode: 'POST', url: "${TASKBOARD_END_POINT}/api/projectfilter?projectKey=${jiraKey}",
    			consoleLogResponseBody: true
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

def asJson(data) {
    return new JsonBuilder(data).toPrettyString();
}

node {
    stage('Pre validation') {
    	if (env.DASHING_END_POINT == null) 
    		throw new IllegalStateException("You must set DASHING_END_POINT in the global properties");

    	if (env.JIRA_REST_ENDPOINT == null) 
    		throw new IllegalStateException("You must set JIRA_REST_ENDPOINT in the global properties");

    	if (env.ORGANIZATION == null) 
    		throw new IllegalStateException("You must set ORGANIZATION in the global properties");

    	if (env.TASKBOARD_END_POINT == null)
    		throw new IllegalStateException("You must set TASKBOARD_END_POINT in the global properties");
    }
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

    stage("Dashboard project creation") {
    	createDashingConfiguration(JiraKey);
    }

    stage("Taskboard project setup") {
    	updateTaskboardConfiguration(JiraKey);
    }
}
