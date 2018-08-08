#!/bin/bash -xe

# Based on https://raw.githubusercontent.com/klarna/brod/master/scripts/generate-certificates.sh (Apache-2.0)

VALIDITY_DAYS=36500
PASS=abcdefgh
CA_PASS="$PASS"
SERVER_PASS="$PASS"
CLIENT_PASS="$PASS"
DOMAIN=rig.accenture.com

CUR_DIR="$(pwd)"
CERTS_DIR="${CUR_DIR}/certs"
PROJ_DIR="${CUR_DIR}/.."
RIG_OUTBOUND_GATEWAY_PRIV_DIR="${PROJ_DIR}/apps/rig_outbound_gateway/priv"


rm -f "${CERTS_DIR}"/*.{jks,p12,crt,csr,key,srl}
mkdir -p "${CERTS_DIR}"
cd "${CERTS_DIR}"


## CA

# create the certificate (request and x509 self-sign it):
openssl req -new -subj "/C=AT/CN=ca.$DOMAIN" \
                 -x509 -keyout ca.key.pem -passout "pass:$CA_PASS" \
                 -out ca.crt.pem \
                 -days $VALIDITY_DAYS

# initialize a new truststore with the CA certificate:
keytool -importcert -file ca.crt.pem \
                    -alias CARoot \
                    -keystore truststore.jks \
                    -storepass "$CA_PASS" \
                    -noprompt


## Server

SERVER_CN="server.$DOMAIN"

# create certificate request:
openssl req -new -subj "/C=AT/CN=$SERVER_CN" \
                 -newkey rsa:2048 -sha256 -keyout server.key.pem -passout "pass:$SERVER_PASS" \
                 -out server.req.pem \
                 -days $VALIDITY_DAYS

# use the CA to sign the request:
openssl x509 -req -CA ca.crt.pem -CAkey ca.key.pem -passin "pass:$CA_PASS" \
                  -CAcreateserial \
                  -in server.req.pem -out server.crt.pem \
                  -days $VALIDITY_DAYS

# export to PKCS#12 for use with keytool:
openssl pkcs12 -export -name "$SERVER_CN" \
                       -in server.crt.pem -inkey server.key.pem -passin "pass:$SERVER_PASS" \
                       -CAfile ca.crt.pem \
                       -out server.p12 -passout "pass:$SERVER_PASS"

# initialize a new keystore with the exported certificate:
keytool -importkeystore -alias "$SERVER_CN" \
                        -srckeystore server.p12 -srcstoretype pkcs12 \
                        -srcstorepass "$SERVER_PASS" \
                        -destkeystore server.keystore.jks \
                        -deststorepass "$SERVER_PASS"


## Client

# Note: Erlang's ssl module doesn't like private keys created by req's -newkey parameter
# (using it causes this: {:failed_to_upgrade_to_ssl, {:keyfile, :function_clause}})
#openssl genrsa -des3 -passout "pass:$CLIENT_PASS" -out client.key.pem 2048
openssl genpkey -algorithm RSA \
                -out client.key.pem \
                -des3 \
                -pass "pass:$CLIENT_PASS" \
                -pkeyopt rsa_keygen_bits:2048
openssl req -new -subj "/C=AT/CN=client.$DOMAIN" \
                 -key client.key.pem -passin "pass:$CLIENT_PASS" -passout "pass:$CLIENT_PASS" \
                 -out client.req.pem \
                 -days $VALIDITY_DAYS

openssl x509 -req -CA ca.crt.pem -CAkey ca.key.pem -passin "pass:$CA_PASS" \
                  -CAserial ca.srl \
                  -in client.req.pem -out client.crt.pem \
                  -days $VALIDITY_DAYS


# Copy CA and client certificates to :rig_outbound_gateway's priv dir

cp ca.crt.pem "${RIG_OUTBOUND_GATEWAY_PRIV_DIR}/ca.crt.pem"
cp client.crt.pem "${RIG_OUTBOUND_GATEWAY_PRIV_DIR}/client.crt.pem"
cp client.key.pem "${RIG_OUTBOUND_GATEWAY_PRIV_DIR}/client.key.pem"
