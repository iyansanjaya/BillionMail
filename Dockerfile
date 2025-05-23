FROM alpine:3.18

# Install dependensi utama
RUN apk add --no-cache bash git openssl postgresql-client

# Clone repositori
WORKDIR /opt
RUN git clone https://github.com/aaPanel/BillionMail

# Setup direktori
WORKDIR /opt/BillionMail
RUN mkdir -p ssl ssl-self-signed

# Generate self-signed SSL
RUN openssl genrsa -out ssl-self-signed/key.pem 2048 && \
    openssl req -x509 -new -nodes -key ssl-self-signed/key.pem -sha256 -days 3650 \
    -subj "/C=US/ST=State/L=City/O=lumigia.top/OU=lumigia.top/CN=*.lumigia.top" \
    -out ssl-self-signed/cert.pem

# Port yang diperlukan
EXPOSE 80 443 25 465 587 143 993 110 995

# Entrypoint
COPY modified-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]