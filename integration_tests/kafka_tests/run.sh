#!/bin/bash -e

function is_kafka_ready() {
    if [[ -z "$(docker-compose exec kafka bash -c '/opt/kafka/bin/kafka-topics.sh --zookeeper $KAFKA_ZOOKEEPER_CONNECT --topic rig --describe')" ]]; then
        # no output - Kafka is not ready yet
        return 1
    else
        # Kafka responds!
        return 0
    fi
}

cd "$(dirname "$0")"
RIG_DIR=../..

source .env

docker-compose up -d || exit 1

while ! is_kafka_ready; do
    echo "waiting for Kafka to start and create the topic.."
    sleep 1
done

check whether Kafka is now ready or the loop has been aborted:
is_kafka_ready || exit 1

export KAFKA_BROKERS="${HOST}:${KAFKA_PORT_PLAIN}"
export KAFKA_SSL_ENABLED=0
export KAFKA_SSL_KEYFILE_PASS=abcdefgh
export LOG_LEVEL=warn
export PROXY_KAFKA_REQUEST_TOPIC=rig_test
export KAFKA_SOURCE_TOPICS=rig_test

cd "${RIG_DIR}"
mix test --only kafka "$@"
