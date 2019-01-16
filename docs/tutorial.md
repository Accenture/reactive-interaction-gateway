---
id: tutorial
title: Tutorial
sidebar_label: Tutorial
---

In this tutorial we use [HTTPie](https://httpie.org/) for HTTP requests, but of course you can also use curl or any other HTTP client. Please note that HTTPie sets the content type to `application/json` automatically, whereas for curl you need to use `-H "Content-Type: application/json"` for all but `GET` requests.

### 1. Start RIG

The easiest way to start RIG is using Docker. Before running a production setup please read the [RIG operator guide](rig-ops-guide.md), but for now all you need to do is this:

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
data: {"specversion":"0.2","source":"rig","type":"rig.connection.create","time":"2018-08-22T10:06:04.730484+00:00","id":"2b0a4f05-9032-4617-8d1e-92d97fb870dd","data":{"connection_token":"g2dkAA1ub25vZGVAbm9ob3N0AAACrAAAAAAA"}}
id: 2b0a4f05-9032-4617-8d1e-92d97fb870dd
```

After the connection has been established, RIG sends out a [CloudEvent](https://github.com/cloudevents/spec/blob/v0.2/spec.md) of type `rig.connection.create`.

> You can see that ID and event type of the outer event (= SSE event) match ID and event type of the inner event (= CloudEvent). The cloud event is serialized to the `data` field.

Please take note of the `connection_token` in the CloudEvent's `data` field - you need it in the next step.

### 3. Subscribe to a topic

With the connection established, you can create _subscriptions_ - that is, you can tell RIG which events your app is interested in. RIG needs to know which connection you are referring to, so you need to use the connection token you have noted down in the last step:

```bash
$ CONN_TOKEN="g2dkAA1ub25vZGVAbm9ob3N0AAACrAAAAAAA"
$ SUBSCRIPTIONS='{"subscriptions":[{"eventType":"greeting"}]}'
$ http put ":4000/_rig/v1/connection/sse/${CONN_TOKEN}/subscriptions" <<<"$SUBSCRIPTIONS"
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
...
```

With that you're ready to receive all "greeting" events.

### 4. Create a new "greeting" event

RIG expects to receive [CloudEvents](https://github.com/cloudevents/spec), so the following fields are required:

- `specversion`: must be set to "0.2" (version "0.1" is also supported).
- `type`: Type of occurrence which has happened. Often this attribute is used for routing, observability, policy enforcement, etc.
- `id`: ID of the event. The semantics of this string are explicitly undefined to ease the implementation of producers. Enables deduplication.
- `source`: This describes the event producer. Often this will include information such as the type of the event source, the organization publishing the event, the process that produced the event, and some unique identifiers. The exact syntax and semantics behind the data encoded in the URI is event producer defined.

Let's send a simple `greeting` event:

```bash
$ http post :4000/_rig/v1/events specversion=0.2 type=greeting id=first-event source=tutorial
HTTP/1.1 202 Accepted
content-type: application/json; charset=utf-8
...

{
    "specversion": "0.2",
    "id": "first-event",
    "time": "2018-08-21T09:11:27.614970+00:00",
    "type": "greeting",
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
  const { connectionToken } = cloudEvent.data
  createSubscriptions(connectionToken)
}, false)

source.addEventListener("rig.subscriptions_set", function (e) {
  cloudEvent = JSON.parse(e.data)
  const { type } = cloudEvent.data
  console.log(`Now subscribed to ${type}`)
}, false)

source.addEventListener("greeting", function (e) {
  console.log("Got a greeting!")
}, false)
```
