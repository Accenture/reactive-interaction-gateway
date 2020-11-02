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

# KAFKA_BROKERS => host for Kafka broker, setting this will automatically turn on Kafka handlers in RIG
# KAFKA_SOURCE_TOPICS => Name of Kafka topic to which consumer will connect, by default rig
# JWT_SECRET_KEY => Secret key by which JWTs are signed, by default empty string
# API_HTTP_PORT => Port at which we want to expose RIG's internal APIs, by default 4010
# INBOUND_PORT => Port at which we want to expose RIG's proxy and websocket/sse communication, by default 4000
# EXTRACTORS => sets constraints for given subscriptions - based on this RIG can use private event communication and decide where to route events

JWT_SECRET_KEY=mysecret \
KAFKA_BROKERS=localhost:9092 \
KAFKA_SOURCE_TOPICS=example \
API_HTTP_PORT=7010 \
INBOUND_PORT=7000 \
EXTRACTORS='{"message":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}}}' \
mix phx.server
```

RIG is now available on ports `7000` and `7010`.

**Terminal 2:** Start Service (from service directory)

```sh
# Go to service folder
npm i
npm start
```

Service is now available on port `8000`.

**Terminal 3:** Start Frontend (from frontend directory)

```sh
# Go to frontend folder
npm i
npm start # Should automatically open browser window with http://localhost:3000
```

Add new API to RIG. REST API calls from Frontend goes through RIG to external services, thus we need to tell RIG that such API exists (or define it in initial JSON file). At the same time by this we are testing proxy part of RIG.

```sh
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"kafka-service\",\"name\":\"kafka-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"kafka-producer-endpoint\",\"path_regex\":\"/produce\",\"method\":\"POST\",\"secured\":false}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"localhost\",\"port\":8000}}" \
--silent \
"http://localhost:7010/v2/apis"
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

## One word to distributed Tracing

RIG handles two types of messages: request/response messages (of any format) and events (in CloudEvents format). Tracing the former is done using headers - e.g., for HTTP RIG implements the w3c trace context specification. Tracing CloudEvents is done using the official CloudEvents tracing extension, where parent trace ID and trace context are taken from the context attributes of the event itself rather than from trace context headers.
For more information, read the [distributed tracing docs](../../docs/distributed-tracing.md).

In this example, RIG processes the trace context as following:

- frontend->RIG: RIG reads trace context from the http header (as this is an incoming message)
- RIG->Kafka: RIG creates a new span and forwards it to the kafka header (as it is still a message) (tackled in issue #311). Consequently, the backend application could potentially also process the -race context and create a new span out of it with the same trace-ID
- Backend->Kafka: Backend need to send the trace context via the event payload (because now we are talking of an event, and not a message anymore)
- Kafka->Rig: RIG will read the trace context from the cloudevent
- RIG->frontend: RIG emits the event, having the trace context in the event payload
