# Configuration

Adopting RIG into your system should be easy. If you struggle, please open an Issue, so we can
ease the process for everyone. The moving parts:

- The [static configuration](#static-configuration), which is about options like timeouts or
  Kafka topic names
- The [API configuration file](#api-configuration), which holds the initial API/endpoint route
  definitions
- The [message formats](#message-formats)
- The [authentication token format](#authentication-token)

## Static Configuration

Most of RIGs settings can be configured in the files found in the [config directory](../config/).
For example, take a look at the [main config file](../config/config.exs), where you find most of
the options, along with their default values. The file should also be self-explanatory; if it
isn't, feel free to create a PR to start the discussion.

TODO: describe how to override at runtime

## API Configuration

TODO

## Message Formats

### Consuming Events
For consuming events from Kafka, the only field expected is a username.
For example:
```json
{"username":"SomeUser"}
```

### Producing Logs
For the format used for logging API calls to Kafka, see
[`Gateway.Kafka.log_proxy_api_call/3`](../lib/gateway/kafka.ex).

### Forwarding Events to Frontends
The format of the events pushed to the frontends depends on the transport
used. For example, when using Server-Sent Events, a message that on Kafka
looks like this:
```json
{"username":"SomeUser","greeting":"Hi there!"}
```
arrives at the browser like this:
```json
event: message
data: {"username":"SomeUser","greeting":"Hi there!"}

```

### Authentication Token
By default, RIG makes sure that requests to backend services are authorized (can be disabled per
service). For this to work, you need to use [JSON Web Tokens (JWT)](https://jwt.io/) as
authorization tokens. Of course, RIG has to know about the secret you're using for signing the
tokens in order to verify them. Additionally, the Reactive API Gateway expects some fields to be
present in the token's payload, specifically:
- "jti" (JWT ID) Claim
- "exp" (Expiration Time) Claim
- "user": same identifier used in the Kafka messages
- "roles": the list of roles a user has in the system. You can define privileged roles in the
  config; users that have one of those privileged roles in their "roles" claim are allowed to
  subscribe to any messages in the system, including those meant for other users.