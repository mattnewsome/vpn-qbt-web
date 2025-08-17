#!/bin/bash

# Generate self-signed certificates for stunnel TLS encryption
# This provides encryption against host-level traffic sniffing

set -e

CERT_DIR="./certs"
CERT_FILE="$CERT_DIR/stunnel.pem"

echo "🔐 Generating TLS certificates for encrypted container communication..."

# Create certificate directory
mkdir -p "$CERT_DIR"

# Create OpenSSL config for localhost certificate
cat > "$CERT_DIR/openssl.conf" << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = Local
L = Local
O = VPN-Container
OU = Encryption
CN = localhost

[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate self-signed certificate with proper extensions for localhost
openssl req -new -x509 -days 3650 -nodes \
    -out "$CERT_FILE" \
    -keyout "$CERT_FILE" \
    -config "$CERT_DIR/openssl.conf" \
    -extensions v3_req \
    2>/dev/null

# Set appropriate permissions
chmod 600 "$CERT_FILE"

echo "✅ TLS certificate generated: $CERT_FILE"
echo "🔒 This certificate will encrypt traffic between containers"
echo "   (protecting against host-level network sniffing)"