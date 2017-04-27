#!groovy
@Library("liferay-sdlc-jenkins-lib")

import groovy.transform.Field
import groovy.json.*
import java.util.Base64;
import java.lang.IllegalArgumentException;
import org.liferay.sdlc.CredentialsManager;
import static org.liferay.sdlc.JenkinsUtils.*;


@Field final JIRA_CREDENTIALS_ID = "jiraCredentials";
@Field final TASKBOARD_AUTH_ID = "taskboardCredentials"
@Field final VERBOSE_REQUESTS = false;

properties([disableConcurrentBuilds(),
    [$class: 'ParametersDefinitionProperty', 
        parameterDefinitions: [
            stringParameter("JiraKey","Jira key for the project"),
            stringParameter("JiraProjectName","Project name"),
            stringParameter("GithubRepoName","Github Repo Name. The repo will become github.com/<ORGANIZATION>/<given name>"),
            stringParameter("ProjectDescription","Project Description"),
            choiceParameter("ProjectOwner", "Project's owner user"),
            autocompleteParameter("JiraAdministrators", "Project administrators"),
            autocompleteParameter("JiraDevelopers", "Project developers"),
            autocompleteParameter("JiraCustomers", "Project customers"),
            stringParameter("GithubOrganization", "(only for non default repo) Github organization"),
            stringParameter("GithubUsername", "(only for non default repo) github user"),
            passwordParameter("GithubPassword", "(only for non default repo) github password")
        ]
    ]
])

def stringParameter(name, description) {
    return [ name: name, description: description, $class: 'StringParameterDefinition']
}

def passwordParameter(name, description) {
    return [ name: name, description: description, $class: 'PasswordParameterDefinition']
}

def autocompleteParameter(name, description) {
    return [
        $class: 'AutoCompleteStringParameterDefinition', 
        name: name, 
        description: description, 
        defaultValue: '', 
        allowUnrecognizedTokens: false, 
        displayExpression: 'displayName', 
        valueExpression: 'name',
        dataProvider: jiraDataProvider()
        ];
}

def choiceParameter(name, description) {
    return [
        $class: 'DropdownAutocompleteParameterDefinition', 
        name: name,
        description: '', 
        defaultValue: '', 
        displayExpression: 'displayName',
        valueExpression: '{name+"/"+emailAddress}',
        dataProvider: jiraDataProvider()
        ];
}

def jiraDataProvider() {
    return [ 
        $class: 'RemoteDataProvider', 
        autoCompleteUrl: "\$JIRA_REST_ENDPOINT/rest/projectbuilder/1.0/users", 
        credentialsId: JIRA_CREDENTIALS_ID] 
}


def createGithubProject(leaderMail, jiraProjectName, repoName, description)
{
    if (!checkRepoExists(repoName)) {
        println "Github repo ${repoName} doesn't exist, can't setup repository"
        error("Github repo ${repoName} doesn't exist, can't setup repository");
    }

    if (checkFileExists("gradlew", repoName)) {
        addJenkinsfileForExistingProjects(repoName, jiraProjectName, leaderMail);
        println "Project already initialized, skipping blade init"
        return;
    }

    println "New project detected. Initialize it";

    def fullRepoName = "${organization()}/$repoName"

    deleteRecursive "proj";

    clone (fullRepoName, "proj");

    execCmd("cd proj && blade init -f");

    createJenkinsFile("proj", repoName, jiraProjectName, leaderMail);

    push("proj");
}

def createJiraProject(jiraKey, jiraName, description, lead, administrators, developers, customers)
{
    def projectHardData =  [
        issueTypeScheme         : "20480",
        workflowScheme          : "17180",
        issueTypeScreenScheme   : "14450",
        fieldConfigurationScheme: "13600",
        permissionScheme        : "14070",
        notificationScheme      : "13250",
        customFields            : [ 
            [ id: "17737", schemeId: "19002" ], 
            [ id: "18629", schemeId: "19989" ], 
            [ id: "18624", schemeId: "19984" ], 
            [ id: "18521", schemeId: "19782" ], 
            [ id: "18522", schemeId: "19783" ], 
            [ id: "18523", schemeId: "19784" ], 
            [ id: "18626", schemeId: "19986" ], 
            [ id: "18623", schemeId: "19983" ], 
            [ id: "18620", schemeId: "19980" ], 
            [ id: "18625", schemeId: "19985" ], 
            [ id: "18635", schemeId: "19996" ], 
            [ id: "18642", schemeId: "20004" ], 
            [ id: "18627", schemeId: "19987" ], 
            [ id: "18630", schemeId: "19990" ], 
            [ id: "18520", schemeId: "19781" ], 
            [ id: "18621", schemeId: "19981" ], 
            [ id: "18622", schemeId: "19982" ] ]
    ];
    if (env.OVERRIDE_DATA) {
        projectHardData = new JsonSlurper().parseText(env.OVERRIDE_DATA);
    }

    def json = asJson([
            key                      : jiraKey,
            name                     : jiraName,
            description              : description,
            lead                     : lead,
            userInRoles              :[
                "Administrators"     : prepareJenkinsUserList(administrators), 
                "Developers"         : prepareJenkinsUserList(developers), 
                "Customers"          : prepareJenkinsUserList(customers),
                "Users"              : [ "gs-task-board" ],
            ],
            projectTypeKey           : "business",
            projectTemplateKey       : "com.atlassian.jira-core-project-templates:jira-core-project-management"
        ] + projectHardData);
    projectHardData = null;

    resp = httpRequest acceptType: 'APPLICATION_JSON', authentication: JIRA_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, 
            url: "${JIRA_REST_ENDPOINT}/rest/projectbuilder/1.0/project", consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"

    if (resp.status != 200) {
        println resp.content
        println "Could not create jira project: Here's the sent data:"
        println json
        error("Jira project creation failed.");
    }
}

