# RigOutboundGateway

This app accepts messages from various sources and forwards them to the the PubSub
server managed by the `:rig` app. The PubSub topic name is determined by a
configurable function invocation; this should make for clear touch points to
`rig_inbound_gateway`.

See the [developer's guide](../../guides/developer-guide.md).
