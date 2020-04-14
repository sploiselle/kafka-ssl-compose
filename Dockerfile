FROM ubuntu:18.04
FROM rust:1.38
RUN apt-get update
RUN apt-get install -y kafkacat curl git
RUN git clone https://github.com/ctz/rustls.git
WORKDIR /rustls
RUN cargo build --example tlsclient
COPY /secrets /secrets
ENTRYPOINT ["/bin/bash"]