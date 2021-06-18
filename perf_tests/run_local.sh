#!/bin/bash

function section_header() {
  printf "\n"
  printf "╓─────[ $@ ]─────╖"
  printf "\n\n"
}

RIG_DIR=../
TESTS_DIR=perf_tests
RIG_CONTAINER_NAME=rig-perf-test-container

cd "${RIG_DIR}"
section_header "Building RIG"
docker build -t accenture/reactive-interaction-gateway .

cd "${TESTS_DIR}/src/run1"
section_header "Building Client"
docker build -t client -f client.Dockerfile .
cd "../../"

# cd "${RIG_DIR}"
# section_header "Building Loader"
# docker build -t accenture/reactive-interaction-gateway .



section_header "Starting Kafka & Zookeeper"
docker-compose up -d || exit 1



# section_header "Starting RIG"
# docker rm -f "$RIG_CONTAINER_NAME" || true
# docker run -d --name "$RIG_CONTAINER_NAME" \
# -e KAFKA_BROKERS=localhost:9094 \
# -e LOG_LEVEL=error \
# -p 4000:4000 \
# accenture/reactive-interaction-gateway