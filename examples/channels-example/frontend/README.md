# Reactive Interaction Gateway Events Example

Frontend that can establish Websocket (WS) or Server Sent Events (SSE) connection to Reactive Interaction Gateway (RIG), calls external service to produce Kafka message and consumes events going to subscribed event types.

## Quick start

```sh
npm i
npm start
```

## Change environment variables

Available values you can setup with env vars. This values should be the same as RIG has. These values are loaded in `constants.js` file. `REACT_APP_` is needed prefix for `create-react-app` project.

```sh
REACT_APP_JWT_SECRET_KEY => default value 'mysecret';
```

## WS/SSE

Code responsible for connecting to WS can be found in `src/utils/ws.js` and to SSE in `src/utils/sse.js`. Protocol types are on purpose divided to two files and done the same way, so you can see the difference in usage.
