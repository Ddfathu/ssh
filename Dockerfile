FROM alpine:3.19

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SSH_PORT=2222 \
    DEFAULT_USER=nodeuser \
    DEFAULT_PASS=TunnelCoreSecureAuth2026!

# Install tools yang beneran dibutuhin aja (Tanpa Nginx & Xray)
RUN apk update && apk add --no-cache bash openssh-server openssh-sftp-server supervisor jq tzdata && rm -rf /var/cache/apk/*

RUN mkdir -p /usr/local/bin /var/run/sshd /var/log/supervisor /etc/tunnel_config

# Copy binary dan script pendukung
COPY gost /usr/local/bin/gost
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/gost && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
