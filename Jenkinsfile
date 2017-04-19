#!groovy

import groovy.transform.Field
import groovy.json.*
import java.util.Base64;
import java.lang.IllegalArgumentException;
import com.michelin.cio.hudson.plugins.rolestrategy.RoleBasedAuthorizationStrategy;
import hudson.model.ListView;
import static com.michelin.cio.hudson.plugins.rolestrategy.RoleBasedAuthorizationStrategy.PROJECT;

@Field final GITHUB_CREDENTIALS_ID = "githubCredentials";
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
            autocompleteParameter("JiraAdministrators", "Project's administrators"),
            autocompleteParameter("JiraDevelopers", "Project's developers"),
            autocompleteParameter("JiraCustomers", "Project's customer users"),
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
        autoCompleteUrl: "\$JIRA_REST_ENDPOINT/projectbuilder/1.0/users", 
        credentialsId: JIRA_CREDENTIALS_ID] 
}


def createGithubProject(leaderMail, jiraProjectName, repoName, description)
{
    if (!checkRepoExists(repoName)) {
        println "Github repo ${repoName} doesn't exist, can't setup repository"
        throw new IllegalStateException("Github repo ${repoName} doesn't exist, can't setup repository");
    }

    if (checkFileExists("gradlew", repoName)) {
        addJenkinsfileForExistingProjects(repoName, jiraProjectName, leaderMail);
        println "Project already initialized, skipping blade init"
        return;
    }

    println "New project detected. Initialize it";

    def fullRepoName = "${organization()}/$repoName"

    File projDir = new File(workspace, "proj");
    execCmd("rm -rf proj")

    clone (fullRepoName, projDir);

    execCmd("cd proj && blade init -f");

    createJenkinsFile(projDir, repoName, jiraProjectName, leaderMail);

    push(projDir);
}

