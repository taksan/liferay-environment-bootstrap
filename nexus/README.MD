# Setup

Run `setup-nexus.sh NEXUS_URL`

# setupsdlc

Usage:

Request:
- Method: POST
- Header: Content-Type: text/plain
- URL: $NEXUS_URL/service/siesta/rest/v1/script/setupauth/run
- Payload: {"jiraKey":"JIRA_KEY", "repo": "NAME_OF_REPO_TO_APPLY VISIBILITY RULE"}

After the request is executed, a user given the role JIRA_KEY, will have access to all artifacts matching repo:$JIRA_KEY/*

# findassets

Usage:

Request:
- Method: POST
- Header: Content-Type: text/plain
- URL: $NEXUS_URL/service/siesta/rest/v1/script/findassets/run
- Payload: {"repoName":"REPO_NANE","pattern":"SEARCH_PATTERN"}

Response example:

{
  "name" : "findassets",
  "result" : "[\"/repository/$REPO/artifact-found.zip\"]"
}%

Observe that "result" field is a escaped json array that can be parsed using any json parser.

