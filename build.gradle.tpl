import groovy.io.FileType;

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

