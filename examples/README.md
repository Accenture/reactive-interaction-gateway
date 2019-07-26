# Simple examples

Following examples are show casing using of live updates via Server-sent events (SSE) and Websocket (WS). Shows how to use public as well as private delivery.

## SSE

This example shows simplest scenario when all messages will arrive to UI.

> examples/sse-demo.html

```bash
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments

## SSE with constraints

This example shows basic restriction with extractors based on sent data.

> examples/sse-demo-simple-extractors.html
> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
mix phx.server
```

**Steps:**

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

## SSE with JWT auth

This example shows simple scenario when all messages will arrive to UI, but RIG will do JWT auth.

> examples/sse-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments
- You can try comment out line `85` in examples/sse-demo-jwt.html => after page refresh you'll see 403 error in console and no message will arrive

## SSE with constraints & JWT

This example shows combination of restrictions with extractors and JWT auth check. Second scenario also shows automatic subscription to events based on JWT during connection phase.

> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

> via create subscription call: examples/sse-demo-jwt-extractors.html

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

> via initial connection: examples/sse-demo-jwt-extractors-conn.html

This time we are not calling subscription call, but they are automatically created from JWT when connection happens.

- Fill `john.doe` (this is set in JWT) to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

## WS

This example shows simplest scenario when all messages will arrive to UI.

> examples/ws-demo.html

```bash
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments

## WS with constraints

This example shows basic restriction with extractors based on sent data.

> examples/ws-demo-simple-extractors.html
> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
mix phx.server
```

**Steps:**

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

## WS with JWT auth

This example shows simple scenario when all messages will arrive to UI, but RIG will do JWT auth.

> examples/ws-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments
- You can try comment out line `85` in examples/sse-demo-jwt.html => after page refresh you'll see 403 error in console and no message will arrive

## WS with constraints & JWT

This example shows combination of restrictions with extractors and JWT auth check. Second scenario also shows automatic subscription to events based on JWT during connection phase.

> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

> via create subscription call: examples/ws-demo-jwt-extractors.html

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

> via initial connection: examples/ws-demo-jwt-extractors-conn.html

This time we are not calling subscription call, but they are automatically created from JWT when connection happens.

- Fill `john.doe` (this is set in JWT) to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive
