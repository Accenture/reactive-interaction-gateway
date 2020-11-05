module.exports = { createTimestampedObject };

function createTimestampedObject(userContext, events, done) {
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
