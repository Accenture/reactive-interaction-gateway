# Operator's Guide to the Reactive Interaction Gateway

TODO ToC

TODO getting started

## Configuration

RIG uses environment variables for most of its configuration -- they're listed in the following table.

Variable | Description | Default
-------- | ----------- | -------
`JWT_SECRET_KEY` | The secret key used to sign and verify the JSON web tokens. | ""
`JWT_USER_FIELD` | The JSON web token as sent by the front-ends should contain the user ID, in the same format used by the back-ends in the messages they send towards the user. `JWT_USER_FIELD` is the name of that user ID field in the JWT. For the corresponding field used in outbound messages, see `MESSAGE_USER_FIELD`. | "user"
`KAFKA_ENABLED` | If enabled, RIG will consume messages from a Kafka broker using the configured broker and topic(s). | false
`KINESIS_ENABLED` | If enabled, RIG will consume messages from Amazon Kinesis using the configured parameters. Credentials are expected at `~/.aws/credentials`. | false
`KINESIS_CLIENT_JAR` | Path to the kinesis-client jar file. | "./kinesis-client/target/rig-kinesis-client-1.0-SNAPSHOT.jar"
`KINESIS_OTP_JAR` | Path to the `OtpErlang.jar` file that contains the `JInterface` implementation. If left empty, RIG picks the file from its Erlang environment (Erlang must be compiled with Java support enabled). | nil
`KINESIS_LOG_LEVEL` | The log level for the (Java) Kinesis-client subsystem. Allowed values: OFF, SEVERE, WARNING, INFO, CONFIG, FINE, FINER, FINEST, ALL. | "INFO"
`KINESIS_APP_NAME` | From Amazon's documentation: "Name of the Amazon Kinesis application. This can assist with troubleshooting (e.g. distinguish requests made by separate applications). | "Reactive-Interaction-Gateway"
`KINESIS_AWS_REGION` | The AWS region the Kinesis stream is located in. | "eu-west-1"
`KINESIS_STREAM` | The name of the Kinesis stream to consume. | "RIG-outbound"
`KINESIS_ENDPOINT` | A specific Kinesis endpoint instead of the default one - useful for testing. | ""
`KINESIS_DYNAMODB_ENDPOINT` | A specific DynamoDB endpoint instead of the default one - useful for testing. | ""
`LOG_LEVEL` | Controls logging level for RIG, available values are: "debug", "info", "warn", "error". Production is using "warn" level. | :debug
`MESSAGE_USER_FIELD` | (Outbound) messages are expected to be in JSON format. For routing the message to a specific user, RIG expects the user's ID to be present in such a JSON message. The corresponding JSON field is defined by `MESSAGE_USER_FIELD`. | "user"

.
