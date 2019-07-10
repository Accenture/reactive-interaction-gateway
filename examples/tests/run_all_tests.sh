#!/bin/bash

function section_header() {
  printf "\n"
  printf "╓─────[ $@ ]─────╖"
  printf "\n"
}

RIG_DIR=../..
TESTS_DIR=examples/tests
cd "${RIG_DIR}"

docker build -t rig .

cd "${TESTS_DIR}"

section_header "Running functional test suite for Examples with no auth"
docker rm -f rig || true
docker run -d --name rig \
-e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
-e JWT_SECRET_KEY=secret \
-p 4000:4000 \
rig

npm run cypress:run:noauth

section_header "Running functional test suite for Examples with JWT auth"
docker rm -f rig || true
docker run -d --name rig \
-e SUBSCRIPTION_CHECK=jwt_validation \
-e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
-e JWT_SECRET_KEY=secret \
-p 4000:4000 \
rig

npm run cypress:run:jwt

section_header "Running functional test suite for Channels examples"
docker rm -f rig || true

cd "../channels-example"
./run-compose.sh
cd ../tests

npm run cypress:run:channels
