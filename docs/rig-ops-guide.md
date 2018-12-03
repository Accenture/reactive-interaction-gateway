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
`API_PORT` | Port at which RIG exposes internal APIs such as API Proxy management or user connections management. | 4010
`CORS` | The "Access-Control-Allow-Origin" setting for the inbound port. It is usually a good idea to set this to your domain. | "*"
`DISCOVERY_TYPE` | Type of discovery used in distributed mode. If not set discovery is not used. Available options: `dns`. | nil
`DNS_NAME` | Address where RIG will do DNS discovery for Node host addresses. | "localhost"
`EXTRACTORS` | Extractor configuration, given either as path to a JSON file, or directly as JSON. The extractor configuration contains information about events' fields per event type, used to _extract_ information. For example, the following setting allows clients to specify a constraint on the `name` field of `greeting` events: `EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/name"}}}}'`. Note that `stable_field_index` and `event/json_pointer` are required for all configured fields. | nil
`FIREHOSE_KAFKA_HTTP_TARGETS` | List of HTTP endpoints where events will be sent from `FIREHOSE_KAFKA_SOURCE_TOPICS | []
`FIREHOSE_KAFKA_SOURCE_TOPICS` | List of Kafka topics RIG will use as a firehose consumer, delimited by comma. Events will be sent to `FIREHOSE_KAFKA_HTTP_TARGETS | ["rig-firehose"]
`FIREHOSE_KINESIS_APP_NAME` | Name for Firehose Kinesis consumer group -- DynamoDB table | "Reactive-Interaction-Gateway-Firehose"
`FIREHOSE_KINESIS_HTTP_TARGETS` | List of HTTP endpoints where events will be sent from `FIREHOSE_KINESIS_STREAM | ["http://localhost:4040/todo"]
`FIREHOSE_KINESIS_STREAM` | Kinesis stream RIG will use as a firehose consumer. Events will be sent to `FIREHOSE_KINESIS_HTTP_TARGETS | "RIG-firehose"
`HOST` | Hostname for Phoenix endpoints (HTTP communication). | "localhost"
`INBOUND_PORT` | Port at which RIG exposes proxy and websocket/sse communication. | 4000
`JWT_BLACKLIST_DEFAULT_EXPIRY_HOURS` | DEPRECATED. Default expiration time in hours for blacklisted JWTs. Used if JWT doesn't have an expiration time in claims. | 1
`JWT_ROLES_FIELD` | DEPRECATED. Key in JWT claims under which roles are set for each user. | "roles"
`JWT_SECRET_KEY` | The secret key used to sign and verify the JSON web tokens. | ""
`JWT_ALG` | Algorithm used to sign and verify JSON web tokens. | "HS256"
`JWT_USER_FIELD` | DEPRECATED. The JSON web token as sent by the front-ends should contain the user ID, in the same format used by the back-ends in the messages they send towards the user. `JWT_USER_FIELD` is the name of that user ID field in the JWT. For the corresponding field used in outbound messages, see `MESSAGE_USER_FIELD`. | "user"
`JWT_SESSION_FIELD` | The JWT field that defines a "session", which is used for listing and killing/blacklisting sessions. What a session is depends on your application. For example, one might set `JWT_SESSION_FIELD` to the users' ID field, which would group all connections that belong to the same user to a single session - this way, blacklisting a session would mean killing all connections of a single user. The `JWT_SESSION_FIELD` is specified using the [JSON Pointer](https://tools.ietf.org/html/rfc6901) notation. Given that the JWT contains a user ID in its "userId" field, the configuration could look like this: `JWT_SESSION_FIELD=/userId`. | nil
`KAFKA_ENABLED` | DEPRECATED. If set to true, RIG will consume messages from a Kafka broker using the configured broker and topic(s). | nil
`KAFKA_BROKERS` | List of Kafka brokers RIG should connect to, delimited by comma (e.g., `localhost:9092,localhost:9093`). Usually it's enough to specify one broker and RIG will auto-discover rest of the Kafka cluster. | []
`KAFKA_LOG_TOPIC` | Kafka topic for producer used to log HTTP requests going through RIG's API Proxy. | "rig-request-log"
`KAFKA_RESTART_DELAY_MS` | If the connection to Kafka fails or cannot be established, RIG retries setting up the connection after `KAFKA_RESTART_DELAY_MS` milliseconds. | nil
`KAFKA_SOURCE_TOPICS` | List of Kafka topics RIG will consume, delimited by comma. | ["rig"]
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
`LOG_LEVEL` | Controls logging level for RIG, available values are: "debug", "info", "warn", "error". Production is using "warn" level. | :debug
`MESSAGE_USER_FIELD` | DEPRECATED. (Outbound) messages are expected to be in JSON format. For routing the message to a specific user, RIG expects the user's ID to be present in such a JSON message. The corresponding JSON field is defined by `MESSAGE_USER_FIELD`. | "user"
`NODE_COOKIE` | Erlang cookie used in distributed mode, so nodes in cluster can communicate between each other. | nil
`NODE_HOST` | Erlang hostname for given node, used to build Erlang long-name `rig@NODE_HOST`. This value is used by Erlang's distributed mode, so nodes can see each other. | nil
`PRIVILEGED_ROLES` | DEPRECATED. User roles that are able to subscribe to messages of any user. You can specify multiple roles delimited by comma. | []
`PROXY_CONFIG_FILE` | Configuration JSON file with initial API definition for API Proxy. Expected path is `proxy/your_json_file.json`. | nil
`PROXY_RECV_TIMEOUT` | Timeout used when receiving a response for a forwarded/proxied request. | 5000
`PROXY_KAFKA_RESPONSE_TOPICS` | Kafka topic for acknowledging Kafka sync events from proxy by correlation ID | ["rig-proxy-response"]
`PROXY_KAFKA_REQUEST_TOPIC` | Kafka topic for publishing sync/async events from proxy. | ""
`PROXY_KAFKA_RESPONSE_TIMEOUT` | In case an endpoint has `target` set to `http` and `response_from` set to `kafka`, this is the maximum delay between an HTTP request and the corresponding Kafka response message. | 5000
`PROXY_KINESIS_RESPONSE_TIMEOUT` | In case an endpoint has `target` set to `http` and `response_from` set to `kinesis`, this is the maximum delay between an HTTP request and the corresponding Kinesis response message. | 5000
`PROXY_KINESIS_REQUEST_REGION` | AWS region for Kinesis stream publishing events from proxy. | "eu-west-1"
`PROXY_KINESIS_REQUEST_STREAM` | Kinesis stream for publishing sync/async events from proxy. | nil
`RATE_LIMIT_AVG_RATE_PER_SEC` | DEPRECATED. The permitted average amount of requests per second. | 10000
`RATE_LIMIT_BURST_SIZE` | DEPRECATED. The permitted peak amount of requests. | 5000
`RATE_LIMIT_ENABLED` | DEPRECATED. Enables/disables rate limiting globally. | false
`RATE_LIMIT_PER_IP` | DEPRECATED. If true, the remote IP is taken into account, otherwise the limits are per endpoint only. | true
`RATE_LIMIT_SWEEP_INTERVAL_MS` | DEPRECATED. Garbage collector interval. If set to zero, Garbage collector is disabled. | 5000
`REQUEST_LOG` | Type of loggers to use to log requests processed by API Proxy, delimited by comma. | []
`SESSION_ROLE` | DEPRECATED. Type of users that are visible to the outside world (possible to list). Only users with these roles will be listed. Possible roles are listed in `JWT_ROLES_FIELD`. Define as strings, separated by comma. | "user"
`SUBMISSION_CHECK` | Select if and how submitting/publishing events should be denied. Can be either `no_check` (submissions are always allowed), `jwt_validation` (submissions are allowed if at least one authorization token is valid - using JWT_SECRET_KEY - and not blacklisted), or an URL that points to an external service that decides whether to allow or deny the submissions. Such an external service is expected to accept POST requests. The CloudEvent is passed as a JSON map in the body. The original request's `Authorization` headers are reused for this request. The subscription is allowed if the service returns 2xx and denied otherwise. | "NO_CHECK"
`SUBSCRIPTION_CHECK` | Select if and how creating subscriptions should be denied. Can be either `no_check` (subscriptions are always allowed), `jwt_validation` (subscription are allowed if at least one authorization token is valid - using JWT_SECRET_KEY - and not blacklisted), or an URL that points to an external service that decides whether to allow or deny the subscription. Such an external service is expected to accept POST requests. The subscription parameters are passed in the body. The original request's `Authorization` headers are reused for this request. The subscription is allowed if the service returns 2xx and denied otherwise. | "NO_CHECK"

.
