#!/bin/bash -e

DOCKER_IMAGE=rig:smoke_test
COMPOSE="docker-compose -f smoke_tests.docker-compose.yml"

function section_header() {
  echo ""
  echo "╓─────[ $@ ]─────╖"
  echo ""
}

section_header "Building docker image: ${DOCKER_IMAGE}"
docker build -f ../smoke_tests.dockerfile -t "${DOCKER_IMAGE}" ..

section_header "Starting Kafka and backend-simulation services"
$COMPOSE up -d kafka rest-api

while [[ -z "$($COMPOSE exec kafka bash -c '/opt/kafka/bin/kafka-topics.sh --zookeeper $KAFKA_ZOOKEEPER_CONNECT --topic rig --describe')" ]]; do
  echo "waiting for Kafka to start and create the topic.."
  sleep 1
done

section_header "Running tests, plaintext Kafka connection"
$COMPOSE run --rm \
  -e KAFKA_ENABLED=1 \
  -e KAFKA_SSL_ENABLED=0 \
  -e KAFKA_HOSTS=kafka:9292 \
  rig

section_header "Running tests, encrypted Kafka connection"
$COMPOSE run --rm \
  -e KAFKA_ENABLED=1 \
  -e KAFKA_SSL_ENABLED=1 \
  -e KAFKA_HOSTS=kafka:9393 \
  -e KAFKA_SSL_KEYFILE_PASS=abcdefgh \
  rig

section_header "All tests passed."
