---
id: rig-ops-guide
title: Operator's Guide to the Reactive Interaction Gateway
sidebar_label: Operator's Guide
---

Typically, RIG is deployed using Docker. You can either use the image on Docker Hub, or build one yourself using `docker build -t rig .`.

## Configuration

RIG uses environment variables for most of its configuration, listed in the following table.

Variable&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description | Default
-------------- | ----------- | -------
`API_HTTP_PORT` | Port at which RIG exposes internal APIs such as API Proxy management or user connections management. | 4010
`API_HTTPS_PORT` | Same as `API_HTTP_PORT`, but encrypted. See `HTTPS_CERTFILE`, `HTTPS_KEYFILE`, `HTTPS_KEYFILE_PASS`. | 4011
`INBOUND_PORT` | Port at which RIG exposes proxy and websocket/sse/longpolling communication. | 4000
`INBOUND_HTTPS_PORT` | Same as `INBOUND_PORT`, but encrypted. See `HTTPS_CERTFILE`, `HTTPS_KEYFILE`, `HTTPS_KEYFILE_PASS`. | 4001
`HTTPS_CERTFILE` | Path to the public HTTPS certificate (PEM format). If set, HTTPS is enabled for all endpoints. | ""
`HTTPS_KEYFILE` | Path to the HTTPS certificate's private key (PEM format). Also supports encrypted private keys; see `HTTPS_KEYFILE_PASS` and consult the Erlang documentation for supported ciphers (e.g. [supported password ciphers in OTP 21.2](https://github.com/erlang/otp/blob/OTP-21.2/lib/public_key/src/pubkey_pbe.erl#L55); note that as of OTP 21.1, using an unsupported cipher fails silently). | ""
`HTTPS_KEYFILE_PASS` | Passphrase to the HTTPS certificate private key. Only set this if the private key is encrypted. | ""
`CORS` | The "Access-Control-Allow-Origin" setting for the inbound port. It is usually a good idea to set this to your domain. | "*"
`DISCOVERY_TYPE` | Type of discovery used in distributed mode. If not set discovery is not used. Available options: `dns`. | nil
`DNS_NAME` | Address where RIG will do DNS discovery for Node host addresses. | "localhost"
`EXTRACTORS` | Extractor configuration, given either as path to a JSON file, or directly as JSON. The extractor configuration contains information about events' fields per event type, used to _extract_ information. For example, the following setting allows clients to specify a constraint on the `name` field of `greeting` events: `EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/name"}}}}'`. Note that `stable_field_index` and `event/json_pointer` are required for all configured fields. | nil
`HOST` | Hostname for Phoenix endpoints (HTTP communication). | "localhost"
`JWT_SECRET_KEY` | The secret key used to sign and verify the JSON web tokens. | ""
`JWT_ALG` | Algorithm used to sign and verify JSON web tokens. | "HS256"
`JWT_SESSION_FIELD` | The JWT claim that defines a "session", which is used for listing and killing/blacklisting sessions. The default is to use a JWT's `jti` claim, which ["provides a unique identifier for the JWT"](https://tools.ietf.org/html/rfc7519#section-4.1.7). This way, when blacklisting a session, the user cannot use the respective token anymore, but is able to create a new one by re-authenticating with the backend. The `JWT_SESSION_FIELD` is specified using the [JSON Pointer](https://tools.ietf.org/html/rfc6901) notation. For example, this is how you would use a custom `sessionId` claim instead of the `jti`: `JWT_SESSION_FIELD=/sessionId`. | "/jti"
`KAFKA_BROKERS` | List of Kafka brokers RIG should connect to, delimited by comma (e.g., `localhost:9092,localhost:9093`). Usually it's enough to specify one broker and RIG will auto-discover rest of the Kafka cluster. | []
`KAFKA_LOG_SCHEMA` | Avro schema name for events published by logger | ""
`KAFKA_LOG_TOPIC` | Kafka topic for producer used to log HTTP requests going through RIG's API Proxy. | "rig-request-log"
`KAFKA_RESTART_DELAY_MS` | If the connection to Kafka fails or cannot be established, RIG retries setting up the connection after `KAFKA_RESTART_DELAY_MS` milliseconds. | nil
`KAFKA_SCHEMA_REGISTRY_HOST` | Host for Kafka Schema Registry. | nil
`KAFKA_SERIALIZER` | Serializer for Kafka events, currently supports Avro. By default uses JSON serialization. | nil
`KAFKA_SOURCE_TOPICS` | List of Kafka topics RIG will consume, delimited by comma. | ["rig"]
`KAFKATOFILTER_KAFKA_GROUP_ID` | Kafka group ID used for forwarding events according to subscriptions over SSE and WS connections. Make sure to use the same value on all RIG instances that belong to the same cluster. The default should be fine. | "rig-kafka-to-filter"
`KAFKA_SASL` | If set, SASL is used to authenticate RIG against the Kafka brokers. Use the following format for SASL/Plain authentication: "plain:myusername:mypassword". Note that setting `KAFKA_SASL` does *not* enable SSL (see `KAFKA_SSL_ENABLED` and related settings). | nil
`KAFKA_SSL_ENABLED` | Enables encrypted communication to Kafka brokers. | false
`KAFKA_SSL_CA_CERTFILE` | Path to the CA certificate (PEM format) that was used to sign the server and client certificates. Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "ca.crt.pem"
`KAFKA_SSL_CERTFILE` | Path to the (signed) client certificate (PEM format). Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "client.crt.pem"
`KAFKA_SSL_KEYFILE` | Path to the private key of the client certificate (PEM format). Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "client.key.pem"
`KAFKA_SSL_KEYFILE_PASS` | Passphrase in case the private key is password-protected. | ""
`KINESIS_APP_NAME` | From Amazon's documentation: "Name of the Amazon Kinesis application. This can assist with troubleshooting (e.g. distinguish requests made by separate applications). | "Reactive-Interaction-Gateway"
`KINESIS_AWS_REGION` | The AWS region the Kinesis stream is located in. | "eu-west-1"
`KINESIS_CLIENT_JAR` | Path to the kinesis-client jar file. | "./kinesis-client/target/rig-kinesis-client-1.0-SNAPSHOT.jar"
`KINESIS_DYNAMODB_ENDPOINT` | A specific DynamoDB endpoint instead of the default one - useful for testing. | ""
`KINESIS_ENABLED` | If enabled, RIG will consume messages from Amazon Kinesis using the configured parameters. Credentials are expected at `~/.aws/credentials`. | false
`KINESIS_ENDPOINT` | A specific Kinesis endpoint instead of the default one - useful for testing. | ""
`KINESIS_LOG_LEVEL` | The log level for the (Java) Kinesis-client subsystem. Allowed values: OFF, SEVERE, WARNING, INFO, CONFIG, FINE, FINER, FINEST, ALL. | "INFO"
`KINESIS_OTP_JAR` | Path to the `OtpErlang.jar` file that contains the `JInterface` implementation. If left empty, RIG picks the file from its Erlang environment (Erlang must be compiled with Java support enabled). | nil
`KINESIS_STREAM` | The name of the Kinesis stream to consume. | "RIG-outbound"
`LOG_LEVEL` | Log level. One of: `debug`, `info`, `warn`, `error`. | "warn"
`LOG_FMT` | Log format. May be set to `json` or `gcl` (Google Cloud Logger LogEntry format). | "erlang"
`NATS_SERVERS` | List of [NATS](https://nats.io) servers RIG should connect to, delimited by comma (e.g., `localhost:4222,example.com:4222`). | []
`NATS_SOURCE_TOPICS` | List of NATS topics to subscribe to, delimited by comma. | ["rig"]
`NATSTOFILTER_QUEUE_GROUP` | NATS [queue group](https://docs.nats.io/developing-with-nats/receiving/queues) used for forwarding events according to subscriptions over SSE and WS connections. Make sure to use the same value on all RIG instances that belong to the same cluster. The default should be fine. | "rig-nats-to-filter"
`NODE_COOKIE` | Erlang cookie used in distributed mode, so nodes in cluster can communicate between each other.<br />Used also as secret key for integrity-check of correlation IDs. | nil
`NODE_HOST` | Erlang hostname for given node, used to build Erlang long-name `rig@NODE_HOST`. This value is used by Erlang's distributed mode, so nodes can see each other. | nil
`PROXY_CONFIG_FILE` | Configuration JSON file with initial API definition for API Proxy. Use this variable to pass either a path to a JSON file, or the JSON string itself. A path can be given in absolute or in relative form (e.g., `proxy/your_json_file.json`). If given in relative form, the working directory is one of RIG's `priv` dirs (e.g., `/opt/sites/rig/lib/rig_inbound_gateway-2.0.2/priv/` in a Docker container). | nil
`PROXY_HTTP_ASYNC_RESPONSE_TIMEOUT` | In case an endpoint has `target` set to `http` and `response_from` set to `http_async`, this is the maximum delay between an HTTP request and the corresponding async HTTP response message. | 5000
`PROXY_RECV_TIMEOUT` | Timeout used when receiving a response for a forwarded/proxied request. | 5000
`PROXY_KAFKA_RESPONSE_TOPICS` | Kafka topic for acknowledging Kafka sync events from proxy by correlation ID | ["rig-proxy-response"]
`PROXY_KAFKA_RESPONSE_KAFKA_GROUP_ID` | Kafka group ID used for forwarding asynchronous HTTP responses to waiting HTTP clients. The default should be fine. | "rig-proxy-response"
`PROXY_KAFKA_RESPONSE_TIMEOUT` | In case an endpoint has `target` set to `http` and `response_from` set to `kafka`, this is the maximum delay between an HTTP request and the corresponding Kafka response message. | 5000
`PROXY_KINESIS_RESPONSE_TIMEOUT` | In case an endpoint has `target` set to `http` and `response_from` set to `kinesis`, this is the maximum delay between an HTTP request and the corresponding Kinesis response message. | 5000
`PROXY_KINESIS_REQUEST_REGION` | AWS region for Kinesis stream publishing events from proxy. | "eu-west-1"
`PROXY_NATS_RESPONSE_TIMEOUT` | If `response_from` is set to `nats`, this defines how long RIG waits for the response. | 60000
`REQUEST_LOG` | Type of loggers to use to log requests processed by API Proxy, delimited by comma. | []
`SUBMISSION_CHECK` | Select if and how submitting/publishing events should be denied. Can be either `no_check` (submissions are always allowed), `jwt_validation` (submissions are allowed if at least one authorization token is valid - using JWT_SECRET_KEY - and not blacklisted), or an URL that points to an external service that decides whether to allow or deny the submissions. Such an external service is expected to accept POST requests. The CloudEvent is passed as a JSON map in the body. The original request's `Authorization` headers are reused for this request. The submission is allowed if the service returns 2xx and denied otherwise; return either 401 or 403 to reject a submission request. | "NO_CHECK"
`SUBSCRIPTION_CHECK` | Select if and how creating subscriptions should be denied. Can be either `no_check` (subscriptions are always allowed), `jwt_validation` (subscription are allowed if at least one authorization token is valid - using JWT_SECRET_KEY - and not blacklisted), or an URL that points to an external service that decides whether to allow or deny the subscription. Such an external service is expected to accept POST requests. The subscription parameters are passed in the body. The original request's `Authorization` headers are reused for this request. The subscription is allowed if the service returns 2xx and denied otherwise; return either 401 or 403 to reject a subscription request. | "NO_CHECK"

.
