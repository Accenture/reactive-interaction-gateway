# Reactive Interaction Gateway Events Example

Example shows how events and subscriptions work inside Reactive Interaction Gateway (RIG) -- SSE/WS, how it interacts with Kafka and at the same time uses API Proxy.

Components involved:

- Kafka & Zookeeper
- RIG => Main component responsible for proxy and live communication
- External service => has REST API endpoint that can produce message to Kafka
- UI => Connects to RIG via WS/SSE, does REST API call to External service through RIG, consumes events from subscribed event types

## Quick start

If you want to just quickly start the application and see what's going on run `sh ./run-compose.sh`. Script builds docker image for each component, runs compose file and registers needed REST API. Once script is done you can visit `http://localhost:3000`.

## Manual start

This approach is a bit slower, but allows you to play with a code.

**Terminal 1:** Start Zookeeper and Kafka

```sh
docker-compose -f kafka.docker-compose.yml up -d
```

**Terminal 1:** Start RIG (from root directory)

Make sure that all required dependencies are fetched.

```sh
mix deps.get
```

For RIG we could use default configuration values, but where's fun in that. Let's change them so we can also see how to configure certain things to our needs.

```sh
# Description of environment variables

# KAFKA_SOURCE_TOPICS => Name of Kafka topic to which consumer will connect, by default rig
# JWT_SECRET_KEY => Secret key by which JWTs are signed, by default empty string
# API_PORT => Port at which we want to expose RIG's internal APIs, by default 4010
# INBOUND_PORT => Port at which we want to expose RIG's proxy and websocket/sse communication, by default 4000
# EXTRACTORS => sets constraints for given subscriptions - based on this RIG can use private event communication and decide where to route events

JWT_SECRET_KEY=mysecret \
KAFKA_SOURCE_TOPICS=example \
API_PORT=7010 \
INBOUND_PORT=7000 \
EXTRACTORS={"message":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}}} \
mix phx.server
```

RIG is now available on ports `7000` and `7010`.

**Terminal 2:** Start Service (from service directory)

```
# Go to service folder
npm i
npm start
```

Service is now available on port `8000`.

**Terminal 3:** Start Frontend (from frontend directory)

```
# Go to frontend folder
npm i
npm start # Should automatically open browser window with http://localhost:3000
```

Add new API to RIG. REST API calls from Frontend goes through RIG to external services, thus we need to tell RIG that such API exists (or define it in initial JSON file). At the same time by this we are testing proxy part of RIG.

```
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"kafka-service\",\"name\":\"kafka-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"kafka-producer-endpoint\",\"path\":\"/produce\",\"method\":\"POST\",\"not_secured\":true}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"localhost\",\"port\":8000}}" \
--silent \
"http://localhost:7010/v1/apis"
```

## Example scenarios to test

Here are a few examples you may try with this simple setup.

### Public events

1. Open two tabs in browser with `http://localhost:3000`
1. First tab: Select some transport type (doesn't matter which)
1. First tab: Fill in `User Name` with e.g. mike
1. First tab: Fill in `Subscribe to public event` with e.g. `my.public.event`
1. First tab: Press `Connect` => You should see spinner and message on the right side, that you are connected (as well as logs in RIG terminal)
1. Do the same in second browser tab (this time with **different** transport type and `User Name` -- john)
1. First tab: Fill in `Set event type` to `my.public.event`
1. First tab: Fill in `Event message` with e.g. `{"foo":"bar"}`
1. First tab: Press `Send event` => You should see messages on the right side in both browser tabs

### Private events

Repeat steps 1 to 6.

1. First tab: Fill in `Set event type` to `message`
1. First tab: Fill in `Event message` with e.g. `{"name":"mike","foo":"bar"}`
1. First tab: new message should be displayed, Second tab: **no new message**
1. Second tab: Fill in `Set event type` to `message`
1. Second tab: Fill in `Event message` with e.g. `{"name":"john","foo":"bar"}`
1. Second tab: new message should be displayed, First tab: **no new message**
