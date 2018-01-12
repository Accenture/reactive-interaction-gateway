# RigOutboundGateway

This app accepts messages from various sources and forwards them to the the PubSub
server managed by the `:rig` app. The PubSub topic name is determined by a
configurable function invocation; this should make for clear touch points to
`rig_inbound_gateway`.

Currently supported sources:

- Kafka (topic with JSON payload)

Work in progress:

- HTTP API

Future candidates:

- AWS SQS
- RabbitMQ/AMQP
