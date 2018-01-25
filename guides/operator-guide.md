# Operator's Guide to the Reactive Interaction Gateway

TODO ToC

TODO getting started

## Configuration

RIG uses environment variables for most of its configuration -- they're listed in the following table.

Variable | Description | Default
-------- | ----------- | -------
`JWT_SECRET_KEY` | The secret key used to sign and verify the JSON web tokens. | ""
`JWT_USER_FIELD` | The JSON web token as sent by the front-ends should contain the user ID, in the same format used by the back-ends in the messages they send towards the user. `JWT_USER_FIELD` is the name of that user ID field in the JWT. For the corresponding field used in outbound messages, see `MESSAGE_USER_FIELD`. | "user"
`MESSAGE_USER_FIELD` | (Outbound) messages are expected to be in JSON format. For routing the message to a specific user, RIG expects the user's ID to be present in such a JSON message. The corresponding JSON field is defined by `MESSAGE_USER_FIELD`. | "user"
`KAFKA_ENABLED` | If enabled, RIG will consume messages from a Kafka broker using the configured broker and topic(s). | false

.
