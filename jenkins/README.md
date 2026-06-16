# Jenkins Runtime Artifacts

This folder contains runtime and pipeline artifacts for Jenkins.
Terraform provisions the host; this folder defines what Jenkins runs.

## Contents

- `Dockerfile`: Custom Jenkins image with Java, Maven, Terraform, AWS CLI, Docker CLI.
- `docker-compose.yml`: Runs Jenkins container with persistent volume and JCasC mount.
- `plugins.txt`: Jenkins plugins installed at image build time.
- `casc/jenkins.yaml`: Baseline Jenkins Configuration as Code.
- `.env.example`: Local template for admin username/password.
- `Jenkinsfile`: CI/CD pipeline for build, Terraform, ECS deploy, and smoke tests.
- `scripts/bootstrap-jenkins-host.sh`: Host bootstrap helper for EC2.

## Local run

1. `cp .env.example .env`
2. Edit `.env` with strong credentials.
3. `docker compose up -d --build`
4. Open `http://localhost:8080`

## EC2 run

1. SSH to Jenkins EC2 host.
2. Clone repo to `/opt/jenkins/vegan-mundi-java`.
3. `cd /opt/jenkins/vegan-mundi-java/jenkins`
4. `cp .env.example .env` and edit values.
5. `docker compose up -d --build`

## Pipeline Terraform behavior

- Uses env-specific backend key: `vegan-mundi/${ENVIRONMENT}/terraform.tfstate`.
- Auto-loads `terraform.tfvars.local` if present in target env folder.
