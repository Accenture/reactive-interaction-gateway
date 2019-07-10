import { getJwtToken } from './services';

export class Sse {
  /**
   * Create SSE connection
   * @param  {string} username
   * @param  {string} subscriberEvent
   * @param  {function} cb
   */
  connect(username, subscriberEvent, cb) {
    // Generate JWT using required fields
    const token = getJwtToken(username);

    // Create SSE connection
    this.socket = new EventSource(
      `http://localhost:7000/_rig/v1/connection/sse?jwt=${token}`
    );

    // Wait for RIG's reply and execute callback
    this.socket.addEventListener('rig.connection.create', e => {
      const cloudEvent = JSON.parse(e.data);
      const payload = cloudEvent.data;
      const connectionToken = payload['connection_token'];
      // we don't want to subscribe to inferred event, otherwise we get 2 subscriptions
      if (subscriberEvent !== 'message') {
        this.createSubscription(connectionToken, subscriberEvent, token);
      }

      cb({ status: 'ok', response: 'connection established' });
    });

    return this;
  }

  createSubscription(connectionToken, subscriberEvent, token) {
    return fetch(
      `http://localhost:7000/_rig/v1/connection/sse/${connectionToken}/subscriptions`,
      {
        method: 'PUT',
        mode: 'cors',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          subscriptions: [{ eventType: subscriberEvent }]
        })
      }
    )
      .then(json => {
        console.log('Subscriptions created:', json);
        return json;
      })
      .catch(err => {
        console.log('Failed to create subscription:', err);
      });
  }

  listenForUserMessage(subscriberEvent, cb) {
    // Listener for all messages
    // this.socket.onmessage = ({ data }) => {
    //   const message = JSON.parse(data);
    //   cb(message);
    // };

    this.socket.addEventListener(subscriberEvent, ({ data }) => {
      const message = JSON.parse(data);
      cb(message);
    });
  }

  disconnect(cb) {
    // Close SSE connection
    this.socket.close();
    cb('None');
  }
}

export default new Sse();
