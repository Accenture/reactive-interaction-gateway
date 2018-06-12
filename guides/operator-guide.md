# Operator's Guide to the Reactive Interaction Gateway

Typically, we deploy RIG using Docker. You can either use the image on Docker Hub, or build one yourself (try `docker build -t rig .`).

## Configuration

RIG uses environment variables for most of its configuration -- they're listed in the following table.

Variable | Description | Default
-------- | ----------- | -------
`API_PORT` | Port at which RIG exposes internal APIs such as API Proxy management or user connections management. | 4010
`DISCOVERY_TYPE` | Type of discovery used in distributed mode. If not set discovery is not used. Available options: `dns`. | nil
`DNS_NAME` | Address where RIG will do DNS discovery for Node host addresses. | "localhost"
`HOST` | Hostname for Phoenix endpoints (HTTP communication). | "localhost"
`INBOUND_PORT` | Port at which RIG exposes proxy and websocket/sse communication. | 4000
`JWT_BLACKLIST_DEFAULT_EXPIRY_HOURS` | Default expiration time in hours for blacklisted JWTs. Used if JWT doesn't have an expiration time in claims. | 1
`JWT_ROLES_FIELD` | Key in JWT claims under which roles are set for each user. | "roles"
`JWT_SECRET_KEY` | The secret key used to sign and verify the JSON web tokens. | ""
`JWT_USER_FIELD` | The JSON web token as sent by the front-ends should contain the user ID, in the same format used by the back-ends in the messages they send towards the user. `JWT_USER_FIELD` is the name of that user ID field in the JWT. For the corresponding field used in outbound messages, see `MESSAGE_USER_FIELD`. | "user"
`KAFKA_CONSUMER_GROUP` | Consumer group name for Kafka. | "rig-consumer-group"
`KAFKA_ENABLED` | If set to true, RIG will consume messages from a Kafka broker using the configured broker and topic(s). | false
`KAFKA_HOSTS` | List of Kafka brokers RIG should connect to, delimited by comma. Usually it's enough to specify one broker and RIG will auto-discover rest of the Kafka cluster. | ["localhost:9092"]
`KAFKA_LOG_TOPIC` | Kafka topic for producer used to log HTTP requests going through RIG's API Proxy. | "rig-request-log"
`KAFKA_RESTART_DELAY_MS` | If the connection to Kafka fails or cannot be established, RIG retries setting up the connection after `KAFKA_RESTART_DELAY_MS` milliseconds. | 20000
`KAFKA_SOURCE_TOPICS` | List of Kafka topics RIG will consume, delimited by comma. | ["rig"]
`KAFKA_SASL` | If set, SASL is used to authenticate RIG against the Kafka brokers. Use the following format for SASL/Plain authentication: "plain:myusername:mypassword". Note that setting `KAFKA_SASL` does *not* enable SSL (see `KAFKA_SSL_ENABLED` and related settings). | nil
`KAFKA_SSL_ENABLED` | Enables encrypted communication to Kafka brokers. | false
`KAFKA_SSL_CA_CERTFILE` | Path to the CA certificate (PEM format) that was used to sign the server and client certificates. Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "ca.crt"
`KAFKA_SSL_CERTFILE` | Path to the (signed) client certificate (PEM format). Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "client.crt"
`KAFKA_SSL_KEYFILE` | Path to the private key of the client certificate (PEM format). Similar to `PROXY_CONFIG_FILE` the path is relative to the OTP app's `priv` directory. | "client.key"
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
`MESSAGE_USER_FIELD` | (Outbound) messages are expected to be in JSON format. For routing the message to a specific user, RIG expects the user's ID to be present in such a JSON message. The corresponding JSON field is defined by `MESSAGE_USER_FIELD`. | "user"
`NODE_COOKIE` | Erlang cookie used in distributed mode, so nodes in cluster can communicate between each other. | nil
`NODE_HOST` | Erlang hostname for given node, used to build Erlang long-name `rig@NODE_HOST`. This value is used by Erlang's distributed mode, so nodes can see each other. | nil
`PRIVILEGED_ROLES` | User roles that are able to subscribe to messages of any user. You can specify multiple roles delimited by comma. | []
`PROXY_CONFIG_FILE` | Configuration JSON file with initial API definition for API Proxy. Expected path is `proxy/your_json_file.json`. | nil
`RATE_LIMIT_AVG_RATE_PER_SEC` | The permitted average amount of requests per second. | 10000
`RATE_LIMIT_BURST_SIZE` | The permitted peak amount of requests. | 5000
`RATE_LIMIT_ENABLED` | Enables/disables rate limiting globally. | false
`RATE_LIMIT_PER_IP` | If true, the remote IP is taken into account, otherwise the limits are per endpoint only. | true
`RATE_LIMIT_SWEEP_INTERVAL_MS` | Garbage collector interval. If set to zero, Garbage collector is disabled. | 5000
`REQUEST_LOG` | Type of loggers to use to log requests processed by API Proxy, delimited by comma. | []
`SESSION_ROLE` | Type of users that are visible to the outside world (possible to list). Only users with these roles will be listed. Possible roles are listed in `JWT_ROLES_FIELD`. Define as strings, separated by comma. | "user"

.
