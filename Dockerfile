FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install openssh-server, stunnel4, dan sudo
RUN apt-get update && apt-get install -y \
    openssh-server \
    stunnel4 \
    sudo \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Buat folder runtime yang dibutuhkan
RUN mkdir -p /var/run/sshd /etc/stunnel

# HACK: Generate sertifikat SSL internal (stunnel.pem) otomatis saat build
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Tunnel/CN=sshrail.up.railway.app" \
    -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem

# Konfigurasi SSH dasar
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
