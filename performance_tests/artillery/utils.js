const EventSource = require('eventsource');

const CONNECTION_CREATE_EVENT = 'rig.connection.create';

module.exports = { connectToWS, connectToSSE };

function createHistogram(events, start, description) {
  events.emit('histogram', description, new Date() - start);
}

function connectToWS(userContext, events, done) {
  const start = new Date();
  userContext.ws.onmessage = (e) => {
    const ce = JSON.parse(e.data);
    if (ce.type === CONNECTION_CREATE_EVENT) {
      createHistogram(events, start, 'Websocket connection time (msec)');
      done();
    }
  };
}

function connectToSSE(userContext, events, done) {
  const source = new EventSource(
    'http://localhost:4000/_rig/v1/connection/sse'
  );
  const start = new Date();
  source.addEventListener(
    CONNECTION_CREATE_EVENT,
    function (e) {
      createHistogram(events, start, 'SSE connection time (msec)');
      done();
    },
    false
  );
}
