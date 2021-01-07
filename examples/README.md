# Simple examples

Following examples are show casing using of live updates via Server-sent events (SSE), Longpolling (LP) and Websocket (WS). Shows how to use public as well as private delivery.

## SSE

### Example 1: SSE

This example shows simplest scenario when all messages will arrive to UI.

> examples/sse-1-demo.html

```bash
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments

> `sse-demo-single-call` is the same, just doing connection and subscriptions in a single call.

### Example 2: SSE with constraints

This example shows basic restriction with extractors based on sent data.

> examples/sse-2-demo-simple-extractors.html
> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
mix phx.server
```

**Steps:**

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

### Example 3: SSE with JWT auth

This example shows simple scenario when all messages will arrive to UI, but RIG will do JWT auth.

> examples/sse-3-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments
- You can try comment out line `85` in examples/sse-demo-jwt.html => after page refresh you'll see 403 error in console and no message will arrive

### Example 4: SSE with constraints & JWT

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

### Example 1: WS

This example shows simplest scenario when all messages will arrive to UI.

> examples/ws-1-demo.html

```bash
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments

> `ws-demo-single-call` is the same, just doing connection and subscriptions in a single call.

### Example 2: WS with constraints

This example shows basic restriction with extractors based on sent data.

> examples/ws-2-demo-simple-extractors.html
> examples/extractor.json

```bash
EXTRACTORS=examples/extractor.json \
mix phx.server
```

**Steps:**

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

### Example 3: WS with JWT auth

This example shows simple scenario when all messages will arrive to UI, but RIG will do JWT auth.

> examples/ws-3-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments
- You can try comment out line `85` in examples/sse-demo-jwt.html => after page refresh you'll see 403 error in console and no message will arrive

### Example 4: WS with constraints & JWT

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

## LP

The main difference with LP is, that it's using cookies and thus requires proper domain (e.g. `127.0.0.1`). We can't just open html file in browser. For that we have small NodeJS server - `examples/staticServer.js`. HTML is accessible at <http://127.0.0.1:8080/>.

### Example 1: LP

This example shows simplest scenario when all messages will arrive to UI.

> examples/lp-1-demo.html

```bash
node staticServer.js

CORS="http://127.0.0.1:8080" \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments

> `lp-demo-single-call` is the same, just doing connection and subscriptions in a single call. You can try it out with `node staticServer.js ./lp-demo-single-call.html`

### Example 2: LP with constraints

This example shows basic restriction with extractors based on sent data.

> examples/lp-2-demo-simple-extractors.html
> examples/extractor.json

```bash
node staticServer.js ./lp-2-demo-simple-extractors.html

CORS="http://127.0.0.1:8080" \
EXTRACTORS=examples/extractor.json \
mix phx.server
```

**Steps:**

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

### Example 3: LP with JWT auth

This example shows simple scenario when all messages will arrive to UI, but RIG will do JWT auth.

> examples/lp-3-demo-jwt.html

```bash
node staticServer.js ./lp-3-demo-jwt.html

CORS="http://127.0.0.1:8080" \
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

- Fill some message to `greeting` input => update should be displayed below after few moments
- You can try comment out line `85` in examples/sse-demo-jwt.html => after page refresh you'll see 403 error in console and no message will arrive

### Example 4: LP with constraints & JWT

This example shows combination of restrictions with extractors and JWT auth check. Second scenario also shows automatic subscription to events based on JWT during connection phase.

> examples/jwt-extractor.json

```bash
node staticServer.js ./lp-demo-jwt-extractors.html

CORS="http://127.0.0.1:8080" \
EXTRACTORS=examples/extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server
```

**Steps:**

> via create subscription call: examples/lp-demo-jwt-extractors.html

- Fill `john` to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive

> via initial connection: examples/lp-demo-jwt-extractors-conn.html

```bash
node staticServer.js ./lp-demo-jwt-extractors-conn.html

...
```

This time we are not calling subscription call, but they are automatically created from JWT when connection happens.

- Fill `john.doe` (this is set in JWT) to first input and some message to second input => update should be displayed below after few moments
- Fill any other name to first input => this time no update should arrive
