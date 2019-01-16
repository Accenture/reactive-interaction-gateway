---
id: event-subscription
title: Event Subscription
sidebar_label: Event Subscription
---

Important part of RIG is creating event subscriptions. RIG is holding connections between clients and itself and forwarding events to proper clients. Currently the supported options are [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events) and [WebSocket](https://en.wikipedia.org/wiki/WebSocket). There is multiple ways how you can create subscription for given events.

## Manual subscriptions

Subscription is created by calling HTTP endpoint:

```
Method: PUT
Url: `/connection/sse/:connectionToken/subscriptions`
Body: { "subscriptions": [{ "eventType": "example-event-type" }] }
```

`connectionToken` is provided by initial SSE/WS connection call, thus it's recommended to save it somewhere. In body you provide which event types to listen to (notice it's an array). After successful you'll get all events with given event type(s).

## Constraints & extractors

To be more restrictive in who should receive what event you can leverage from constraints and extractors. Extractors are set on RIG describing how to match events to clients -- to be more specific where to look for values. As an example _check `name` field in event_. This can be set as an environment variable (string or JSON file). Constraints are set on client side providing exact value to look for in filtering -- for example `John`. Combining with extractor example RIG will try to find `John` in event -- if found event is forwarded to client.

Extractor example:

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

Environment variable:

```
EXTRACTORS=my-extractor.json
```

Constraints example (in subscription call):

```json
{
  "subscriptions": [
    {
      "eventType": "example",
      "oneOf": [
        {
          "name": "John"
        }
      ]
    }
  ]
}
```

## Auth

Authentication can be turned on by setting environment variables:

```
SUBSCRIPTION_CHECK=jwt_validation
JWT_SECRET_KEY=secret
```

JWT needs to be in form of `Bearer eyJh...`.

## Inferred subscriptions

There is also possibility to create subscription automatically (without calling subscription endpoint above) -- inferring from JWT. This behavior is triggered right away in first connection call. Event types to be subscribed to are inferred from extractors, thus it's needed to set them up.

Extractors example:

```json
{
  "greeting": {
    "name": {
      "stable_field_index": 1,
      "jwt": {
        "json_pointer": "/username"
      },
      "event": {
        "json_pointer": "/data/name"
      }
    }
  },
  "example": {
    "fullname": {
      "stable_field_index": 1,
      "jwt": {
        "json_pointer": "/fullname"
      },
      "event": {
        "json_pointer": "/data/fullname"
      }
    }
  }
}
```

This would lead to subscription to event types - `greeting` and `example`.

Environment variable:

```
EXTRACTORS=my-extractor.json
```

Connection call (client side):

```js
new EventSource(`/connection/sse?jwt=${jwt}`)
```
