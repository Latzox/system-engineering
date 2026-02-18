#!/bin/bash
sudo certbot \
    certonly \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --manual \
    --agree-tos \
    --preferred-challenges dns \
    --register-unsafely-without-email \
    -d *.domain. # Wildcard - could be regular and one can also specify multiple -d options to include in the certificate

# Copy locally and chown to user
sudo cp /etc/letsencrypt/live/<domain>/cert.pem .
sudo cp /etc/letsencrypt/live/<domain>/chain.pem .
sudo cp /etc/letsencrypt/live/<domain>/fullchain.pem .
sudo cp /etc/letsencrypt/live/<domain>/privkey.pem .
sudo chown $(whoami) *.pem

# Export to pfx
openssl pkcs12 -inkey privkey.pem -in cert.pem -export -out certificate.pfx
