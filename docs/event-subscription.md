---
id: event-subscription
title: Receiving Events on Frontends
sidebar_label: Receiving Events
---

There are **two ways to receive events**, either via [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events) (SSE) or via a [WebSocket](https://en.wikipedia.org/wiki/WebSocket) connection. We recommend SSE:

- With HTTP/2, there is no (practical) limit to the number of SSE connections/streams that can be created.
- SSE does not require dropping the HTTP protocol, which makes it firewall-friendly.
- SSE is a better fit to the architecture RIG implements (WebSocket is typically used for full-duplex connection).

**Event subscriptions** allow both backend and frontend developers to select the events they want to have forwarded towards the UI:

- Frontend developers can set up **(manual) subscriptions** that refer to an event type and zero, one or more _named_ fields of an event. The fields that can be referred to have to be set up in advance using the so-called _extractor configuration_ (see below).
- Backend developers/administrators can set up **automatic subscriptions**, where events are subscribed to according to the JWT the UI sends with its request.

Both automatic and manual subscriptions can be used at the same time - they are simply merged into a single set of subscriptions. Below there are examples for both types, but first we introduce _constraints_ and _extractors_.

## Constraints & Extractors

If subscribing to events by their event type is all you need, you can skip this.

For a larges example and more details take a look at [the source documentation of `EventFilter`](https://accenture.github.io/reactive-interaction-gateway/source_docs/Rig.EventFilter.html).

### Constraints

Constraints allow you to subscribe to events based on the value of pre-defined fields. For example, this is a subscription for "greeting" events that have the "name" field set to "John":

```json
{
  "subscriptions": [
    {
      "eventType": "greeting",
      "oneOf": [
        { "name": "John" }
      ]
    }
  ]
}
```

The "oneOf" property contains a list of objects. Each object may contain one or more fields and each of them must match the respective value in the event, but only one of those objects must match (that's the reason the property is called "oneOf"). This allows you to query for greeting event to either "John" or "Frank":

```json
{
  "subscriptions": [
    {
      "eventType": "greeting",
      "oneOf": [
        { "name": "John" },
        { "name": "Frank" }
      ]
    }
  ]
}
```

### Basic Extractor configuration

When referring to the "name" field in a subscription, we assume that RIG knows what "name" refers to in incoming events. In RIG, obtaining the value for a named field is called _extraction_ and the corresponding configuration is called _extractor configuration_. The latter can be set using the `EXTRACTORS` environment variable, which expects either a file path or a JSON encoded string.

Consider the following extractor configuration, `extractors.json`:

```json
{
  "greeting": {
    "name": {
      "stable_field_index": 1,
      "event": {
        "json_pointer": "/data/name"
      }
    }
  }
}
```

This sets up an extractor for events of type "greeting". It has one field called "name"; the value of "name" for any given event is extracted using the [JSON Pointer](https://tools.ietf.org/html/rfc6901) `/data/name`.

We can pass this configuration to RIG using the environment variable:

```bash
export EXTRACTORS=extractors.json
```

Assuming the UI sets up a subscription like this:

```json
{ "subscriptions": [ { "eventType": "greeting", "oneOf": [ { "name": "John" } ] } ] }
```

And RIG receives the following event:

```json
{
  "type": "greeting",
  "data": {
    "name": "John"
  },
  ...
}
```

Then RIG's greeting extractor would use the JSON pointer configured for "name" to extract the value "John" and match that against the subscription - this matches, so RIG forwards the event to the UI.

### Extractor configuration for automatic subscriptions

In order to support automatic, JWT-based subscriptions, the extractor also needs to know how to extract the value from JWT claims. Going back to the previous example, we extends the extractor configuration by an additional `jwt` property:

<pre><code>
{
  "greeting": {
    "name": {
      "stable_field_index": 1,
      "event": {
        "json_pointer": "/data/name"
      },
      <b>"jwt": {
        "json_pointer": "/username"
      }</b>
    }
  }
}
</code></pre>

With that configuration, a frontend receives all events of type "greeting" where the value of `/data/name` equals the value of `/username` in the JWT.

## Manual subscriptions

Manual subscriptions can be set up when establishing the connection. Additionally, RIG offers an endpoint to update a connection's subscriptions after the connection has already been established.

The following example works similarly for both SSE and WebSocket. We use HTTPie here to make the examples a bit shorter. See the [MDN web docs article on SSE](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) for an example on how to set up SSE in a browser.

Example for setting up initial subscriptions:

```bash
$ http --stream ':4000/_rig/v1/connection/sse?subscriptions=[{"eventType":"greeting"}]'
HTTP/1.1 200 OK
content-type: text/event-stream
transfer-encoding: chunked

event: rig.connection.create
data: {"data":{"connection_token":"g2dkAA1yaWdAMTI3LjAuMC4xAAAKNwAAAAAD","errors":[]},"id":"634b8420-010f-4430-870b-fb5ca8e02945","source":"rig","specversion":"0.2","time":"2019-03-27T11:53:18.435690+00:00","type":"rig.connection.create"}

event: rig.subscriptions_set
data: {"data":[{"eventType":"greeting","oneOf":[]}],"id":"ec4deb26-d2a7-46ed-806d-d1beaa2560f8","source":"rig","specversion":"0.2","time":"2019-03-27T11:53:18.438281+00:00","type":"rig.subscriptions_set"}

```

Note that the `rig.subscriptions_set` event includes the passed subscription. Also, note that the `rig.connection.create` event includes a `connection_token`; this token can now be used to update the subscriptions after the connection has been established. Let's replace our initial subscription to "greeting" with a new one to "greeting2":

```bash
$ CONN_TOKEN=g2dkAA1yaWdAMTI3LjAuMC4xAAAKTAAAAAAD
$ BODY='{"subscriptions": [{"eventType":"greeting2"}]}'
$ echo "${BODY}" | http put :4000/_rig/v1/connection/sse/${CONN_TOKEN}/subscriptions
HTTP/1.1 204 No Content

```

After this call, the client receives a new `rig.subscriptions_set` event:

```plaintext
event: rig.subscriptions_set
data: {"data":[{"eventType":"greeting2","oneOf":[]}],"id":"0ba84600-f5cc-4abb-b55d-f9e145cbd03d","source":"rig","specversion":"0.2","time":"2019-03-27T11:58:11.411963+00:00","type":"rig.subscriptions_set"}
```

We see that the subscription to "greeting" has been replaced by a subscription to "greeting2".

Note that if you want to retain any automatic subscriptions you got along with setting up the connection, you need to make sure you _include the same HTTP Authorization header in both requests_.

## Subscription Authorization

RIG can either allow anyone to subscribe to any events, restrict subscriptions to clients that send a valid JWT, or forward subscription requests to an external endpoint and let that endpoint decide whether or not to allow a particular subscription. This can be configured using the environment variable `SUBSCRIPTION_CHECK` - please consult the [Operator's Guide](rig-ops-guide) for details.

