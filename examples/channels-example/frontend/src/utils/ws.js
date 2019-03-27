import { getJwtToken } from './services';

export class Ws {
  /**
   * Creates Websocket connection
   * @param  {string} username
   * @param  {string} subscriberEvent
   * @param  {function} cb
   */
  connect(username, subscriberEvent, cb) {
    // Generate JWT using required fields
    const token = getJwtToken(username);

    // Creates Websocket connection
    this.socket = new WebSocket(`ws://localhost:7000/_rig/v1/connection/ws?jwt=${token}`);

    this.socket.onmessage = e => {
      const cloudEvent = JSON.parse(e.data);
      if (cloudEvent.type === 'rig.connection.create') {
        const payload = cloudEvent.data;
        const connectionToken = payload['connection_token'];
        // we don't want to subscribe to inferred event, otherwise we get 2 subscriptions
        if (subscriberEvent !== 'message') {
          this.createSubscription(connectionToken, subscriberEvent, token);
        }

        cb({ status: 'ok', response: 'connection established' });
      }
    };

    return this;
  }

  createSubscription(connectionToken, subscriberEvent, token) {
    return fetch(
      `http://localhost:7000/_rig/v1/connection/ws/${connectionToken}/subscriptions`,
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
    this.socket.onmessage = ({ data }) => {
      const cloudEvent = JSON.parse(data);
      if (
        cloudEvent.eventType === 'message' ||
        cloudEvent.eventType === subscriberEvent
      ) {
        cb(cloudEvent);
      }
    };
  }

  disconnect(cb) {
    // Remove Websocket connection
    this.socket.close();
    cb('None');
  }
}

export default new Ws();
