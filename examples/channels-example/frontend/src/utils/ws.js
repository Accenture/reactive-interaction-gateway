import { Socket } from 'phoenix';
import { getJwtToken } from './services';

export class Ws {

    /**
     * Creates Websocket connection, subscribes to user's Phoenix channel
     * @param  {string} username
     * @param  {string} levels
     * @param  {string} subscriberTopic
     * @param  {function} cb
     */
    connect(username, levels, subscriberTopic, cb) {

        // Transforms comma separated string to array of strings
        const levelsArray = levels.split(',');
        // Generates JWT using required fields
        const token = getJwtToken(username, levelsArray);

        // Creates Websocket connection
        this.socket = new Socket('/socket', { params: { token } });
        this.socket.connect();

        // Subscribes to user's Phoenix channel
        this.userChannel = this.socket.channel(`user:${subscriberTopic}`);
        this.userChannel.join();

        // Wait for RIG's Phoenix channel reply and executes callback
        this.userChannel.on('phx_reply', ({ status, response }) => {
            cb({ status, response });
        });

        return this;
    }

    listenForUserMessage(cb) {
        // Listener for all messages on given Phoenix channel
        this.userChannel.on('message', cb);
    }

    disconnect(subscriberTopic, cb) {
        // Unsubscribe from Phoenix channel
        this.socket.channel(`user:${subscriberTopic}`).leave();
        this.socket.reconnectTimer.reset();
        // Remove Websocket connection
        this.socket.disconnect();
        cb('None');
    }
}

export default new Ws();