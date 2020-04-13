#!/bin/bash

set -o nounset \
    -o errexit

printf "Deleting previous (if any)..."
rm -rf secrets
mkdir secrets
mkdir -p tmp
echo " OK!"
# Generate CA key
printf "Creating CA..."
openssl req -new -x509 -keyout secrets/datahub-ca.key -out secrets/datahub-ca.crt -days 1 -subj '/CN=ca.datahub/OU=test/O=datahub/L=paris/C=fr' -passin pass:datahub -passout pass:datahub

echo " OK!"

for i in 'broker' 'producer' 'consumer' 'schema-registry'
do
	printf "Creating cert and keystore of $i..."
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i, OU=test, O=datahub, L=paris, C=fr" \
				 -keystore secrets/$i.keystore.jks \
				 -keyalg RSA \
				 -storepass datahub \
				 -keypass datahub

	# Create CSR, sign the key and import back into keystore
	keytool -keystore secrets/$i.keystore.jks -alias $i -certreq -file tmp/$i.csr -storepass datahub -keypass datahub

	openssl x509 -req -CA secrets/datahub-ca.crt -CAkey secrets/datahub-ca.key -in tmp/$i.csr -out tmp/$i-ca-signed.crt -days 365 -CAcreateserial -passin pass:datahub

	keytool -keystore secrets/$i.keystore.jks -alias CARoot -import -noprompt -file secrets/datahub-ca.crt -storepass datahub -keypass datahub

	keytool -keystore secrets/$i.keystore.jks -alias $i -import -file tmp/$i-ca-signed.crt -storepass datahub -keypass datahub

	# Create truststore and import the CA cert.
	keytool -keystore secrets/$i.truststore.jks -alias CARoot -import -noprompt -file secrets/datahub-ca.crt -storepass datahub -keypass datahub

	# Dump PEM and CRT files
	# https://akshaysin.github.io/kafka_ssl.html#.XpSPE8YpDUI
	# keytool -exportcert -alias $i -keystore secrets/$i.keystore.jks -rfc -file $i-certificate.pem
	# keytool -v -importkeystore -srckeystore secrets/$i.keystore.jks -srcalias $i -destkeystore $i-cert_and_key.p12 -deststoretype PKCS12
	# openssl pkcs12 -in $i-cert_and_key.p12 -nocerts -nodes > $i-key.pem
	# keytool -exportcert -alias CARoot -keystore secrets/$i.keystore.jks -rfc -file $i-CARoot.pem
  echo " OK!"
done

echo "datahub" > secrets/cert_creds
rm -rf tmp

echo "SUCCEEDED"
