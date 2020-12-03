# Artillery

[Artillery](https://artillery.io/) is a load (performance) testing tool based on the JavaScript.

## Scenarios

### Connections per minute

Establishes 4_500 connection per minute, each connection stays alive for 15 seconds.

```bash
# ws
npm run connections:ws
# sse
npm run connections:sse
```
