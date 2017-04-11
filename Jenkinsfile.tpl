#!groovy
import groovy.json.JsonSlurper

properties([disableConcurrentBuilds()])


def gitRepository = '#{_GITHUB_ORGANIZATION_}/#{_GITHUB_REPOSITORY_NAME_}'
def projectName = "#{_JIRA_PROJECT_NAME_}#"
def projectKey  = "#{_GITHUB_REPOSITORY_NAME_}#"

@NonCPS
def getLogin(String json) {
	return new JsonSlurper().parseText(json).user.login
}

@NonCPS
def getEmail(String json) {
	return new JsonSlurper().parseText(json).email
}

@NonCPS
def isPullRequest()
{
	return env.CHANGE_ID != null
}

@NonCPS
def shouldClosePullRequest()
{
	File failureReasonFile = new File("failureReasonFile");
	if (!failureReasonFile.exists())
		return false;
	
	def reasonText = failureReasonFile.text.trim();
	if (reasonText.matches(".*Task: compileJava.*org.gradle.api.internal.tasks.compile.CompilationFailedException.*"))
		return true;

	if (reasonText.matches(".*Task: compileTestJava.*org.gradle.api.internal.tasks.compile.CompilationFailedException.*"))
		return true;

	if (reasonText.matches(".*Task: test.*There were failing tests.*"))
		return true;

	return false;
}

@NonCPS
def onError() {
	if (!isPullRequest())
		return;

	if (!shouldClosePullRequest()) {
		println "Will not close PR because error is not considered to be introduced by new code"
		return;
	}

	def gitAuthentication = 'lfrgsGithubAuthentication'
	def emailText = 'Your Pull Request PR-${CHANGE_ID} broke the build and will be removed. Please fix it at your earliest convenience and re-submit. ${JOB_URL}'
	def emailSubject = "Validate PR-${CHANGE_ID}"
	def emailLeader = '#{_LEADER_MAIL_}'

	def body = """
	{"state": "closed"}
	"""
	httpRequest acceptType: 'APPLICATION_JSON', authentication: "${gitAuthentication}", contentType: 'APPLICATION_JSON', httpMode: 'PATCH', requestBody: body, url: "https://api.github.com/repos/${gitRepository}/pulls/${CHANGE_ID}"			

	def response = httpRequest acceptType: 'APPLICATION_JSON', authentication: "${gitAuthentication}", contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "https://api.github.com/repos/${gitRepository}/pulls/${CHANGE_ID}"
	def login = getLogin(response.content)

	def respUser = httpRequest acceptType: 'APPLICATION_JSON', authentication: "${gitAuthentication}", contentType: 'APPLICATION_JSON', httpMode: 'GET', url: "https://api.github.com/users/${login}"
	def email = getEmail(respUser.content)
	
	emailext body: "${emailText}", subject: "${emailSubject}", to: "${email}"
	emailext body: "${emailText}", subject: "${emailSubject}", to: "${emailLeader}"
}

@NonCPS
def gradlew(args)
{
	if (isUnix())
		sh "./gradlew " + args
	else
		bat "gradlew " + args
}

@NonCPS
def appendAdditionalCommand(fileName, additionalCustomCommands) {
    def value = '';
    if (fileExists(fileName)) {
        value = readFile(fileName);
    }
    value += '\n\n'+ additionalCustomCommands;
    writeFile file: fileName, text: value
}

@NonCPS
def sonarqube(args)
{
	print "Running sonar with arguments : ${args}"
	gradlew "sonarqube -Dsonar.buildbreaker.queryMaxAttempts=90 -Dsonar.buildbreaker.skip=true -Dsonar.host.url=${SonarHostUrl} ${args}"
}

node ("pr-agent") {
	try {
		stage('Checkout') {
			checkout scm
		}

		stage('Setup') {
			def bundlesDir = new File("bundles");
			if (bundlesDir.exists()) 
				bundlesDir.deleteDir();

			def url = "${env.URL_GRADLE_ADDITIONAL_CUSTOM_COMMANDS}";
			def additionalCustomCommands = new URL(url).getText();
			additionalCustomCommands = additionalCustomCommands.replace("#{_SONAR_PROJECT_NAME_}", "${projectName}")
			additionalCustomCommands = additionalCustomCommands.replace("#{_SONAR_PROJECT_KEY_}", "${projectKey}")
			appendAdditionalCommand("build.gradle", additionalCustomCommands) ;
			
			gradlew 'clean'
		}

		stage('Init Bundle') {
			gradlew 'initBundle'
		}

		stage('Build') {
			try {
				gradlew 'build -x test'	
			} catch (exc) {
				onError()
				throw exc
			}
		}

		stage('Test') {
			try {
				gradlew 'test'
			} catch (exc) {
				onError()
				throw exc
			} finally {
				junit '**/build/test-results/test/*.xml'
			}
		}

		stage('Sonar') {
			if (isPullRequest()) {
				println "Will evaluate the Pull Request"
				sonarqube "-Dsonar.analysis.mode=preview -Dsonar.github.pullRequest=${CHANGE_ID} -Dsonar.github.oauth=${GithubOauth} -Dsonar.github.repository=${gitRepository}"
			}
			else
				sonarqube ""
		}
	}finally {
		stage('Cleanup') {
			dir(workspace) {
				deleteDir();
			}
		}
	}
}
