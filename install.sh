#!/bin/ash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Konfigurasi utama
CONTAINER_PROJECT_NAME=billionmail
DBNAME=billionmail
DBUSER=billionmail
BILLIONMAIL_HOSTNAME=${BILLIONMAIL_HOSTNAME:-example.com}
BILLIONMAIL_TIME_ZONE=${TZ:-UTC}

# Generate password acak
generate_password() {
    LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 32
}

# Setup direktori penting
mkdir -p \
    /run/postgresql \
    /var/lib/postgresql/data \
    /var/lib/rspamd/dkim \
    /ssl-self-signed \
    /ssl

chown postgres:postgres /run/postgresql /var/lib/postgresql/data

# Install dependensi Alpine
apk add --no-cache \
    bash \
    curl \
    docker \
    docker-compose \
    postgresql \
    postgresql-client \
    redis \
    rspamd \
    dovecot \
    dovecot-pgsql \
    postfix \
    openssl \
    shadow

# Setup PostgreSQL
su-exec postgres initdb -D /var/lib/postgresql/data --auth=trust
echo "host all all all trust" >> /var/lib/postgresql/data/pg_hba.conf
su-exec postgres pg_ctl start -D /var/lib/postgresql/data

# Setup Docker
rc-update add docker boot
service docker start

# Generate SSL
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /ssl-self-signed/key.pem \
    -out /ssl-self-signed/cert.pem \
    -subj "/CN=${BILLIONMAIL_HOSTNAME}"

cp /ssl-self-signed/* /ssl/

# File konfigurasi environment
cat << EOF > .env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$(generate_password)
SafePath=$(generate_password)
BILLIONMAIL_HOSTNAME=${BILLIONMAIL_HOSTNAME}
DBNAME=${DBNAME}
DBUSER=${DBUSER}
DBPASS=$(generate_password)
REDISPASS=$(generate_password)

SMTP_PORT=25
SMTPS_PORT=465
SUBMISSION_PORT=587
IMAP_PORT=143
IMAPS_PORT=993
POP_PORT=110
POPS_PORT=995
HTTP_PORT=80
HTTPS_PORT=443

TZ=${BILLIONMAIL_TIME_ZONE}
IPV4_NETWORK=172.66.1
FAIL2BAN_INIT=y
EOF

# Inisialisasi database
psql -U postgres << EOSQL
    CREATE USER ${DBUSER} WITH PASSWORD '$(grep DBPASS .env | cut -d= -f2)';
    CREATE DATABASE ${DBNAME} OWNER ${DBUSER};
EOSQL

# Start services
rc-service redis start
rc-service rspamd start
rc-service dovecot start
rc-service postfix start

# Jalankan Docker compose
docker-compose up -d

# Tetap pertahankan container running
tail -f /dev/null