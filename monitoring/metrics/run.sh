#!/bin/bash

cd "$(dirname "$0")"
RIG_DIR=../..
METRICS_DIR=monitoring/metrics

cd "${RIG_DIR}"

docker build -t accenture/reactive-interaction-gateway -f aws.dockerfile .

cd "${METRICS_DIR}"

docker-compose down && docker-compose up -d

# wait for a bit till RIG, Kafka and others are ready
sleep 10

# create Kinesis streams
docker-compose exec localstack bash -c 'awslocal kinesis create-stream --stream-name RIG-outbound --shard-count 1 --region eu-west-1 && awslocal kinesis create-stream --stream-name RIG-firehose --shard-count 1 --region eu-west-1'

count=0
while true; do
  # blacklist token and send invalid event every 30 seconds
  if ! ((count % 30)); then
    printf "\nBlacklisting a session ...\n"
    curl -X POST "http://localhost:4010/v2/session-blacklist" -H "accept: application/json" -H "content-type: application/json" -d "{ \"validityInSeconds\": 60, \"sessionId\": \"SomeSessionID123\"}"
    printf "\nProducing an invalid Kafka event ...\n"
    docker-compose exec kafkacat bash -c 'echo "hello" | kafkacat -b kafka:9092 -t test-monitoring'
  fi

  # send one kinesis event every 5 seconds
  if ! ((count % 5)); then
    printf "\nProducing a standard Kinesis event ...\n"
    curl -d '{"event":{"id":"069711bf-3946-4661-984f-c667657b8d86","type":"greeting.simple","specversion":"0.2","source":"\/cli","data":{"example":"kinesis test"}}}' -H "Content-Type: application/json" -X POST http://localhost:4000/api/kinesis
  fi

  # send one standard event every second
  printf "\nProducing a standard Kafka event ...\n"
  curl -d "{\"specversion\":\"0.2\",\"type\":\"greeting.simple\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\",\"data\":{\"example\":\"kafka test\"}}" -H "Content-Type: application/json" -X POST http://localhost:4000/api/kafka
	# curl -d '{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"greeting.simple","specversion":"0.2","source":"\/cli","data":{"example":"kafka test"}}' -H "Content-Type: application/json" -X POST http://localhost:4000/api/kafka
  (( count++ ))
  sleep 1
done