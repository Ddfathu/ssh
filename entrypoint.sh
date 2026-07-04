#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: Operational Orchestration & Dynamic Reverse Proxy Multiplexing Engine
# AUTHOR: Advanced Systems Architecture Group
# ==============================================================================

set -o pipefail

# Global Configuration Parameters
LOG_FILE="/var/log/tunnel_orchestrator.log"
CONFIG_DIR="/etc/tunnel_config"
XRAY_CONFIG="${CONFIG_DIR}/xray_ws.json"
NGINX_TEMPLATE="/etc/nginx/nginx.conf"

mkdir -p "${CONFIG_DIR}"
touch "${LOG_FILE}"

log_info() {
    echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S') UTC] [INFO] $1" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S') UTC] [WARN] $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S') UTC] [ERROR] $1" | tee -a "${LOG_FILE}"
}

log_info "Initializing Runtime Environment for Multi-Protocol Tunneling Suite."

# Capture the environment port injected dynamically by Render's Load Balancer
if [ -z "${PORT}" ]; then
    log_warn "The dynamic 'PORT' variable was not detected from the environment. Defaulting core ingress to 8080."
    TARGET_INGRESS_PORT=8080
else
    log_info "Dynamic Ingress Port allocation verified. System binding to: ${PORT}"
    TARGET_INGRESS_PORT=${PORT}
fi

# System Authentication Management Section
TUNNEL_USER="${SSH_USER:-$DEFAULT_USER}"
TUNNEL_PASS="${SSH_PASSWORD:-$DEFAULT_PASS}"

log_info "Configuring active user identity credentials..."
if id "$TUNNEL_USER" &>/dev/null; then
    log_info "User Account '${TUNNEL_USER}' exists. Overwriting current security layer keys."
else
    log_info "Creating production sandbox isolation account: ${TUNNEL_USER}"
    adduser -D -s /bin/bash "${TUNNEL_USER}"
fi

echo "${TUNNEL_USER}:${TUNNEL_PASS}" | chpasswd
log_info "Authentication matrix applied successfully. Username: ${TUNNEL_USER}"

# Generate unique cryptographic footprints for runtime authentication metrics
UUID_SEED=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "a8b7c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d")
JWT_PATH_SSH="/ssh-ws-tunnel-core"
JWT_PATH_XRAY="/xray-vless-ws"
JWT_PATH_GOST="/gost-multiplex-ws"

log_info "--------------------------------------------------------"
log_info "   TUNNEL CONFIGURATION CREDENTIAL MANIFEST (EXPORT)"
log_info "--------------------------------------------------------"
log_info " Ingress Domain : [Render Application Domain URL]"
log_info " Active Port    : 443 (Secured via Render Front-End Edge SSL)"
log_info " Client Username: ${TUNNEL_USER}"
log_info " Client Password: ${TUNNEL_PASS}"
log_info " WebSocket Paths Configured:"
log_info "   -> SSH-WS Endpoint     : ${JWT_PATH_SSH}"
log_info "   -> Xray-VLESS Endpoint : ${JWT_PATH_XRAY}"
log_info "   -> Gost-WS Endpoint    : ${JWT_PATH_GOST}"
log_info " Xray UUID Client Target  : ${UUID_SEED}"
log_info "--------------------------------------------------------"

# 1. OpenSSH Engine Initialization & Bind Tuning
sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
sed -i "s/Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    log_warn "RSA Host keys missing from temporary store. Regenerating key bits."
    ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
fi
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -q -N "" -t ecdsa -b 521 -f /etc/ssh/ssh_host_ecdsa_key
fi
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
fi

# 2. Xray Core Dynamic Engine Configuration Matrix Generation
cat <<EOF > "${XRAY_CONFIG}"
{
  "log": {
    "access": "/var/log/xray_access.log",
    "error": "/var/log/xray_error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": ${XRAY_PORT},
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID_SEED}",
            "level": 0,
            "email": "core-node@render.internal"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${JWT_PATH_XRAY}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

# 3. Dynamic Nginx Gateway Re-configuration Engine
cat <<EOF > "${NGINX_TEMPLATE}"
user root;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    server_tokens off;

    server {
        listen ${TARGET_INGRESS_PORT} default_server;
        listen [::]:${TARGET_INGRESS_PORT} default_server;
        server_name _;

        root /var/www/html;
        index index.html;

        location / {
            try_files \$uri \$uri/ =404;
        }

        location ${JWT_PATH_SSH} {
            if (\$http_upgrade != "websocket") {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${GOST_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        location ${JWT_PATH_XRAY} {
            if (\$http_upgrade != "websocket") {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:${XRAY_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }
    }
}
EOF

log_info "System orchestration layers calculated completely. Handing control loop off to Supervisor..."
rm -f /var/run/nginx.pid /var/run/sshd.pid
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
