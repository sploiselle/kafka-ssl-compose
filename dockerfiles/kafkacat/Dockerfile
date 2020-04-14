FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y kafkacat curl
RUN mkdir /secrets
WORKDIR /secrets
COPY ../../secrets /secrets
ENTRYPOINT ["/bin/bash"]