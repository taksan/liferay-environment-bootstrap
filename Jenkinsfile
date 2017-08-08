#!groovy
@Library("liferay-sdlc-jenkins-lib")

import groovy.transform.Field;
import groovy.json.*;
import java.util.Base64;
import java.util.concurrent.TimeUnit;
import java.lang.IllegalArgumentException;
import org.apache.commons.lang3.StringUtils;
import org.liferay.sdlc.CredentialsManager;
import com.cloudbees.plugins.credentials.CredentialsMatchers;
import com.cloudbees.plugins.credentials.CredentialsProvider;
import com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials;
import com.cloudbees.plugins.credentials.domains.URIRequirementBuilder;
import hudson.model.Item;
import hudson.security.ACL;

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
//            choiceParameter("ProjectOwner", "Project's owner user", "displayName", '{name+"/"+emailAddress}', jiraDataProvider(), ""),
            stringParameter("ProjectOwner","Project owneer"),
            autocompleteParameter("JiraAdministrators", "Project administrators", "displayName", "name", jiraDataProvider()),
            autocompleteParameter("JiraDevelopers", "Project developers", "displayName", "name", jiraDataProvider()),
            autocompleteParameter("JiraCustomers", "Project customers", "displayName", "name", jiraDataProvider()),
            stringParameter("BuildServerIp", """IP Address of the server that will build the jobs. You must setup the server to have a 'jenkins' user that authorizes the following public key:

ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAsaAmegjHI2/EbjJH8LHRwpQs1SuM6NP0kTIzRnEk/oHMG9ZUVpifg5++2hzyQ9Aub13Ggg5Mr33QM09moCZd0fo/RyXhv/i/B2pEb29KpgqJ0t/hs+y3Z2S2vxXVkd3zJ+LmEL/Lwtdmx1Y8l3wF7/MP/cPjBtWHdjT+5BGR1xbJN+Ma7IchR5TeIaCas3VVvK2UxBwzVarB9ErmA1k3pARcNO7Ho64nxkpq3X7V711InUVlPARzJVPCX9FwruDH15APilnDWOSJIjDu779XDyIYUr4DUFgzKk1nrJGPlcbOuNBpIeKLEPQGafmNnt99xX8girC+wNCNOkiGbPSm4Q== jenkins@gs-ci.liferay.com"""),
            stringParameter("GithubOrganization", "(optinal) Custom Github organization"),
            stringParameter("GithubUsername", "(optional) Custom Github user"),
            passwordParameter("GithubPassword", "(optional) Custom Github password"),
            choiceParameter("CustomTimeZone", """(optional) Custom TimeZone. This value is used to calculate the \'Pull Request Aging\' of the dashboard more precisely.
Default value: """ + jenkinsTimeZoneId(), "displayName", "id", timeZoneDataProvider(), jenkinsTimeZoneId())
        ]
    ]
])

def stringParameter(name, description, defaultValue="") {
    return [ name: name, description: description, $class: 'StringParameterDefinition', default: defaultValue]
}

def passwordParameter(name, description) {
    return [ name: name, description: description, $class: 'PasswordParameterDefinition', default: ""]
}

def autocompleteParameter(name, description, displayExpression, valueExpression, dataProvider) {
    return [
        $class: 'AutoCompleteStringParameterDefinition', 
        name: name,
        description: description,
        defaultValue: '',
        allowUnrecognizedTokens: false,
        displayExpression: displayExpression,
        valueExpression: valueExpression,
        dataProvider: dataProvider
        ];
}

def choiceParameter(name, description, displayExpression, valueExpression, dataProvider, defaultValue) {
    return [
        $class: 'DropdownAutocompleteParameterDefinition',
        name: name,
        description: description,
        defaultValue: defaultValue,
        displayExpression: displayExpression,
        valueExpression: valueExpression,
        dataProvider: dataProvider
        ];
}

def jiraDataProvider() {
    return [ 
        $class: 'RemoteDataProvider', 
        autoCompleteUrl: "\$JIRA_REST_ENDPOINT/rest/projectbuilder/1.0/users", 
        credentialsId: JIRA_CREDENTIALS_ID] 
}

def timeZoneDataProvider() {
    return [
        $class: 'InlineJsonDataProvider',
        autoCompleteData: asJson(timeZoneList())
    ]
}

def timeZoneList() {
    def List<String> ids = TimeZone.getAvailableIDs();
    def List<String> results = new ArrayList<>();
    for (String id : ids) {
       results.add([ id: TimeZone.getTimeZone(id).getID(), displayName: timeZoneDisplayFormat(TimeZone.getTimeZone(id)) ]);
    }
    return results;
}

