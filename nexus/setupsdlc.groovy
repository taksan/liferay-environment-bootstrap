/*
This script setups view/edit permissions for a ROLE named "jiraKey" to access artifacts matching the jira key. 
*/
import org.sonatype.nexus.common.entity.*
import org.sonatype.nexus.security.*
import org.sonatype.nexus.security.authz.*
import org.sonatype.nexus.selector.*
import com.google.common.collect.ImmutableMap
import groovy.json.JsonOutput
import groovy.json.JsonSlurper

def request = new JsonSlurper().parseText(args);
assert request.jiraKey: 'jiraKey is required';
assert request.repoName: 'repoName is required';

def jiraKey = request.jiraKey

// use container.lookup to fetch internal APIs we need to use
def selectorManager = container.lookup(SelectorManager.class.name)
def securitySystem = container.lookup(SecuritySystem.class.name)
def authorizationManager = securitySystem.getAuthorizationManager('default')

// create content selector (if not already present)
def selectorConfig = new SelectorConfiguration(
    name: "${jiraKey}-content-selector",
    type: 'jexl',
    description: "$jiraKey content selector",
    attributes: ['expression': 'path=~"/' + jiraKey + '/.*"']
)

if (selectorManager.browse().find { it -> it.name == selectorConfig.name } != null) 
    return "$jiraKey already setup";

selectorManager.create(selectorConfig)

// create content selector privilege
def projectPrivProperties = ImmutableMap.builder()
  .put("contentSelector", selectorConfig.name)
  .put("repository", request.repoName)
  .put("actions", "browse,read,edit")
  .build()

def projectPrivilege = new org.sonatype.nexus.security.privilege.Privilege(
    id: "jenkins-${jiraKey}-priv",
    version: '',
    name: "auto_sdlc-${jiraKey}-priv",
    description: "${jiraKey} Content Selector privilege",
    type: "repository-content-selector",
    properties: projectPrivProperties
)
authorizationManager.addPrivilege(projectPrivilege)


// create a role with the privileges to access the project
def role = new org.sonatype.nexus.security.role.Role(
    roleId: jiraKey,
    source: "Nexus",
    name: jiraKey,
    description: "${jiraKey} access ROLE",
    readOnly: false,
    privileges: [ projectPrivilege.id ],
    roles: []
)
authorizationManager.addRole(role)
