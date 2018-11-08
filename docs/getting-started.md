---
id: getting-started
title: Getting started
sidebar_label: Getting started
---

Setting up your dev environment is easier than you think! We're trying hard to make the developer experience as frictionless as possible. If you still think it's too complicated, please open a Github issue!

## Setting up your development environment

The easiest and recommended way to get started is using [Docker](https://www.docker.com):

```bash
$ docker run -d -p 4000:4000 -p 4010:4010 accenture/reactive-interaction-gateway
```

This runs an instance of RIG in its _local-development_ mode. The local-development mode makes it easy to get started, but please, **don't run this in production**.

RIG is now ready to accept frontend connections. Let's connect to RIG using [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events), which is our recommended approach (open standard, firewall friendly, plays nice with HTTP/2). Add this code to your frontend:

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
  const { eventType } = cloudEvent.data
  console.log(`Now subscribed to ${eventType}`)
}, false)

source.addEventListener("greeting", function (e) {
  console.log("Got a greeting!")
}, false)
```

Since we don't send an authorization token yet (we're not logged in or anything), we're only allowed to subscribe to "public" topics. RIG doesn't know anything about which topic is used for what purpose, but by convention it will deny access to any topic that doesn't start with "public:", unless the request carries an authorization token. To learn more about this token and what it's used for, take a look at the next section.
