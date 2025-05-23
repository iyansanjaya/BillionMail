#!/bin/bash

# Generate config
./install.sh --domain ${DOMAIN:-lumigia.top} --TZ ${TZ:-UTC}

# Start services secara manual
postgres &
redis-server &
rspamd &
dovecot &
postfix start

# Pertahankan container tetap running
tail -f /dev/null