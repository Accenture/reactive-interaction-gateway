#!/bin/bash -e

function section_header() {
  printf "\n"
  printf "╓─────[ $@ ]─────╖"
  printf "\n"
}

function is_kafka_ready() {
    if [[ -z "$(docker-compose exec kafka bash -c 'kafka-topics --list --zookeeper zookeeper:2181')" ]]; then
        # no output - Kafka is not ready yet
        return 1
    else
        # Kafka responds!
        section_header "Creating Kafka topics"
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig_test --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig-proxy-response --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rig_kafka_test_simple_topic --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        docker-compose exec kafka bash -c 'kafka-topics --create --topic rigAvro --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181'
        section_header "List of Kafka topics"
        docker-compose exec kafka bash -c 'kafka-topics --list --zookeeper zookeeper:2181'
        section_header "Creating Kafka registry schemas"
        curl -d '{"schema":"{\"name\":\"myrecord\",\"type\":\"record\",\"fields\":[{\"name\":\"foo\",\"type\":\"string\"}]}"}' -H "Content-Type: application/vnd.schemaregistry.v1+json" -X POST http://localhost:8081/subjects/rigAvro-value/versions
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

export KAFKA_BROKERS="${HOST}:${KAFKA_PORT_PLAIN}"
export KAFKA_SSL_ENABLED=0
export KAFKA_SSL_KEYFILE_PASS=abcdefgh
export LOG_LEVEL=warn
export PROXY_KAFKA_REQUEST_TOPIC=rig_test
export KAFKA_SOURCE_TOPICS=rig_test,rigAvro

cd "${RIG_DIR}"
section_header "RUNNING INTEGRATION TEST SUITE"
mix test --only kafka "$@"
