#!/bin/bash

# Shutdown running app
docker-compose -f app.docker-compose.yml down

# Build frontend docker image
cd ./frontend
npm i
npm run build
docker build -t channels-ui .

# Build service docker image
cd ../service
docker build -t channels-external-service .

# Run app
cd ../
docker-compose -f app.docker-compose.yml up -d

# Register REST API endpoint
sleep 20
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"kafka-service\",\"name\":\"kafka-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"kafka-producer-endpoint\",\"path\":\"/produce\",\"method\":\"POST\",\"not_secured\":true}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"channels-external-service\",\"port\":8000}}" \
--silent \
"http://localhost:7010/v1/apis"

printf "\n===> Application is ready <===\n"
