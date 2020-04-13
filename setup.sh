#!/bin/sh

# Copyright Materialize, Inc. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

psql -h materialized -p 6875 -d materialize << EOF
CREATE MATERIALIZED SOURCE quotes
FROM KAFKA BROKER 'localhost:9092'
    TOPIC 'quotes' 
    WITH (
        security_protocol='SSL',
        ssl_key_location='/Users/sean/docker/kafka-ssl-compose/key.pem',
        ssl_certificate_location='/Users/sean/docker/kafka-ssl-compose/certificate.pem',
        ssl_ca_location='/Users/sean/docker/kafka-ssl-compose/CARoot.pem',
        ssl_key_password='datahub'
    )
    FORMAT AVRO 
        USING CONFLUENT SCHEMA REGISTRY 'localhost:8181';
EOF
