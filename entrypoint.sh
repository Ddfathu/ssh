#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: Operational Orchestration for Pure TCP/SNI Tunnel Matrix
# TARGET: Railway Free/Trial Layer Deployment
# ==============================================================================

set -o pipefail

# Deteksi otomatis port dinamis yang dikasih sama Railway
if [ -z "${PORT}" ]; then
    TARGET_PORT=8080
else
    TARGET_PORT=${PORT}
fi

# Setup data akun SSH
TUNNEL_USER="${SSH_USER:-$DEFAULT_USER}"
TUNNEL_PASS="${SSH_PASSWORD:-$DEFAULT_PASS}"

if id "$TUNNEL_USER" &>/dev/null; then
    echo "User exists."
else
    adduser -D -s /bin/bash "${TUNNEL_USER}"
fi

echo "${TUNNEL_USER}:${TUNNEL_PASS}" | chpasswd

# Mengalihkan internal port SSH
sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
sed -i "s/Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config

# HACK: Tulis ulang config supervisord agar Gost mengikat port dinamis Railway secara akurat
cat <<EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log

[program:sshd]
command=/usr/sbin/sshd -D -e
autostart=true
autorestart=true

[program:gost-tcp]
command=/usr/local/bin/gost -L="tcp://:${TARGET_PORT}" -F="tcp://127.0.0.1:${SSH_PORT}"
autostart=true
autorestart=true
EOF

rm -f /var/run/sshd.pid
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
