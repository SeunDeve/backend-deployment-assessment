#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/backend-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== Backend bootstrap started: $(date) ====="

wait_for_network() {
  echo "Waiting for outbound internet connectivity..."

  for i in $(seq 1 20); do
    if curl -s --max-time 5 https://github.com >/dev/null 2>&1; then
      echo "Network ready."
      return 0
    fi

    echo "Network unavailable. Retry $i/20..."
    sleep 15
  done

  echo "ERROR: Network never became available."
  exit 1
}

retry_command() {
  local max_attempts=10
  local attempt=1

  until "$@"; do
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Command failed after $attempt attempts: $*"
      exit 1
    fi

    echo "Retrying command ($attempt/$max_attempts): $*"
    attempt=$((attempt + 1))
    sleep 15
  done
}

wait_for_network

echo "Updating packages..."
retry_command yum update -y

echo "Installing Git..."
retry_command yum install -y git

echo "Installing Docker..."
retry_command amazon-linux-extras install docker -y

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

echo "Installing Docker Compose plugin..."

mkdir -p /usr/local/lib/docker/cli-plugins

retry_command curl -SL \
https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
-o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "Verifying installation..."

docker --version
docker compose version
git --version

touch /home/ec2-user/setup-complete.log
chown ec2-user:ec2-user /home/ec2-user/setup-complete.log

echo "===== Backend bootstrap completed: $(date) ====="