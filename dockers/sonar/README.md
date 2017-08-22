# Sonar
## Configuration
Logged with an **admin** account, perform the following instructions:
- Go to "Administration > Configuration > General Settings > Security" and **enable** "Force user authentication";
- Go to "Administration > Security > Global Permissions" and **revoke** all permissions of "Anyone" group;
- Go to "Administration > Security > Users" and **create an user** with login "jenkins.analyser", name "Jenkins Analyser" and a password;
- Go to "Administration > Security > Permission Templates" and edit "Default template";
    - **Revoke** all permissions of "sonar-users" group;
    - **Grant** "Browse" and "Execute Analysis" to "jenkins.analyser" user;
- In the Jenkins, **create a credential** of type "Username with password" with id "sonar_analyser", username "jenkins.analyser" and the password configured previously.

---
chcon -Rt svirt_sandbox_file_t /opt/taskboard-data/
