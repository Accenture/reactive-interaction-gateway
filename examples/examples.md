# Simple examples

## basic public SSE

examples/sse-demo.html

```bash
mix phx.server
```

## basic public SSE with constraints

examples/sse-demo-simple-extractors.html

examples/simple-extractor.json

```bash
EXTRACTORS=examples/simple-extractor.json \
mix phx.server
```

## basic SSE with JWT auth

examples/sse-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

## basic public SSE with constraints & JWT

via create subscription call: examples/sse-demo-jwt-extractors.html
via initial connection: examples/sse-demo-jwt-extractors-conn.html

examples/jwt-extractor.json

```bash
EXTRACTORS=examples/jwt-extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server
```

## basic public WS

examples/ws-demo.html

```bash
mix phx.server
```

## basic public WS with constraints

examples/ws-demo-simple-extractors.html

examples/simple-extractor.json

```bash
EXTRACTORS=examples/simple-extractor.json \
mix phx.server
```

## basic WS with JWT auth

examples/ws-demo-jwt.html

```bash
SUBSCRIPTION_CHECK=jwt_validation \
JWT_SECRET_KEY=secret \
mix phx.server
```

## basic public WS with constraints & JWT

via create subscription call: examples/ws-demo-jwt-extractors.html
via initial connection: examples/ws-demo-jwt-extractors-conn.html

examples/jwt-extractor.json

```bash
EXTRACTORS=examples/jwt-extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server
```
