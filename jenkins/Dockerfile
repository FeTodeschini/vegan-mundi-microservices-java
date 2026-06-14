FROM jenkins/jenkins:lts

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    openssh-client \
    build-essential \
    python3 \
    python3-pip \
    default-mysql-client \
    zip \
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Java (required for Maven builds)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    && apt-get clean

# Install Maven
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz \
    | tar xzf - -C /opt && \
    ln -s /opt/apache-maven-3.9.1 /opt/maven

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV M2_HOME=/opt/maven
ENV PATH=$PATH:$M2_HOME/bin

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.4.0/terraform_1.4.0_linux_amd64.zip -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# Install Docker CLI (for building images)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-25.0.0.tgz | \
    tar xz -C /usr/local/bin --strip-components=1 docker/docker

# Switch back to jenkins user
USER jenkins

# Set working directory
WORKDIR /var/jenkins_home

# Copy groovy scripts and plugins if needed
# COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

EXPOSE 8080
