#!/bin/bash -e

function section_header() {
    printf "\n"
    printf "╓─────[ $@ ]─────╖"
    printf "\n"
}

function die() {
  docker logs rig >&2
  exit 1
}

RIG_DIR=../..
TESTS_DIR=examples/tests
RIG_CONTAINER_NAME=rig-cypress-test-container

[[ -e node_modules ]] || npm install

cd "${RIG_DIR}"

docker build -t accenture/reactive-interaction-gateway .

cd "${TESTS_DIR}"

# section_header "Running functional test suite for Examples with no auth"
# docker rm -f "$RIG_CONTAINER_NAME" || true
# docker run -d --name "$RIG_CONTAINER_NAME" \
# -e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
# -e JWT_SECRET_KEY=secret \
# -e LOG_LEVEL=debug \
# -p 4000:4000 \
# accenture/reactive-interaction-gateway

# npm run cypress:run:noauth || die

# section_header "Running functional test suite for Examples with JWT auth"
# docker rm -f "$RIG_CONTAINER_NAME" || true
# docker run -d --name "$RIG_CONTAINER_NAME" \
# -e SUBSCRIPTION_CHECK=jwt_validation \
# -e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
# -e JWT_SECRET_KEY=secret \
# -e LOG_LEVEL=debug \
# -p 4000:4000 \
# accenture/reactive-interaction-gateway

# npm run cypress:run:jwt || die

section_header "Running functional test suite for Channels examples"
docker rm -f "$RIG_CONTAINER_NAME" || true

cd "../channels-example"
./run-compose.sh
cd ../tests

npm run cypress:run:channels || die
