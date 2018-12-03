# Reactive Interaction Gateway Events Example

Service that serves as a REST API. Implements one endpoint that can produce message to Kafka and respond if it went ok or not. Uses Hapi as a HTTP server.

## Quick start

```sh
npm i
npm start
```

## Change environment variables

Available values you can setup with env vars. This values should be the same as RIG has.

```sh
KAFKA_HOSTS => default value 'localhost:9092'
KAFKA_SOURCE_TOPICS => default value 'example';
```
