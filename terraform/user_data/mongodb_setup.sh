#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/mongodb-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== MongoDB bootstrap started: $(date) ====="

MONGO_ROOT_USERNAME="$${mongo_root_username:-admin}"
MONGO_ROOT_PASSWORD="$${mongo_root_password:-changeme}"

wait_for_network() {
  for i in $(seq 1 20); do
    if curl -s --max-time 5 https://repo.mongodb.org >/dev/null 2>&1; then
      return 0
    fi
    sleep 15
  done

  echo "Network unavailable"
  exit 1
}

retry_command() {
  local max_attempts=10
  local attempt=1

  until "$@"; do
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "Command failed: $*"
      exit 1
    fi

    attempt=$((attempt + 1))
    sleep 15
  done
}

wait_for_network

retry_command yum update -y

cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

retry_command yum install -y mongodb-org

grep -q "bindIp: 0.0.0.0" /etc/mongod.conf || \
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf

systemctl enable mongod
systemctl start mongod

sleep 10

cat > /tmp/create-admin.js <<EOF
db = db.getSiblingDB("admin");

if (!db.getUser("$MONGO_ROOT_USERNAME")) {
  db.createUser({
    user: "$MONGO_ROOT_USERNAME",
    pwd: "$MONGO_ROOT_PASSWORD",
    roles: [
      { role: "root", db: "admin" }
    ]
  });
}
EOF

mongosh < /tmp/create-admin.js

grep -q "authorization: enabled" /etc/mongod.conf || cat >> /etc/mongod.conf <<EOF

security:
  authorization: enabled
EOF

systemctl restart mongod

sleep 10

mongosh \
-u "$MONGO_ROOT_USERNAME" \
-p "$MONGO_ROOT_PASSWORD" \
--authenticationDatabase admin \
--eval "db.adminCommand({ ping: 1 })"

echo "MongoDB successfully configured."

systemctl is-active mongod

echo "===== MongoDB bootstrap completed: $(date) ====="