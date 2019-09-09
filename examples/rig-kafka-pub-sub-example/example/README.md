### Overview

We send a POST request to the Reactive Gateway (RIG), which publishes to Kafka, then that Kafka topic is consumed by a Springboot application, which does a simple data transformation and publishes back onto a topic, which is consumed by RIG and published to the front end.

This demo is currently showing this flow from the commandline.

### Setting Up The Environment 
Clone and run the docker-starter repo. This creates an instance of Kafka, Zookeeper, RIG, and the example Springboot application.

First, we have to build the Springboot app's Docker image.

```bash
cd example
docker build -t example -f Dockerfile .
```

Then run the simple start script.
```bash
cd docker-starter
./start.sh
```

Notes:
- Topics for kafka are set at the `KAFKA_SOURCE_TOPICS` flag:

```yml
  reactive-interaction-gateway:
    container_name: reactive-interaction-gateway
    image: accenture/reactive-interaction-gateway
    environment:
      - LOG_LEVEL=debug
      - KAFKA_SOURCE_TOPICS=rig,rig-consumed
      - PROXY_KAFKA_REQUEST_TOPIC=rig
      - KAFKA_BROKERS=kafka:9092
      - API_HTTP_PORT=7010
      - INBOUND_PORT=7000
      - PROXY_CONFIG_FILE=/rig-proxy.json
```

- The internal and the external ports for Kafka are different. 

In the Dockerfile
```yml
 kafka:
    image: confluentinc/cp-kafka:5.0.0
    container_name: kafka
    ports:
      - 9092:9092 # container communication
      - 9094:9094 # localhost communication
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zk:2181
      KAFKA_ADVERTISED_LISTENERS: INSIDE://kafka:9092,OUTSIDE://localhost:9094
      KAFKA_LISTENERS: INSIDE://0.0.0.0:9092,OUTSIDE://0.0.0.0:9094
```

You'll see below when we ssh into the container, from the CLI there we use 9092.

However our Springboot application yaml is the public facing 9094

```yml
spring:
  profiles: local
  kafka:
    properties:
      security.protocol: PLAINTEXT
    consumer:
      bootstrap-servers: 127.0.0.1:9094
    producer:
      bootstrap-servers: 127.0.0.1:9094
```

### Setup the Routes in RIG
We set up the routes in RIG by hitting the `/apis` endpoint.

POST
```http://localhost:7010/v1/apis```

Body
```JSON
{
  "id": "new-service",
  "name": "new-service",
  "auth_type": "none",
  "auth": {
    "use_header": false,
    "header_name": "",
    "use_query": false,
    "query_name": ""
  },
  "versioned": false,
  "version_data": {
    "default": {
      "endpoints": [
        {
          "id": "async-publish",
          "path": "/api/async-publish",
          "method": "POST",
          "target": "kafka",
          "secured": false
        },
        {
          "id": "sync-publish",
          "path": "/api/sync-publish",
          "method": "POST",
          "target": "kafka",
          "response_from": "kafka",
          "secured": false
        }
      ]
    }
  },
  "proxy": {
    "use_env": true,
    "target_url": "KS_HOST",
    "port": 9092
  }
}
```

Response
```JSON
{
    "message": "ok"
}
```

### RIG -> Kafka -> Java -> Kafka -> RIG
Set up RIG to output events to the commandline.

```bash
http --stream ':7000/_rig/v1/connection/sse?subscriptions=[{"eventType":"com.example"}]'
```

*Output*
```bash
⚡ http --stream ':7000/_rig/v1/connection/sse?subscriptions=[{"eventType":"com.example"}]'
HTTP/1.1 200 OK
access-control-allow-origin: *
cache-control: no-cache
content-type: text/event-stream; charset=utf-8
date: Thu, 29 Aug 2019 21:31:29 GMT
server: Cowboy
transfer-encoding: chunked

event: rig.connection.create
data: {"data":{"connection_token":"g2dkAA1yaWdAMTI3LjAuMC4xAAAPJwAAAAAD"},"id":"632f6767-0c2e-4166-82ae-27c2be34df43","source":"rig","specversion":"0.2","time":"2019-08-29T21:31:30.362896+00:00","type":"rig.connection.create"}

event: rig.subscriptions_set
data: {"data":[{"eventType":"com.example","oneOf":[]}],"id":"9a4187a0-af79-439e-b07b-27e98bee9e7f","source":"rig","specversion":"0.2","time":"2019-08-29T21:31:30.369058+00:00","type":"rig.subscriptions_set"}

: heartbeat
```

Have Kafka output to the CLI for both topics RIG and the Springboot app consume and produce.

```bash
docker exec -it kafka bash
```

You now have a command prompt in Kafka.

