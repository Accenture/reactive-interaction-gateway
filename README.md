# RIG - Reactive Interaction Gateway

_The missing link between backend and frontend -- stop polling and go real-time!_

[![Build Status](https://travis-ci.org/Accenture/reactive-interaction-gateway.svg?branch=master)](https://travis-ci.org/Accenture/reactive-interaction-gateway)

Take a look at the [documentation](https://accenture.github.io/reactive-interaction-gateway/) and get in touch with us on [Slack](https://rig-opensource.slack.com)!

## What does it solve?

In short: handling asynchronous events.

Slightly longer:

You want UI updates without delay, "real time". However, handling connections to thousands of frontend instances concurrently is not only hard to implement in a scalable way – it also makes it very hard (impossible?) to upgrade your service without losing those connections. And in a microservice environment, which service should manage those connections?

Instead, let the Reactive Interaction Gateway (RIG) handle those connections for you. RIG is designed for scalability and allows you to focus on more important things. Backend (micro)services no longer have to care about connection state, which allows them to be stateless. Having stateless services enables many things, including DevOps practices, rolling updates and auto-scaling. RIG is built for consuming events from message brokers like Kafka and Kinesis, but it also supports submitting events using HTTP POST, which is great for testing and low-traffic scenarios.

Built on open standards, RIG is very easy to integrate – and easy to _replace_ – which means low-cost, low-risk adoption. Unlike other solutions, RIG does not leak into your application – no libraries or SDKs required.

RIG also comes with a basic API gateway implementation, enabling effective two-way communication between your services and your frontends.

## Getting Started

This is a small tutorial for getting started quickly. For a more in-depth introduction, see the [documentation](https://accenture.github.io/reactive-interaction-gateway/).

In this tutorial we use [HTTPie](https://httpie.org/) for HTTP requests, but of course you can also use curl or any other HTTP client. Please note that HTTPie sets the content type to `application/json` automatically, whereas for curl you need to use `-H "Content-Type: application/json"` for all but `GET` requests.

### 1. Start RIG

The easiest way to start RIG is using Docker. Before running a production setup please read the [RIG operator guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html), but for now all you need to do is this:

```bash
docker run -d -p 4000:4000 -p 4010:4010 accenture/reactive-interaction-gateway
```

### 2. Create a connection

Let's connect to RIG using [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events), which is our recommended approach (open standard, firewall friendly, plays nice with HTTP/2):

```bash
$ http --stream :4000/_rig/v1/connection/sse
HTTP/1.1 200 OK
connection: keep-alive
content-type: text/event-stream
transfer-encoding: chunked
...

event: rig.connection.create
data: {"cloudEventsVersion":"0.1","source":"rig","eventType":"rig.connection.create","eventTime":"2018-08-22T10:06:04.730484+00:00","eventID":"2b0a4f05-9032-4617-8d1e-92d97fb870dd","data":{"connection_token":"g2dkAA1ub25vZGVAbm9ob3N0AAACrAAAAAAA"}}
id: 2b0a4f05-9032-4617-8d1e-92d97fb870dd
```

After the connection has been established, RIG sends out a [CloudEvent](https://github.com/cloudevents/spec/blob/v0.1/spec.md) of type `rig.connection.create`.

> You can see that ID and event type of the outer event (= SSE event) match ID and event type of the inner event (= CloudEvent). The cloud event is serialized to the `data` field.

Please take note of the `connection_token` in the CloudEvent's `data` field - you need it in the next step.

### 3. Subscribe to a topic

With the connection established, you can create _subscriptions_ - that is, you can tell RIG which events your app is interested in. RIG needs to know which connection you are referring to, so you need to use the connection token you have noted down in the last step:

```bash
$ CONN_TOKEN="g2dkAA1ub25vZGVAbm9ob3N0AAACrAAAAAAA"
$ SUBSCRIPTIONS="{ "subscriptions": [ { "eventType": "greeting" } ] }"
$ http PUT ":4000/_rig/v1/connection/sse/${CONN_TOKEN}/subscriptions" <<<"$SUBSCRIPTIONS"
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
...
```

With that you're ready to receive all "greeting" events.

### 4. Create a new "greeting" event

RIG expects to receive [CloudEvents](https://github.com/cloudevents/spec/blob/v0.1/spec.md), so the following fields are required:

- `cloudEventsVersion`: must be set to "0.1".
- `eventType`: the event type in reverse-DNS notation, which basically means that an event looks like `com.github.pull.create`, and that `com.github.pull.create` is a sub-event of `com.github.pull`.
- `eventID`: a unique ID for an event (may be used for deduplication).
- `source`: describes the event producer.

For now, let's send a simple `greeting` event:

```bash
$ http post :4000/_rig/v1/events cloudEventsVersion=0.1 eventType=greeting eventID=first-event source=tutorial
HTTP/1.1 202 Accepted
content-type: application/json; charset=utf-8
...

{
    "cloudEventsVersion": "0.1",
    "eventID": "first-event",
    "eventTime": "2018-08-21T09:11:27.614970+00:00",
    "eventType": "greeting",
    "source": "tutorial"
}

```

RIG responds with `202 Accepted`, followed by the CloudEvent as sent to subscribers.

> If there are no subscribers for a received event, the response will still be `202 Accepted` and the event will be silently dropped.

### 5. The event has been delivered to our subscriber

Going back to the first terminal window you should now see your greeting event :tada:

### 6. Next: connect your app

Simply add an event listener to your frontend:

```javascript
const url = "http://localhost:4000/_rig/v1/connection/sse"
const source = new EventSource(url)

source.onopen = e => console.log("SSE connection open", e)
source.onerror = e => console.log("SSE connection error", e)

source.addEventListener("rig.connection.create", function (e) {
  cloudEvent = JSON.parse(e.data)
  payload = JSON.parse(cloudEvent.data)
  connectionToken = payload["connection_token"]
  createSubscriptions(connectionToken)
}, false)

source.addEventListener("greeting", function (e) {
  console.log("Got a greeting!")
}, false)
```

## Feature Summary

- Easy to use and scalable by design:
  - Supports tens of thousands stable connections per node even on low-end machines.
  - Easy to add additional nodes.
  - Built on the battle-proven [**Erlang/OTP**](http://www.erlang.org/) distribution model.
  - Only uses in-memory data structures - no external dependencies to configure or scale.
- Firewall friendly and future proof using **Server-Sent Events (SSE)**:
  - [HTML5 standard](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events).
  - Regular HTTP requests, so no issues with proxy servers or firewalls.
  - Connection multiplexing with HTTP/2 out of the box.
  - SSE implementation (browser) keeps track of connection drops and restores the connection automatically.
  - Polyfills available for older browsers.
- WebSocket connections are supported, too.
- Uses the upcoming [**CloudEvents** specification](https://github.com/cloudevents/spec).
- Flexible event subscription model:
  - Subscription based on event types.
  - Supports "recursive" subscriptions that include sub-events.
- _No_ business logic inside.
  - Use RIG for a public website, or
  - Use your existing services for authentication and authorization of users and subscriptions.
- JWT signature verification for APIs as a simple authentication check.
- Session blacklist with immediate session invalidation.

## Configuration, Integration, Deployment

RIG is designed to integrate easily into your current architecture. Should you have any problems, please open a Github issue. Also, check out
[the operator's guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html) for a description of available configuration options.

We use [SemVer](http://semver.org/) for versioning. For the versions available, take a look at the
[list of tags](https://github.com/Accenture/reactive-interaction-gateway/tags).

## Contribute

- **Use issues for everything.**
- For a small change, just send a PR.
- For bigger changes open an issue for discussion before sending a PR.
- PR should have:
  - Test case
  - Documentation (e.g., moduledoc, developer's guide, operator's guide)
  - Changelog entry
- You can also contribute by:
  - Reporting issues
  - Suggesting new features or enhancements
  - Improve/fix documentation

See the [developer's guide](guides/developer-guide.md) and [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

The Reactive Interaction Gateway (patent pending) is licensed under the Apache License 2.0 - see
[LICENSE](LICENSE) for details.

## Acknowledgments

The Reactive Interaction Gateway is sponsored and maintained by [Accenture](https://accenture.github.io/).

Kudos to these awesome projects:

- Elixir
- Erlang/OTP
- Phoenix Framework
- Brod
- Distillery

.
