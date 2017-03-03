import groovy.io.FileType;

plugins {
  id "org.sonarqube" version "2.2.1"
}

allprojects {
	apply plugin: "idea"
	apply plugin: 'nebula.provided-base'
	apply plugin: "jacoco"

	jacoco{
		group = "Coverage"
		description = "Generate Jacoco coverage reports after running tests."
	}
}


distBundle {
	exclude "**/Source-formatter*.jar"
}

downloadBundle {
	onlyIf {
		String url = downloadBundle.src.toString()
		File cachedFile = new File(downloadBundle.dest, url.substring(url.lastIndexOf('/') + 1))

		if (cachedFile.exists()) {
			return false
		}

		return true
	}
}

sonarqube {
	def generated = [];
	new File(".").eachFileRecurse(FileType.FILES) { file ->  
		if (!file.getName().endsWith(".java")) return;
		if (!file.text.contains("* @generated")) return;
		generated.add(file.getPath().replaceAll("^.*src/","src/"));
	}  

	def filesExcludedFromAnalysis = generated.join(",")
	properties {
		property "sonar.projectName", "#{_JIRA_PROJECT_NAME_}"
		property "sonar.projectKey", "#{_GITHUB_REPOSITORY_NAME_}"
		property "sonar.jacoco.reportPath", "${project.buildDir}/jacoco/test.exec"
		property "sonar.jacoco.reportMissing.force.zero", "true"
		property "sonar.coverage.exclusions", filesExcludedFromAnalysis
		property "sonar.exclusions", filesExcludedFromAnalysis
	}
}

gradle.taskGraph.afterTask { Task task, TaskState state ->
	if (state.failure ) {
		def failureReasonFile = new File("failureReason");
		def rootException = state.failure;
		while (rootException.cause != null)
			rootException = rootException.cause;

		def reason = "Message: ${rootException.message} Exception: ${rootException.class}"
		failureReasonFile.append(System.getProperty("line.separator")+"Task: ${task.name} Reason: ${reason}");
	}
}

