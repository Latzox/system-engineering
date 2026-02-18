#!/bin/bash

# Author: Marco Platzer
# Date: 28-03-2025
# Description: This script creates a certificate signing request for an certificate authority

# Usage: ./create-csr.sh
# Make sure to replace `yourdomain.com` with your actual domain name.

# Define file paths
PRIVATE_KEY_FILE="domain.key"
CSR_FILE="domain.csr"
DOMAIN="*.domain.com"

# Prompt for the passphrase for the private key
echo "Enter passphrase for the private key (leave empty for no passphrase):"
read -s PASSPHRASE

# Generate private key
if [ -z "$PASSPHRASE" ]; then
    openssl genpkey -algorithm RSA -out "$PRIVATE_KEY_FILE"
else
    openssl genpkey -algorithm RSA -out "$PRIVATE_KEY_FILE" -aes256 -pass "pass:$PASSPHRASE"
fi

# Create CSR
openssl req -new -key "$PRIVATE_KEY_FILE" -out "$CSR_FILE" -subj "/C=CH/ST=ZH/L=Zurich/O=SWISSPERFORM/OU=IT/CN=$DOMAIN/emailAddress=example@domain.com"

# Verify the CSR
openssl req -text -noout -verify -in "$CSR_FILE"

# Print success message
echo "CSR and private key have been generated successfully."
echo "CSR: $CSR_FILE"
echo "Private Key: $PRIVATE_KEY_FILE"
echo "Submit the CSR to your SSL provider to obtain your certificate."