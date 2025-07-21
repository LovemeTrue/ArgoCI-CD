#!/bin/bash

set -e

# === НАСТРОЙКИ ===
ORG="Elewise"
COUNTRY="US"
STATE="California"
CITY="San Francisco"
ROOT_CA_NAME="elewise-root-ca"
INT_CA_NAME="elewise-intermediate-ca"
CERT_DIR="./certs"
MINIO_CERT_DIR="/etc/minio/certs"
MINIO_CA_DIR="${MINIO_CERT_DIR}/CAs"
DOMAIN="*.elewise.local"
CN="master.elewise.local"

# === ПОДГОТОВКА ===
mkdir -p "${CERT_DIR}" "${MINIO_CA_DIR}"

echo "[1] Генерация Root CA (если нужно)..."
if [[ ! -f "${CERT_DIR}/${ROOT_CA_NAME}.crt" ]]; then
  openssl genrsa -out "${CERT_DIR}/${ROOT_CA_NAME}.key" 4096
  openssl req -x509 -new -nodes -key "${CERT_DIR}/${ROOT_CA_NAME}.key" \
    -sha256 -days 3650 \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/CN=Elewise Root CA" \
    -out "${CERT_DIR}/${ROOT_CA_NAME}.crt"
else
  echo "[INFO] Root CA уже существует, пропускаем..."
fi

echo "[2] Генерация Intermediate CA с CA:TRUE..."

# Создаём расширения для intermediate CA
cat > "${CERT_DIR}/intermediate_ext.cnf" <<EOF
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF

# Удалим старую цепочку и .srl
rm -f "${CERT_DIR}/${INT_CA_NAME}.crt" "${CERT_DIR}/${INT_CA_NAME}.csr" "${CERT_DIR}/${INT_CA_NAME}.key" "${CERT_DIR}/${ROOT_CA_NAME}.srl"

# Генерация
openssl genrsa -out "${CERT_DIR}/${INT_CA_NAME}.key" 4096
openssl req -new -key "${CERT_DIR}/${INT_CA_NAME}.key" \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/CN=Elewise Intermediate CA" \
  -out "${CERT_DIR}/${INT_CA_NAME}.csr"

openssl x509 -req -in "${CERT_DIR}/${INT_CA_NAME}.csr" \
  -CA "${CERT_DIR}/${ROOT_CA_NAME}.crt" \
  -CAkey "${CERT_DIR}/${ROOT_CA_NAME}.key" \
  -CAcreateserial -out "${CERT_DIR}/${INT_CA_NAME}.crt" \
  -days 1825 -sha256 \
  -extfile "${CERT_DIR}/intermediate_ext.cnf"

echo "[3] Генерация server ключа и CSR..."

openssl genrsa -out "${CERT_DIR}/public.key" 2048

cat > "${CERT_DIR}/san.cnf" <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[dn]
C=${COUNTRY}
ST=${STATE}
L=${CITY}
O=${ORG}
CN=${CN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CN}
DNS.2 = ${DOMAIN}
EOF

openssl req -new -key "${CERT_DIR}/public.key" \
  -out "${CERT_DIR}/public.csr" -config "${CERT_DIR}/san.cnf"

echo "[4] Подпись server сертификата Intermediate CA..."

openssl x509 -req -in "${CERT_DIR}/public.csr" \
  -CA "${CERT_DIR}/${INT_CA_NAME}.crt" \
  -CAkey "${CERT_DIR}/${INT_CA_NAME}.key" \
  -CAcreateserial -out "${CERT_DIR}/public.crt" -days 825 -sha256 \
  -extfile "${CERT_DIR}/san.cnf" -extensions req_ext

echo "[5] Создание цепочки..."
cat "${CERT_DIR}/${INT_CA_NAME}.crt" "${CERT_DIR}/${ROOT_CA_NAME}.crt" > "${CERT_DIR}/chain.crt"

echo "[6] Проверка цепочки..."
openssl verify -CAfile "${CERT_DIR}/chain.crt" "${CERT_DIR}/public.crt"

echo "[7] Установка сертификатов в MinIO..."

cp "${CERT_DIR}/public.crt" "${MINIO_CERT_DIR}/public.crt"
cp "${CERT_DIR}/public.key" "${MINIO_CERT_DIR}/private.key"
cp "${CERT_DIR}/chain.crt" "${MINIO_CA_DIR}/elewise-chain.crt"

chmod -R 777 "${MINIO_CERT_DIR}/private.key"
chmod -R 777 "${MINIO_CERT_DIR}/public.crt"
chmod -R 777 "${MINIO_CA_DIR}/elewise-chain.crt"

echo "[8] Перезапуск MinIO..."
if systemctl is-active --quiet minio; then
  systemctl restart minio
  echo "[OK] MinIO перезапущен."
else
  echo "[WARN] MinIO не работает как systemd-сервис. Перезапусти вручную, если нужно."
fi

echo "[DONE] Готово! MinIO теперь работает с валидными самоподписанными сертификатами."