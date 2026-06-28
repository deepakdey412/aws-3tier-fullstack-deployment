#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/userdata.log | logger -t userdata) 2>&1

echo "=== App Tier Bootstrap: $(date) ==="

# ── System Update ──────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip awscli

# ── Java 21 ───────────────────────────────────────
apt-get install -y openjdk-21-jdk-headless
java -version

# ── CloudWatch Agent ──────────────────────────────
curl -fsSL https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o /tmp/cwa.deb
dpkg -i /tmp/cwa.deb

cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/app/logs/spring.log",
            "log_group_name": "/app/${project_name}-${environment}",
            "log_stream_name": "{instance_id}/spring-app"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# ── Application Setup ──────────────────────────────
APP_DIR=/opt/app
mkdir -p $APP_DIR/logs

# Write env file
cat > $APP_DIR/.env <<ENV
DB_HOST=${db_endpoint}
DB_PORT=3306
DB_NAME=${db_name}
DB_USERNAME=${db_username}
DB_PASSWORD=${db_password}
AWS_REGION=${aws_region}
S3_BUCKET=${s3_bucket}
SERVER_PORT=8080
ENV

# ── Systemd Service ────────────────────────────────
cat > /etc/systemd/system/crud-app.service <<'SERVICE'
[Unit]
Description=CRUD Spring Boot Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/java -jar /opt/app/app.jar \
  --server.port=8080 \
  --spring.datasource.url=jdbc:mysql://$${DB_HOST}/$${DB_NAME}?useSSL=true&serverTimezone=UTC \
  --spring.datasource.username=$${DB_USERNAME} \
  --spring.datasource.password=$${DB_PASSWORD} \
  --logging.file.name=/opt/app/logs/spring.log
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=crud-app

[Install]
WantedBy=multi-user.target
SERVICE

# ── Pull JAR from S3 (if present) ─────────────────
if aws s3 cp s3://${s3_bucket}/builds/backend/app.jar $APP_DIR/app.jar 2>/dev/null; then
  chown ubuntu:ubuntu $APP_DIR/app.jar
  systemctl daemon-reload
  systemctl enable crud-app
  systemctl start crud-app
  echo "Backend service started"
else
  echo "No JAR found in S3 yet — service will start after deploy.sh runs"
  systemctl daemon-reload
  systemctl enable crud-app
fi

echo "=== App Tier Bootstrap Complete: $(date) ==="
