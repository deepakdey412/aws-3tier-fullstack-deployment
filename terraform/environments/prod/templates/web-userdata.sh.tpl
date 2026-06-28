#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/userdata.log | logger -t userdata) 2>&1

echo "=== Web Tier Bootstrap: $(date) ==="

# ── System Update ──────────────────────────────────
apt-get update -y
apt-get upgrade -y
apt-get install -y nginx curl unzip awscli

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
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/web/${project_name}-${environment}",
            "log_stream_name": "{instance_id}/nginx-access"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/web/${project_name}-${environment}",
            "log_stream_name": "{instance_id}/nginx-error"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# ── Download Frontend Build from S3 ───────────────
APP_DIR=/var/www/html
mkdir -p $APP_DIR

# Try to pull pre-built frontend from S3; fall back to placeholder
if aws s3 cp s3://${s3_bucket}/builds/frontend/dist.tar.gz /tmp/dist.tar.gz 2>/dev/null; then
  tar -xzf /tmp/dist.tar.gz -C $APP_DIR
  echo "Frontend deployed from S3"
else
  echo "No frontend build found in S3 — serving placeholder"
  cat > $APP_DIR/index.html <<'HTML'
<!DOCTYPE html>
<html><head><title>Loading…</title></head>
<body><h2>Frontend build not yet deployed. Run deploy.sh to push the React build.</h2></body>
</html>
HTML
fi

# ── Nginx Config ───────────────────────────────────
APP_ALB_DNS="${app_alb_dns}"

cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    # Serve React SPA
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy API calls to the internal App ALB
    location /api/ {
        proxy_pass         http://$APP_ALB_DNS:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
}
NGINX

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "=== Web Tier Bootstrap Complete: $(date) ==="
