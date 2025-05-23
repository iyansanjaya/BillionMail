#!/bin/bash

# Inisialisasi database PostgreSQL
su-exec postgres initdb -D /var/lib/postgresql/data
su-exec postgres pg_ctl start -D /var/lib/postgresql/data

# Generate config
./install.sh --domain ${DOMAIN:-lumigia.top} --TZ ${TZ:-UTC}

# Start services menggunakan s6 overlay
exec s6-svscan /etc/services.d