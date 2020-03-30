# HTTP <> Kafka SASL Plain

A simple example for RIG inbound gateway to Kafka with SASL Plain enabled. Kudos to [kafka-security-playbook](https://github.com/Dabz/kafka-security-playbook) where we took the Kafka SASL Plain setup.

1. Start Kafka and RIG

    ```shell
    ./up
    ```

2. Start a Kafka console consumer

    ```shell
    docker-compose exec kafka kafka-console-consumer --bootstrap-server kafka:9093 --consumer.config /etc/kafka/consumer.properties --topic test --from-beginning
    ```

3. Send a message to Kafka through RIG

    ```shell
    curl \
        -H 'traceparent: 00-9c18b63f316cbfe3854122c20c8c6b23-22d69e0945046f2d-01' \
        -H 'tracestate: hello=tracing' \
        --data "{\"specversion\":\"0.2\",\"type\":\"com.github.pull.create\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\",\"data\":\"hello\"}"  localhost:400
    ```

    You should see the message at the Kafka console consumer.
