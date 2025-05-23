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
    su-exec \
    shadow \
    procps \
    coreutils

# Setup environment
WORKDIR /opt/BillionMail
COPY . .

# Fix permissions dan inisialisasi
RUN chmod +x install.sh entrypoint.sh && \
    mkdir -p \
    /run/postgresql \
    /var/lib/postgresql/data \
    /var/log/{postgresql,redis,rspamd,dovecot,postfix} && \
    chown -R postgres:postgres /var/lib/postgresql /run/postgresql && \
    chmod 2775 /var/lib/postgresql /run/postgresql

# Generate SSL
RUN openssl genrsa -out ssl-self-signed/key.pem 2048 && \
    openssl req -x509 -new -nodes -key ssl-self-signed/key.pem \
    -subj "/C=US/ST=State/L=City/O=lumigia.top/OU=lumigia.top/CN=*.lumigia.top" \
    -out ssl-self-signed/cert.pem

EXPOSE 25 80 143 443 465 587 993 995

ENTRYPOINT ["./entrypoint.sh"]