def timeZoneDisplayFormat(TimeZone tz) {
    def hours = TimeUnit.MILLISECONDS.toHours(tz.getRawOffset());
    def minutes = TimeUnit.MILLISECONDS.toMinutes(tz.getRawOffset()) - TimeUnit.HOURS.toMinutes(hours);
    minutes = Math.abs(minutes);
    def result;
    if (hours > 0) {
        result = String.format("(GMT+%d:%02d) %s", hours, minutes, tz.getID());
    } else {
        result = String.format("(GMT%d:%02d) %s", hours, minutes, tz.getID());
    }
    return result;
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
            [ id: "18622", schemeId: "19982" ],
            [ id: "19434", schemeId: "20898" ],
            [ id: "19435", schemeId: "20899" ]
            ]
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
            projectTypeKey           : "software",
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

    def assigneeJson = asJson([ assigneeType: 'UNASSIGNED' ]);

    // change default assignee to UNASSIGNED
    resp = httpRequest acceptType: 'APPLICATION_JSON', authentication: JIRA_CREDENTIALS_ID, contentType: 'APPLICATION_JSON', httpMode: 'PUT', requestBody: assigneeJson, 
            url: "${JIRA_REST_ENDPOINT}/rest/project/${jiraKey}", consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"

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

def serviceUrl(serviceEndpoint) {
    return "https://api.github.com/$serviceEndpoint";
}

def githubRequest(serviceEndpoint, mode, json) {
    resp = httpRequest acceptType: 'APPLICATION_JSON', authentication: githubCredentialsId(), contentType: 'APPLICATION_JSON', httpMode: mode, requestBody: json, url: serviceUrl(serviceEndpoint),
                    consoleLogResponseBody: VERBOSE_REQUESTS, validResponseCodes: "100:599"
    return resp;                    
}


def createDashingConfiguration(jiraKey, githubUser, githubPassword, githubRepoName, timeZone) {
    def json = asJson([
        project: jiraKey,
        'github-user': githubUser,
        'github-password': githubPassword,
        'github-reponame': githubRepoName,
        'time-zone': timeZone
    ])
    
    httpRequest acceptType: 'APPLICATION_JSON', authentication: 'dashboardCredentials', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: json, url: "${DASHING_END_POINT}/project",
                consoleLogResponseBody: VERBOSE_REQUESTS 
}

def updateTaskboardConfiguration(jiraKey, leaderJiraName)
{
    httpRequest acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', authentication: TASKBOARD_AUTH_ID, httpMode: 'POST', url: "${TASKBOARD_END_POINT}/api/projects?projectKey=${jiraKey}",
                requestBody: asJson([projectKey: JiraKey, teamLeader: leaderJiraName]) ,consoleLogResponseBody: VERBOSE_REQUESTS

    httpRequest authentication: TASKBOARD_AUTH_ID, url: "${TASKBOARD_END_POINT}/cache/configuration", consoleLogResponseBody: VERBOSE_REQUESTS

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
    assignSidToRole(jiraKey, "@ViewMatchSidMacroRole");
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

def lookupUsernamePasswordCredentials(credentialsId) {
    if (credentialsId == null)
        return null;

    return CredentialsMatchers.firstOrNull(
        CredentialsProvider.lookupCredentials(
            StandardUsernamePasswordCredentials.class,
            Jenkins.instance,
            ACL.SYSTEM
        ),
        CredentialsMatchers.withId(credentialsId)
    );
}

def jenkinsTimeZoneId() {
    def calendar = Calendar.getInstance();
    def id = calendar.getTimeZone().SHORT;
    def tz = TimeZone.getTimeZone(id.toString());
    return tz.getID();
}

def isEmpty(s) {
    return s == null || "".equals(s)
}

node ("master"){
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
//        if (isJobPropertiesObsolete()) {
//            error("Some of the build parameters are missing. It might be due to obsolete JenkinsFile. Retry your build");
//        } 
        println "ignore"
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
           new CredentialsManager().createUsernameWithPasswordCredentials(githubCredentialsId(), "Credentials for ${GithubOrganization}/${GithubRepoName}", GithubUsername, GithubPassword)
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
        if ( isEmpty(GithubUsername) || isEmpty(GithubPassword) ) {
            def credentials = lookupUsernamePasswordCredentials(githubCredentialsId());
            GithubUsername = credentials.getUsername();
            GithubPassword = credentials.getPassword().plainText;
        }
        if (isEmpty(CustomTimeZone)) {
            CustomTimeZone = jenkinsTimeZoneId();
        }
        createDashingConfiguration(JiraKey, GithubUsername, GithubPassword, GithubRepoName, CustomTimeZone);
    }

    stage("Build server Slave setup") {
        createJenkinsSlave(GithubRepoName, "$JiraProjectName's build server", BuildServerIp, 'jenkins-slaves');
    }

    stage("Taskboard project setup") {
        updateTaskboardConfiguration(JiraKey, leaderJiraName);
    }

    stage("Setting up project permission scheme on Jenkins") {
        setupPermissionRoles(JiraKey);
    }
}
