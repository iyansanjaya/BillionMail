#!/bin/bash

# Inisialisasi PostgreSQL
su-exec postgres initdb -D /var/lib/postgresql/data
su-exec postgres pg_ctl start -D /var/lib/postgresql/data

# Start services secara manual
su-exec redis redis-server --daemonize yes
rspamd -u rspamd -g rspamd -f &
dovecot -F &
postfix start

# Jalankan install script yang sudah dimodifikasi
./install.sh --domain ${DOMAIN:-lumigia.top} --TZ ${TZ:-UTC}

# Pertahankan container tetap running
tail -f /dev/null

for service in postgresql redis rspamd dovecot postfix; do
    rc-service $service start
done