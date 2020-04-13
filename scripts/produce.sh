#!/usr/bin/env bash

echo "my computer is very large" | \
kafkacat -b broker:9092 \
-X security.protocol=SSL \
-X ssl.key.location=key.pem \
-X ssl.certificate.location=certificate.pem \
-X ssl.ca.location=CARoot.pem \
-X ssl.key.password=datahub \
-X ssl.check.hostname=false\
-P \
-t quotes