def createJiraProject(jiraKey, jiraName, description, lead, administrators, developers, customers)
{
    def projectHardData =  [
        issueTypeScheme         : "20480",
        workflowScheme          : "17180",
        issueTypeScreenScheme   : "14450",
        fieldConfigurationScheme: "13600",
        permissionScheme        : "11770",
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
            url: "${JIRA_REST_ENDPOINT}/projectbuilder/1.0/project", consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"

    if (resp.status != 200) {
        println resp.content
        println "Could not create jira project: Here's the sent data:"
        println json
        throw new IllegalStateException("Jira project creation failed.");
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
    File projDir = new File(workspace, "proj");
    projDir.mkdirs();

    jenkinsFile = createJenkinsFile(projDir, repoName, jiraProjectName, leaderMail);

    addFileInRepo(jenkinsFile, repoName) 
}

def createJenkinsFile(projDir, repoName, jiraProjectName, leaderMail) {
    File jenkinsFile = new File(projDir, "Jenkinsfile");
    jenkinsFile.write updateTemplateVariables("Jenkinsfile.tpl", [
        _JIRA_PROJECT_NAME_      : jiraProjectName,
        _GITHUB_REPOSITORY_NAME_ : repoName,
        _GITHUB_ORGANIZATION_    : organization(),
        _LEADER_MAIL_            : leaderMail,
        _GITHUB_CREDENTIALS_ID_  : GITHUB_CREDENTIALS_ID
    ])

    return jenkinsFile;
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
                    consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"
    return resp;                    
}


def createDashingConfiguration(jiraKey)
{
    def json = asJson([project: jiraKey])
    
    httpRequest acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${DASHING_END_POINT}/project",
                consoleLogResponseBody: VERBOSE_REQUESTS 
}

def updateTaskboardConfiguration(jiraKey, leaderJiraName)
{
    httpRequest acceptType: 'APPLICATION_JSON', authentication: TASKBOARD_AUTH_ID, httpMode: 'POST', url: "${TASKBOARD_END_POINT}/api/projects?projectKey=${jiraKey}",
                requestBody: asJson([projectKey: JiraKey, teamLeader: leaderJiraName]) ,consoleLogResponseBody: VERBOSE_REQUESTS
}

def updateTemplateVariables(templateName, varMap)
{
    def txt = new File(workspace, templateName).text;
    for (e in varMap) {
        txt = txt.replace("#{"+e.key+"}", e.value);
    }
    return txt;
}

def createJobFromTemplate(jobName, templateFile, varMap) {
    def jobXml = updateTemplateVariables(templateFile, varMap )
    try {
        Jenkins.instance.createProjectFromXML(jobName, new ByteArrayInputStream(jobXml.getBytes()))
    } catch(IllegalArgumentException e) {
        println "Job ${jobName} not created (reason: ${e.message}), probably already exists. Just ignore."
    }
}

def createProjectJobs(githubRepoName) {
    createJobFromTemplate(githubRepoName+"-pr-builder", "pullRequestBuilderJob.tpl", [
        _SCM_SOURCE_ID_          : java.util.UUID.randomUUID().toString(),
        _GITHUB_CREDENTIALS_ID_  : GITHUB_CREDENTIALS_ID,
        _GITHUB_REPOSITORY_NAME_ : githubRepoName,
        _GITHUB_ORGANIZATION_    : organization(),
        _JIRA_KEY_               : JiraKey
    ])

    createJobFromTemplate(githubRepoName+"-bundle-build", "bundle-build-config.tpl", [
        _SCM_SOURCE_ID_          : java.util.UUID.randomUUID().toString(),
        _GITHUB_CREDENTIALS_ID_  : GITHUB_CREDENTIALS_ID,
        _GITHUB_REPOSITORY_NAME_ : githubRepoName,
        _GITHUB_ORGANIZATION_    : organization(),
        _JIRA_KEY_               : JiraKey
    ])

    def view = Jenkins.instance.getView(JiraKey);
    if (view != null) {
        println "View ${JiraKey} already exists. Skip"
    }
    else {
        view = new ListView(JiraKey, Jenkins.instance);
        Jenkins.instance.addView(view)
    }
    view.add(Jenkins.instance.getItem(githubRepoName+"-pr-builder"))
    view.add(Jenkins.instance.getItem(githubRepoName+"-bundle-build"))
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

def isJobPropertiesObsolete() {
    def shouldHave = []
    for (e in Jenkins.instance.getItem(JOB_NAME).properties) {
        if (e.key instanceof hudson.model.ParametersDefinitionProperty.DescriptorImpl) {
            shouldHave = e.value.parameterDefinitionNames
        }   
    }
    
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
    def strategy = Jenkins.instance.authorizationStrategy;
    def projectRoleMap = strategy.roleMaps.get(PROJECT);
    def role = projectRoleMap.getRole("@DescriptionMatchMacroRole([{]team:{SID}[}])")

    try {
        if (role == null) {
            println "It's not possible to team role because the required role doesn't exist"
            return;
        }
        println "Assign $jiraKey to role $role"
        projectRoleMap.assignRole(role,jiraKey);
    }finally {
        strategy = null;
        projectRoleMap = null;
        role = null;
    }
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

def isEmpty(s) {
    return s == null || "".equals(GithubOrganization)
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

        if (isEmpty(ProjectOwner)) 
            throw new IllegalArgumentException("You must provide the team leader")

        if (isEmpty(GithubRepoName)) 
            throw new IllegalArgumentException("You must provide the git repository name")

        if (isEmpty(JiraKey)) 
            throw new IllegalArgumentException("You must provide the jira key for the project")

    }
    stage('Checkout') {
        checkout scm
    }

    stage("Parameter existence validation") {
        if (isJobPropertiesObsolete()) {
            throw new IllegalArgumentException("Some of the build parameters are missing. It might be due to obsolete JenkinsFile. Retry your build");
        } 
    }

    GITHUB_REPOS_API_ENDPOINT = "repos/${organization()}"

    def leaderJiraName = ProjectOwner.split("/")[0]
    def leaderMail = ProjectOwner.split("/")[1]


    stage("Github Project Creation") {
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
