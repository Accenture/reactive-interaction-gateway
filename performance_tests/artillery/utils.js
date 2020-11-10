const EventSource = require('eventsource');

module.exports = { connectToWS, connectToSSE };

function connectToWS(userContext, events, done) {
  const start = new Date();
  userContext.ws.onmessage = (e) => {
    const ce = JSON.parse(e.data);
    if (ce.type === 'rig.connection.create') {
      events.emit(
        'histogram',
        'Websocket connection time (msec)',
        new Date() - start
      );
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
    'rig.connection.create',
    function (e) {
      events.emit(
        'histogram',
        'SSE connection time (msec)',
        new Date() - start
      );
      done();
    },
    false
  );
}
