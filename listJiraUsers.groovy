import groovy.json.JsonSlurper;
import java.net.URL;
import java.util.Base64;

final user = "build";
final password = "build";
//final JIRA_ENDPOINT = "http://10.42.11.231:8081/rest/api/latest";
final JIRA_ENDPOINT = "https://jira.objective.com.br/rest/api/latest";
final wildcard = "%"; // latest jira is .

auth = Base64.getEncoder().encodeToString((user + ":" + password).getBytes());

users = new JsonSlurper().parseText(new URL("${JIRA_ENDPOINT}/user/search?startAt=0&maxResults=1000&username=${wildcard}").getText(requestProperties: ['Authorization': "Basic ${auth}"]))

println users.collect{"${it.displayName} (${it.key})"} 
