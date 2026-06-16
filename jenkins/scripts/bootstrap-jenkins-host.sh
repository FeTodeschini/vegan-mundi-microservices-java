#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <repo-url> [branch]"
  exit 1
fi

REPO_URL="$1"
BRANCH="${2:-main}"
WORKDIR="/opt/jenkins"

sudo dnf update -y
sudo dnf install -y docker git docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [[ ! -d vegan-mundi-java ]]; then
  git clone --branch "$BRANCH" "$REPO_URL" vegan-mundi-java
fi

cd vegan-mundi-java/jenkins

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from template. Edit it before exposing Jenkins publicly."
fi

docker compose up -d --build

echo "Jenkins started. Check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
