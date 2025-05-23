FROM alpine:3.18

# Install semua dependency yang diperlukan
RUN apk add --no-cache \
    bash \
    git \
    openssl \
    postgresql \
    postgresql-client \
    redis \
    rspamd \
    dovecot \
    postfix \
    tzdata \
    su-exec

# Setup direktori dan permission
WORKDIR /opt/BillionMail
COPY . .
RUN chmod +x install.sh entrypoint.sh && \
    mkdir -p ssl ssl-self-signed && \
    chown -R nobody:nobody /opt/BillionMail

# Setup init services
RUN mkdir -p /etc/services.d/postgres /etc/services.d/redis && \
    echo -e '#!/command/execlineb -P\ns6-setuidgid postgres\npostgres -D /var/lib/postgresql/data' > /etc/services.d/postgres/run && \
    echo -e '#!/command/execlineb -P\ns6-setuidgid redis\nredis-server' > /etc/services.d/redis/run

# Generate SSL
RUN openssl genrsa -out ssl-self-signed/key.pem 2048 && \
    openssl req -x509 -new -nodes -key ssl-self-signed/key.pem \
    -subj "/C=US/ST=State/L=City/O=lumigia.top/OU=lumigia.top/CN=*.lumigia.top" \
    -out ssl-self-signed/cert.pem

EXPOSE 25 80 143 443 465 587 993 995

ENTRYPOINT ["./entrypoint.sh"]