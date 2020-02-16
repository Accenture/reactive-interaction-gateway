#!/bin/bash

function section_header() {
  printf "\n"
  printf "╓─────[ $@ ]─────╖"
  printf "\n\n"
}

function is_kafka_ready() {
    if [[ -z "$(docker-compose exec kafka bash -c 'kafka-topics --list --zookeeper zookeeper:2181')" ]]; then
        # no output - Kafka is not ready yet
        return 1
    else
        # Kafka responds!
        section_header "Creating Kafka topics"
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-test --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-request-log --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-proxy-response --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-kafka-test-simple-topic --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-avro --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        section_header "List of Kafka topics"
        docker-compose exec kafka bash -c 'kafka-topics --list --zookeeper zookeeper:2181'
        section_header "Creating Kafka registry schemas"
        curl -d '{"schema":"{\"name\":\"basicAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"foo\",\"type\":\"string\"}]}"}' -H "Content-Type: application/vnd.schemaregistry.v1+json" -X POST http://localhost:8081/subjects/rig-avro-value/versions
        curl -d '{"schema":"{\"name\":\"loggerAvro\",\"type\":\"record\",\"fields\":[{\"name\":\"request_path\",\"type\":\"string\"},{\"name\":\"remote_ip\",\"type\":\"string\"},{\"name\":\"endpoint\",\"type\":{\"name\":\"endpoint\",\"type\":\"record\",\"fields\":[{\"name\":\"path\",\"type\":\"string\"},{\"name\":\"method\",\"type\":\"string\"},{\"name\":\"id\",\"type\":\"string\"}]}}]}}]}"}' -H "Content-Type: application/vnd.schemaregistry.v1+json" -X POST http://localhost:8081/subjects/rig-request-logger-value/versions
        printf "\n"
        return 0
    fi
}

cd "$(dirname "$0")"
RIG_DIR=../..

source .env

docker-compose up -d || exit 1

while ! is_kafka_ready; do
    printf "waiting for Kafka to start and create the topics..\n"
    sleep 1
done

export PROXY_CONFIG_FILE="[]"
export KAFKA_BROKERS="${HOST}:${KAFKA_PORT_PLAIN}"
export KAFKA_SSL_ENABLED=0
export KAFKA_SSL_KEYFILE_PASS=abcdefgh
export LOG_LEVEL=warn
export PROXY_KAFKA_REQUEST_TOPIC=rig-test
export KAFKA_SOURCE_TOPICS=rig-test

cd "${RIG_DIR}"
section_header "Running integration test suite for Kafka"
mix test --only kafka "$@"

export KAFKA_SOURCE_TOPICS=rig-avro
export KAFKA_SERIALIZER=avro
export KAFKA_SCHEMA_REGISTRY_HOST=localhost:8081
export KAFKA_LOG_SCHEMA=rig-request-logger-value
export PROXY_KAFKA_REQUEST_TOPIC=rig-avro
export PROXY_KAFKA_REQUEST_AVRO=rig-avro-value

section_header "Running integration test suite for Kafka & Avro"
mix test --only avro "$@"
