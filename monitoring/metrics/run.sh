#!/bin/bash

cd "$(dirname "$0")"
RIG_DIR=../..
METRICS_DIR=monitoring/metrics

cd "${RIG_DIR}"

docker build -t accenture/reactive-interaction-gateway .

cd "${METRICS_DIR}"

docker-compose down && docker-compose up -d

count=0
while true; do
  # blacklist token and send invalid event every 30 seconds
  if ! ((count % 30)); then
    curl -X POST "http://localhost:4010/v2/session-blacklist" -H "accept: application/json" -H "content-type: application/json" -d "{ \"validityInSeconds\": 60, \"sessionId\": \"SomeSessionID123\"}"
    docker-compose exec kafkacat bash -c 'echo "hello" | kafkacat -b kafka:9092 -t test-monitoring'
  fi
	curl -d '{"event":{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"greeting.simple","specversion":"0.2","source":"\/cli","data":{"example":"test"}},"partition":"test_key"}' -H "Content-Type: application/json" -X POST http://localhost:4000/api/kafka
  (( count++ ))
  sleep 1
done