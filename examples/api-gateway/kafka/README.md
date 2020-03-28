# API Gateway HTTP <> Kafka

First start Kafka

```shell
docker-compose -f kafka.docker-compose.yml up -d
```

Start RIG locally:

```shell
cd ../../../
export KAFKA_SOURCE_TOPICS=example
export API_HOST=localhost
config=$(cat examples/api-gateway/kafka/config.json)
export PROXY_CONFIG_FILE="$config"
mix run --no-halt
```

[Download some quickstart scripts for Kafka](https://kafka.apache.org/quickstart) and run a consumer:

```shell
/path/to/download/folder/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic example --from-beginning
```

After that we should be able to send events to Kafka through RIG:

```shell
curl --data "{\"specversion\":\"0.2\",\"type\":\"com.github.pull.create\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\", \"traceparent\": \"00-9c18b63f316cbfe3854122c20c8c6b23-22d69e0945046f2d-01\", \"tracestate\": \"hello=world\",\"data\":\"hello\"}"  localhost:4000
```

You should see the message in the Kafka consumer.