def addJenkinsfileForExistingProjects(repoName, jiraProjectName, leaderMail)
{
    if (checkFileExists("Jenkinsfile", repoName)) {
        println "Jenkinsfile already present in repo ${repoName}. Nothing to do here."
        return; 
    }
    println "Jenkinsfile missing in project. Adding.."

    // file is missing, we need to up it there
    mkdir "proj"

    def jenkinsFile = createJenkinsFile("proj", repoName, jiraProjectName, leaderMail);

    def content = readFile file: jenkinsFile
    addFileInRepo("Jenkinsfile", content, repoName) 
}

def createJenkinsFile(projDir, repoName, jiraProjectName, leaderMail) {
    def fileName = "${projDir}/Jenkinsfile";
    writeFile file: fileName, text: updateTemplateVariables("Jenkinsfile.tpl", [
        _JIRA_PROJECT_NAME_      : jiraProjectName,
        _GITHUB_REPOSITORY_NAME_ : repoName,
        _GITHUB_ORGANIZATION_    : organization(),
        _LEADER_MAIL_            : leaderMail,
        _GITHUB_CREDENTIALS_ID_  : githubCredentialsId()
    ])

    return fileName;
}

def checkRepoExists(repoName) {
    response = githubGetRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}"
    if (response.status == 404) 
        return false;
    if (response.status > 400)
        error(response.content)
    return true;
}

def checkFileExists(fileName, repoName) {
    response = githubGetRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}/contents/${fileName}"
    if (response.status == 404)
        return false;
    if (response.status > 400)
        error(response.content)
    return true;
}

def addFileInRepo(filename, content, repoName) {
    response = githubPutRequest "${GITHUB_REPOS_API_ENDPOINT}/${repoName}/contents/${filename}",
        [
            message: "Jenkinsfile automatically added",
            content:  Base64.getEncoder().encodeToString(content.bytes),
            name: "jenkins"
        ]
    if (response.status > 400)
        error(response.content)
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
    resp = httpRequest acceptType: 'APPLICATION_JSON', authentication: githubCredentialsId(), contentType: 'APPLICATION_JSON', httpMode: mode, requestBody: json, url: "https://api.github.com/$serviceEndpoint",
                    consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"
    return resp;                    
}


def createDashingConfiguration(jiraKey)
{
    def json = asJson([project: jiraKey])
    
    httpRequest acceptType: 'APPLICATION_JSON', authentication: 'dashboardCredentials', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${DASHING_END_POINT}/project",
                consoleLogResponseBody: VERBOSE_REQUESTS 
}

def updateTaskboardConfiguration(jiraKey, leaderJiraName)
{
    httpRequest acceptType: 'APPLICATION_JSON', authentication: TASKBOARD_AUTH_ID, httpMode: 'POST', url: "${TASKBOARD_END_POINT}/api/projects?projectKey=${jiraKey}",
                requestBody: asJson([projectKey: JiraKey, teamLeader: leaderJiraName]) ,consoleLogResponseBody: VERBOSE_REQUESTS
}

def updateTemplateVariables(templateName, varMap)
{
    def txt = readFile file: templateName;
    for (e in varMap) {
        txt = txt.replace("#{"+e.key+"}", e.value);
    }
    return txt;
}

def createJobFromTemplate(jobName, templateFile, varMap) {
    def jobXml = updateTemplateVariables(templateFile, varMap )
    try {
        createProjectFromXML(jobName, jobXml)
    } catch(IllegalArgumentException e) {
        println "Job ${jobName} not created (reason: ${e.message}), probably already exists. Just ignore."
    }
}

def createProjectJobs(githubRepoName) {
    createJobFromTemplate(githubRepoName+"-pr-builder", "pullRequestBuilderJob.tpl", getJobTemplateData())

    createJobFromTemplate(githubRepoName+"-bundle-build", "bundle-build-config.tpl", getJobTemplateData())

    createJobFromTemplate(githubRepoName+"-bundle-deploy", "bundle-deploy-config.tpl", getJobTemplateData())

    if (checkViewExists(JiraKey)) 
        println "View ${JiraKey} already exists. Skip"
    else 
        createView(JiraKey);
    
    addJobToView(githubRepoName+"-pr-builder", JiraKey)
    addJobToView(githubRepoName+"-bundle-build", JiraKey)
    addJobToView(githubRepoName+"-bundle-deploy", JiraKey)
}

