FROM jenkins/jenkins:lts
USER root

# Install Docker Client
RUN apt-get update -qq \
    && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
       $(lsb_release -cs) \
       stable" \
    && apt-get update -qq \
    && apt-get -y install docker-ce

RUN usermod -aG docker jenkins

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Set up Jenkins environment for Docker and Azure CLI
USER jenkins
RUN mkdir -p /var/jenkins_home/.azure \
    && mkdir -p /var/jenkins_home/.aws

# Default entrypoint
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
