#!/bin/sh


# Create CA
# openssl req -nodes \
#           -x509 \
#           -days 3650 \
#           -newkey rsa:4096 \
#           -keyout secrets/ca.key \
#           -out secrets/ca.cert \
#           -sha256 \
#           -batch \
#           -subj "/CN=MZ RSA CA"

# for i in 'broker' 'producer' 'materialized' 'schema-registry'
# do

# 	# Create keystores
# 	keytool -genkey \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-alias $i \
# 		-dname "CN=$i client" \
# 		-keystore secrets/$i.keystore.jks \
# 		-keyalg RSA

# 	# Create CSR, sign the key and import back into keystore
# 	keytool -keystore secrets/$i.keystore.jks \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-alias $i \
# 		-certreq \
# 		-file tmp/$i.csr

# 	openssl x509 -req \
# 			-in tmp/$i.csr \
# 			-out secrets/$i.cert \
# 			-CA secrets/ca.cert \
# 			-CAkey secrets/ca.key \
# 			-sha256 \
# 			-days 2000 \
# 			-set_serial 789 \
# 			-extensions $i -extfile openssl.cnf
	
# 	keytool -keystore secrets/$i.keystore.jks \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-alias CARoot \
# 		-import \
# 		-file secrets/ca.cert

# 	keytool -keystore secrets/$i.keystore.jks \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-alias $i \
# 		-import \
# 		-file secrets/$i.cert

# 	keytool -keystore secrets/$i.truststore.jks \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-alias CARoot \
# 		-import \
# 		-file secrets/ca.cert

# 	echo "$i done"

# done

# openssl asn1parse -in secrets/ca.cert -out secrets/ca.der > /dev/null

# # Export key for materialized
# keytool -v -importkeystore  \
# 		-noprompt \
# 		-storepass mzmzmz \
# 		-keypass mzmzmz \
# 		-srckeystore secrets/materialized.keystore.jks \
# 		-srcalias materialized \
# 		-destkeystore secrets/materialized-cert_and_key.p12 \
# 		-deststoretype PKCS12

# openssl pkcs12 -in secrets/materialized-cert_and_key.p12 -nocerts -nodes > secrets/mz-key.pem


set -xe

printf "Deleting previous (if any)..."
rm -rf secrets
mkdir secrets
mkdir -p tmp
echo " OK!"
# Generate CA key
printf "Creating CA..."

openssl req \
	-x509 \
	-days 3650 \
	-newkey rsa:4096 \
	-keyout secrets/datahub-ca.key \
	-out secrets/datahub-ca.crt \
	-sha256 \
	-batch \
	-subj "/CN=MZ RSA CA" \
	-passin pass:datahub \
	-passout pass:datahub

echo " OK!"

for i in 'broker' 'producer' 'materialized' 'schema-registry'
do
	printf "Creating cert and keystore of $i..."
	# Create keystores
	keytool -genkey \
		-noprompt \
		-alias $i \
		-dname "CN=$i, OU=test, O=datahub, L=paris, C=fr" \
		-keystore secrets/$i.keystore.jks \
		-keyalg RSA \
		-sigalg SHA256withRSA \
		-keysize 2048 \
		-storepass datahub \
		-keypass datahub

	# Create CSR, sign the key and import back into keystore
	keytool -keystore secrets/$i.keystore.jks \
		-alias $i \
		-certreq \
		-file tmp/$i.csr \
		-storepass datahub -keypass datahub \
		-ext SAN=dns:$i

	openssl x509 -req \
		-CA secrets/datahub-ca.crt \
		-CAkey secrets/datahub-ca.key \
		-in tmp/$i.csr \
		-out tmp/$i-ca-signed.crt \
		-sha256 \
		-days 365 \
		-CAcreateserial \
		-passin pass:datahub \
		-extensions $i -extfile openssl.cnf

	keytool -keystore secrets/$i.keystore.jks -alias CARoot -import -noprompt -file secrets/datahub-ca.crt -storepass datahub -keypass datahub

	keytool -keystore secrets/$i.keystore.jks -alias $i -import -file tmp/$i-ca-signed.crt -storepass datahub -keypass datahub

	# Create truststore and import the CA cert.
	keytool -keystore secrets/$i.truststore.jks -alias CARoot -import -noprompt -file secrets/datahub-ca.crt -storepass datahub -keypass datahub

  echo " OK!"
done

# Dump PEM and CRT files
# https://akshaysin.github.io/kafka_ssl.html#.XpSPE8YpDUI
keytool -exportcert -alias materialized -keystore secrets/materialized.keystore.jks -noprompt -storepass datahub -keypass datahub -rfc -file secrets/certificate.pem -ext san=dns:materialized
keytool -v -importkeystore -srckeystore secrets/materialized.keystore.jks -srcalias materialized -destkeystore secrets/materialized-cert_and_key.p12 -deststoretype PKCS12 -noprompt -storepass datahub -keypass datahub
openssl pkcs12 -in secrets/materialized-cert_and_key.p12 -nocerts -nodes > secrets/key.pem
keytool -exportcert -alias CARoot -keystore secrets/materialized.keystore.jks -noprompt -storepass datahub -keypass datahub -rfc -file secrets/CARoot.pem

echo "datahub" > secrets/cert_creds
rm -rf tmp

echo "SUCCEEDED"
