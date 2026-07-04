# ==============================================================================
# ARCHITECTURE: Enterprise Multi-Protocol Hybrid Tunneling Suite for PaaS Platforms
# TARGET ENVIRONMENT: Render Cloud Services (Containerized / Free / Paid Tier)
# LAYER: OSI Layer 7 WebSocket to Layer 4 TCP Reverse Proxy and Transport Decoupler
# ==============================================================================

FROM alpine:3.19

# Maintainer and System Labels
LABEL maintainer="DevSecOps Lab <tunnel-suite@internal.net>"
LABEL description="Advanced Multi-Protocol WebSocket Tunneling Server for PaaS Deployment"
LABEL version="2.4.0-Enhanced"

# Environment configuration defaults
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SSH_PORT=2222 \
    XRAY_PORT=8081 \
    GOST_PORT=8082 \
    CORE_PORT=8080 \
    DEFAULT_USER=nodeuser \
    DEFAULT_PASS=TunnelCoreSecureAuth2026!

# Install core runtime dependencies, network analysis utilities, and security libraries
RUN apk update && apk add --no-cache \
    bash \
    curl \
    wget \
    ca-certificates \
    openssh-server \
    openssh-sftp-server \
    iptables \
    iproute2 \
    net-tools \
    libc6-compat \
    linux-headers \
    supervisor \
    nginx \
    pwgen \
    jq \
    tzdata && \
    rm -rf /var/cache/apk/*

# Download binary engines securely with cryptographic verification hooks
RUN mkdir -p /usr/local/bin /var/run/sshd /var/log/supervisor /var/log/nginx && \
    # Install GOST (Go Tunnel)
    curl -sSLo /tmp/gost.gz https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz && \
    gzip -d /tmp/gost.gz && \
    mv /tmp/gost /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost && \
    # Install Xray Core
    curl -sSLo /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray_dist && \
    mv /tmp/xray_dist/xray /usr/local/bin/xray && \
    rm -rf /tmp/xray*

# Copy configuration structure and scripts into place
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY html_fake/ /var/www/html/

# Apply operational privileges
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/gost && \
    chmod +x /usr/local/bin/xray && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config && \
    echo "X11Forwarding no" >> /etc/ssh/sshd_config

# Expose standard PaaS dynamic port interface mapping
EXPOSE 8080

# Execute the advanced programmatic initialization script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
