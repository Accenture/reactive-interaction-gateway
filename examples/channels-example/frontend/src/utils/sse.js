import { getJwtToken } from './services';

export class Sse {

    /**
     * Creates SSE connection, subscribes to user's Phoenix channel
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

        // Creates SSE connection and subscribes to user's Phoenix channel
        this.socket = new EventSource(`/socket/sse?auth_token=${token}`);

        // Wait for RIG's Phoenix channel reply and executes callback
        this.socket.addEventListener('connection established', () => {
            cb({ status: "ok", response: "connection established" });
        });

        return this;
    }

    listenForUserMessage(cb) {
        // Listener for all messages on given Phoenix channel
        this.socket.onmessage = ({ data }) => {
            const message = JSON.parse(data);
            cb(message);
        };
    }

    disconnect(subscriberTopic, cb) {
        // Unsubscribe from Phoenix channel and remove SSE connection
        this.socket.close();
        cb('None');
    }
}

export default new Sse();
