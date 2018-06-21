---
id: getting-started
title: Getting started
sidebar_label: Getting started
---

Setting up your dev environment is easier than you think! We're trying hard to make the developer experience as frictionless as possible. If you still think it's too complicated, please open a Github issue!

## Setting up your development environment

> NOTE: This does not quite work like that, but we're getting there..
> What's missing:
> - The local-development Docker image is not there yet. [#73](https://github.com/Accenture/reactive-interaction-gateway/issues/73)
> - The SSE endpoint requires the JWT set up in advance and supplied when connecting. [#66](https://github.com/Accenture/reactive-interaction-gateway/pull/66)
> - The subscriptions endpoint.

The easiest and recommended way to get started is using [Docker](https://www.docker.com):

```bash
$ docker run -d -p 4000:4000 -p 4010:4010 accenture/reactive-interaction-gateway:latest-local-development-only
```

This runs an instance of RIG in its _local-development_ mode. The local-development mode makes it easy to get started, but please, **don't run this in production**.

RIG is now ready to accept frontend connections. Let's connect to RIG using [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events), which is our recommended approach (open standard, firewall friendly, plays nice with HTTP/2). Add this code to your frontend:

```javascript
const source = new EventSource("http://localhost:4000/socket/sse");

source.addEventListener("open", event => {
  console.log("Connection opened.")
}, false);

source.addEventListener("connection established", event => {
  console.log("RIG is now forwarding events.")
}, false);

source.addEventListener("message", event => {
  console.log("Forwarded message:", event.data);
}, false);

source.addEventListener("error", event => {
  if (event.readyState == EventSource.CLOSED) {
    console.log("Connection was closed.")
  } else {
    console.log("Connection error:", e)
  }
}, false);

// source.onmessage = event => {
//   console.log("This would be invoked for any message type:", event.data)
// };
```

This hooks you up the the event stream, but there are no subscriptions yet. Let's change this (using [axios](https://github.com/axios/axios) for making the request):

```javascript
axios.post("http://localhost:4000/socket/subscriptions", {
  topic: "public:lobby"
})
```

Since we don't send an authorization token yet (we're not logged in or anything), we're only allowed to subscribe to "public" topics. RIG doesn't know anything about which topic is used for what purpose, but by convention it will deny access to any topic that doesn't start with "public:", unless the request carries an authorization token. To learn more about this token and what it's used for, take a look at the next section.
