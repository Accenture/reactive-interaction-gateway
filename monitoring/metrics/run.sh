#!/bin/bash

cd "$(dirname "$0")"
RIG_DIR=../..
METRICS_DIR=monitoring/metrics
RIG_CONTAINER_NAME=rig-metrics-container

cd "${RIG_DIR}"

docker build -t accenture/reactive-interaction-gateway .

cd "${METRICS_DIR}"

docker-compose down && docker-compose up -d

while true; do
	curl -d '{"event":{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"greeting.simple","specversion":"0.2","source":"\/cli","data":{"example":"test"}},"partition":"test_key"}' -H "Content-Type: application/json" -X POST http://localhost:4000/api/kafka
  sleep 1
done
