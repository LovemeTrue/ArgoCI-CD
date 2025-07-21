#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Error: No domain name argument provided"
  echo "Usage: Provide a domain name as an argument"
  exit 1
fi

DOMAIN=$1

# Create root CA & Private key

openssl req -x509 \
            -sha256 -days 356 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=${DOMAIN}/C=US/L=San Fransisco" \
            -keyout rootCA.key -out rootCA.crt 

# Generate Private key 

openssl genrsa -out ${DOMAIN}.key 2048

# Create csf conf

cat > csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = San Fransisco
O = Elma
OU = Elma Dev
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
IP.1 = 92.217.196.189
IP.2 = 92.217.196.183
IP.3 = 92.217.196.156

EOF

# create CSR request using private key

openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr -config csr.conf

# Create a external config file for the certificate

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.sale.elewise.com
DNS.3 = master.sale.elewise.com

EOF

# Create SSl with self signed CA

openssl x509 -req \
    -in ${DOMAIN}.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out ${DOMAIN}.crt \
    -days 365 \
    -sha256 -extfile cert.conf

# Convert rootCA.crt to rootCA.pem file

openssl x509 -in rootCA.crt -out rootCA.pem -outform PEM

## Decrypt rootCA.key file 

openssl rsa -in rootCA.key -out rootCA_unencrypted.key -aes256 -passin pass:passkey

# Clean up + rw rights

rm ${DOMAIN}.csr
rm csr.conf
rm cert.conf

chmod -R 777 ${DOMAIN}.key
chmod -R 777 rootCA.key
chmod -R 777 rootCA_unencrypted.key

# cp to /etc/ssl
cp ${DOMAIN}.crt /etc/ssl/certs/
cp ${DOMAIN}.key /etc/ssl/private/
cp rootCA.crt  /etc/ssl/certs/

echo "Certificate created for ${DOMAIN}"

echo "Certificate created for ${DOMAIN}"


kubectl create secret tls elma365-onpremise-tls --cert=/home/vrstel/ssl/${DOMAIN}.crt --key=/home/vrstel/ssl/${DOMAIN}.key -n elma365-dbs
kubectl create secret tls elma365-onpremise-tls --cert=/home/vrstel/ssl/${DOMAIN}.crt --key=/home/vrstel/ssl/${DOMAIN}.key -n elma365
kubectl create configmap elma365-onpremise-ca --from-file=elma365-onpremise-ca.pem=/home/vrstel/ssl/rootCA.pem -n elma365

echo "Secret elma365-onpremise-tls and configmap elma365-onpremise-ca has been created for elma365, elma365-dbs. Please upgrade your helm charts"
