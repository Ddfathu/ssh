FROM alpine:3.19

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SSH_PORT=2222 \
    XRAY_PORT=8081 \
    GOST_PORT=8082 \
    CORE_PORT=8080 \
    DEFAULT_USER=nodeuser \
    DEFAULT_PASS=TunnelCoreSecureAuth2026!

# Install package internal tanpa download luar (Railway friendly)
RUN apk update && apk add --no-cache bash openssh-server openssh-sftp-server supervisor nginx jq tzdata && rm -rf /var/cache/apk/*

RUN mkdir -p /usr/local/bin /var/run/sshd /var/log/supervisor /var/log/nginx /etc/tunnel_config /var/www/html

# TRICK: Copy langsung binary yang lo download ke dalam folder sistem
COPY gost /usr/local/bin/gost
COPY xray /usr/local/bin/xray
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY html_fake/ /var/www/html/

# Set ijin eksekusi file
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/gost && \
    chmod +x /usr/local/bin/xray && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
