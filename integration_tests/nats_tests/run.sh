#!/usr/bin/env sh

cd "$(dirname "$0")"
RIG_DIR=../..

NATS_VERSION=2
CONTAINER_PREFIX=rig-i9n-nats-test
NATS_CONTAINER="${CONTAINER_PREFIX}-nats"

function cleanup() {
    printf "\nCleaning up..\n"
    echo "killing the http client.."
    kill %1
    echo "stopping RIG.."
    ${RIG_DIR}/_build/dev/rel/rig/bin/rig stop
    echo "stopping (and removing) the NATS server.."
    docker stop $NATS_CONTAINER
    printf "\nCleanup complete.\n"
}
trap cleanup EXIT

# Start NATS server:
docker stop $NATS_CONTAINER 2>/dev/null
docker run --rm -d --name $NATS_CONTAINER -p 4222:4222 nats:$NATS_VERSION
sleep 1 # should be up within 1 sec

# Build and run RIG:
(cd $RIG_DIR && mix distillery.release)
export NATS_SERVERS=localhost:4222
export NATS_SOURCE_TOPICS=rig-test
${RIG_DIR}/_build/dev/rel/rig/bin/rig stop 2>/dev/null
${RIG_DIR}/_build/dev/rel/rig/bin/rig start

# Wait for RIG to start its webserver:
printf "waiting for RIG to start up"
secs_left=30
while ! http --check-status --print '' :4000/_rig/health 2>/dev/null; do
    if [[ $secs_left > 0 ]]; then
        printf "." ; sleep 1 ; secs_left=$((secs_left-1))
    else
        printf " - timed out."
        exit 1
    fi
done
printf "\n"

# Connect client to RIG:
http --stream :4000/_rig/v1/connection/sse\?subscriptions='[{"eventType":"test"}]' >received &

# Make sure the client is connected and subscribed to the topic:
printf "waiting for the client to be connected and subscribed"
secs_left=30
while ! grep -q rig.subscriptions_set received; do
    if [[ $secs_left > 0 ]]; then
        printf "." ; sleep 1 ; secs_left=$((secs_left-1))
    else
        printf " - timed out."
        exit 1
    fi
done
printf "\n"

# Publish an event:
mix deps.get && mix run publish_event_to_nats_topic.exs

# Wait for the client to receive the event:
printf "waiting for events to show up in the client's output"
secs_left=30
while ! grep -q "the event was consumed from a NATS topic and published to the client" received; do
    if [[ $secs_left > 0 ]]; then
        printf "." ; sleep 1 ; secs_left=$((secs_left-1))
    else
        printf " - timed out."
        printf "\nTEST FAILED!\n"
        exit 1
    fi
done
printf "\n"

printf "\nTEST SUCCEEDED!\n"
