#!groovy
import groovy.transform.Field

@Library("liferay-sdlc-jenkins-lib") import static org.liferay.sdlc.SDLCPrUtilities.*

@Field final gitRepository = '#{_GITHUB_ORGANIZATION_}/#{_GITHUB_REPOSITORY_NAME_}'
@Field final projectName = "#{_JIRA_PROJECT_NAME_}"
@Field final projectKey  = "#{_GITHUB_REPOSITORY_NAME_}"

def onError() {
	handleError(gitRepository, "#{_LEADER_MAIL_}", "#{_GITHUB_CREDENTIALS_ID_}")
}

node ("#{_GITHUB_REPOSITORY_NAME_}") {
	try {
		stage('Checkout') {
			checkout scm
		}

		stage('Setup') {
			def bundlesDir = new File("bundles");
			if (bundlesDir.exists()) 
				bundlesDir.deleteDir();

			appendAdditionalCommand("build.gradle", [
				"_SONAR_PROJECT_NAME_" : projectName,
				"_SONAR_PROJECT_KEY_"  : projectKey
			]) ;
			
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