```bash
kafka-console-consumer --bootstrap-server kafka:9092 --topic rig --from-beginning
```

Open a second window
```bash
docker exec -it kafka bash
```

```bash
kafka-console-consumer --bootstrap-server kafka:9092 --topic rig-consumed --from-beginning
```

Send a POST request to RIG

```
http://localhost:7000/api/async-publish
```

Body:
```JSON
{
    "id":"069711bf-3946-4661-984f-c667657b8d85",
    "type":"com.example",
    "time":"2018-04-05T17:31:00Z",
    "specversion":"0.2",
    "source":"/cli",
    "contenttype":"application/json",
    "rig": {
    "target_partition": "the-partition-key"
  },
    "data": { 
              "payload": { "payload": "payload", "number": 2 }
            }
  }
```

Response
```
Accepted.
```

You should see both the outgoing and the transformed message in the RIG subscriptions tab (below). The latter is truncated for length.

```JSON
{
  "type": "com.example",
  "time": "2018-04-05T17:31:00Z",
  "specversion": "0.2",
  "source": "/cli",
  "rig": {
    "scheme": "http",
    "remoteip": "172.18.0.1",
    "query": "",
    "port": 7000,
    "path": "/api/async-publish",
    "method": "POST",
    "host": "localhost",
    "headers": [
      [
        "accept",
        "*/*"
      ],
      [
        "accept-encoding",
        "gzip, deflate"
      ],
      [
        "cache-control",
        "no-cache"
      ],
      [
        "connection",
        "keep-alive"
      ],
      [
        "content-length",
        "331"
      ],
      [
        "content-type",
        "application/json"
      ],
      [
        "host",
        "localhost:7000"
      ],
      [
        "postman-token",
        "6a440d1e-e4fd-448a-84c5-d31a9e3c5f2e"
      ],
      [
        "user-agent",
        "PostmanRuntime/7.15.2"
      ],
      [
        "forwarded",
        "for=172.18.0.1;by=127.0.0.1"
      ]
    ],
    "correlation": "g2dkAA1yaWdAMTI3LjAuMC4xAAARCAAAAAAD"
  },
  "id": "069711bf-3946-4661-984f-c667657b8d85",
  "data": {
    "payload": {
      "payload": "payload",
      "number": 2
    }
  },
  "contenttype": "application/json"
}
```

Transformed:
```json
{
  "id": "069711bf-3946-4661-984f-c667657b8d85",
  "type": "com.example",
  "time": "2018-04-05T17:31:00Z",
  "specversion": "0.2",
  "source": "/cli",
  "contenttype": "application/json",
  "data": {
    "payload": {
      "payload": "payload TRANSFORMED",
      "number": 4
    }
  },
  "rig": { ... }
}
```

You will also see in the Kafka windows the publication to those Kafka topics.

Topic "rig"
```
{"type":"com.example","time":"2018-04-05T17:31:00Z","specversion":"0.2","source":"/cli","rig":{"scheme":"http","remoteip":"172.18.0.1","query":"","port":7000,"path":"/api/async-publish","method":"POST","host":"localhost","headers":[["accept","*/*"],["accept-encoding","gzip, deflate"],["cache-control","no-cache"],["connection","keep-alive"],["content-length","331"],["content-type","application/json"],["host","localhost:7000"],["postman-token","6a440d1e-e4fd-448a-84c5-d31a9e3c5f2e"],["user-agent","PostmanRuntime/7.15.2"],["forwarded","for=172.18.0.1;by=127.0.0.1"]],"correlation":"g2dkAA1yaWdAMTI3LjAuMC4xAAARCAAAAAAD"},"id":"069711bf-3946-4661-984f-c667657b8d85","data":{"payload":{"payload":"payload","number":2}},"contenttype":"application/json"}
```

Topic "rig-consumed"
```
{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"com.example","time":"2018-04-05T17:31:00Z","specversion":"0.2","source":"/cli","contenttype":"application/json","data":{"payload":{"payload":"payload TRANSFORMED","number":4}},"rig":{"scheme":"http","remoteip":"172.18.0.1","query":"","port":7000.0,"path":"/api/async-publish","method":"POST","host":"localhost","headers":[["accept","*/*"],["accept-encoding","gzip, deflate"],["cache-control","no-cache"],["connection","keep-alive"],["content-length","331"],["content-type","application/json"],["host","localhost:7000"],["postman-token","6a440d1e-e4fd-448a-84c5-d31a9e3c5f2e"],["user-agent","PostmanRuntime/7.15.2"],["forwarded","for\u003d172.18.0.1;by\u003d127.0.0.1"]],"correlation":"g2dkAA1yaWdAMTI3LjAuMC4xAAARCAAAAAAD"}}
```