def getJobTemplateData() {
    return [
        _SCM_SOURCE_ID_          : java.util.UUID.randomUUID().toString(),
        _GITHUB_CREDENTIALS_ID_  : githubCredentialsId(),
        _GITHUB_REPOSITORY_NAME_ : githubRepoName,
        _GITHUB_ORGANIZATION_    : organization(),
        _JIRA_KEY_               : JiraKey,
        _JIRA_PROJECT_NAME_      : JiraProjectName

    ]
}

def execCmd(args){
    sh args
}

def clone(repo, dirName) {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: githubCredentialsId(), usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
        execCmd("git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${repo}.git ${dirName}")
    }
}

def push(dir) {
    execCmd("cd ${dir} && git add * && git -c 'user.name=autocreator' -c 'user.email=autocreator@nomail' commit -m 'Project setup' && git push origin master")
}

def asJson(data) {
    return new JsonBuilder(data).toPrettyString();
}

def isJobPropertiesObsolete() {
    def shouldHave = getJobParameterNames(JOB_NAME);
    
    boolean isObsolete = false;
    def envvars = env.getEnvironment()
    for (e in shouldHave) {
        if (envvars.get(e) == null) {
            println "MISSING VARIABLE $e"
            isObsolete = true;
        }
    }
    shouldHave = null;
    envvars = null;

    return isObsolete;
}

@NonCPS
def setupPermissionRoles(jiraKey)
{
    assignSidToRole(jiraKey, "@ViewMatchSidMacroRole(:admin=Delete/Configure)");
}

@NonCPS
def prepareJenkinsUserList(array) {
    for(i = 0; i < array.length; i++) 
        array[i] = array[i].trim();
    
    return array;
}

def organization() {
    if (isEmpty(GithubOrganization))
        return ORGANIZATION;

    return GithubOrganization;
}

def githubCredentialsId() {
    if (!isEmpty(GithubOrganization)) {
        return "github_${GithubOrganization}_${GithubRepoName}";
    }
    return "githubCredentials";
}

def isEmpty(s) {
    return s == null || "".equals(s)
}

node {
    stage('Pre validation') {
        if (env.DASHING_END_POINT == null) 
            error("You must set DASHING_END_POINT in the global properties");

        if (env.JIRA_REST_ENDPOINT == null) 
            error("You must set JIRA_REST_ENDPOINT in the global properties");

        if (env.ORGANIZATION == null) 
            error("You must set ORGANIZATION in the global properties");

        if (env.TASKBOARD_END_POINT == null)
            error("You must set TASKBOARD_END_POINT in the global properties");

        if (isEmpty(ProjectOwner)) 
            error("You must provide the project owner ${ProjectOwner}")

        if (isEmpty(GithubRepoName)) 
            error("You must provide the git repository name")

        if (isEmpty(JiraKey)) 
            error("You must provide the jira key for the project")

    }
    stage('Checkout') {
        checkout scm
    }

    stage("Parameter existence validation") {
        if (isJobPropertiesObsolete()) {
            error("Some of the build parameters are missing. It might be due to obsolete JenkinsFile. Retry your build");
        } 
    }

    GITHUB_REPOS_API_ENDPOINT = "repos/${organization()}"

    def leaderJiraName = ProjectOwner.split("/")[0]
    def leaderMail = ProjectOwner.split("/")[1]


    stage("Github Project Setup") {
        if (!isEmpty(GithubOrganization)) {
            if (isEmpty(GithubUsername)) 
                error("If you provide a custom organization, you must provide the username")
            if (isEmpty(GithubPassword)) 
                error("If you provide a custom organization, you must provide the password")
           cm = new CredentialsManager();
           cm.createUsernameWithPasswordCredentialsIfNeeded(githubCredentialsId(), "Setting up credentials for github project", "Credentials for ${GithubOrganization}/${GithubRepoName}")
        }

        createGithubProject(leaderMail, JiraKey, GithubRepoName, ProjectDescription);
    }

    stage("Jira Project Creation") {
        createJiraProject(JiraKey, JiraProjectName, ProjectDescription, leaderJiraName, 
            JiraAdministrators.split(","), 
            JiraDevelopers.split(","), 
            JiraCustomers.split(","));
    }

    stage("Projects Jobs Creation") {
        createProjectJobs(GithubRepoName);
    }

    stage("Dashboard project creation") {
        createDashingConfiguration(JiraKey);
    }

    stage("Taskboard project setup") {
        updateTaskboardConfiguration(JiraKey, leaderJiraName);
    }

    stage("Setting up project permission scheme on Jenkins") {
        setupPermissionRoles(JiraKey);
    }
}
