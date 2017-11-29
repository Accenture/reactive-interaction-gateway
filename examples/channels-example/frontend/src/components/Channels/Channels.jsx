import React, { PureComponent } from 'react';
import ws from '../../utils/ws';
import sse from '../../utils/sse';
import { PRIVILEGED_ROLES } from '../../constants';
import Events from './Events';

class Channels extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      protocols: { ws, sse },
      type: 'ws',
      username: '',
      levels: '',
      subscriberTopic: '',
      status: 'None',
      response: '',
      messages: []
    };

    this.connectToChannel = this.connectToChannel.bind(this);
    this.disconnectFromChannel = this.disconnectFromChannel.bind(this);
    this.clearEventLog = this.clearEventLog.bind(this);
    this.handleInputChange = this.handleInputChange.bind(this);
  }

  connectToChannel() {
    const { type, username, levels, subscriberTopic, protocols } = this.state;
    // Choose one of the imported protocol types (ws, sse), controlled by radio buttons
    const channels = protocols[type];

    // Create WS/SSE connection and join to user's Phoenix channel
    channels.connect(username, levels, subscriberTopic, ({ status, response }) => {
      // Listen to broadcasted messages in connected Phoenix channel
      channels.listenForUserMessage((message) => {
        const updatedMessages = [message, ...this.state.messages];
        this.setState({ messages: updatedMessages });
      });

      this.setState({ status, response });
    });
  }

  disconnectFromChannel() {
    const { type, protocols, subscriberTopic } = this.state;
    // Choose one of the imported protocol types (ws, sse), controlled by radio buttons
    const channels = protocols[type];

    // Unsubscribe from user's Phoenix channel and close WS/SSE connection
    channels.disconnect(subscriberTopic, () => {
      this.setState({ status: 'None' });
    });
  }

  clearEventLog() {
    this.setState({ messages: [] });
  }

  handleInputChange(ev) {
    const { name, value } = ev.target;
    const newState = Object.assign({}, this.state);;
    newState[name] = value;

    this.setState(newState);
  }

  render() {
    const { type, status, response, messages, subscriberTopic } = this.state;

    return (
      <div className="columns">
        <div className="column is-two-fifths">
          <div className="field">
              <label className="label" htmlFor="username">Transport protocol type</label>
              <label className="radio" htmlFor="ws">
                <input
                  type="radio"
                  name="type"
                  value="ws"
                  checked={type === 'ws'}
                  onChange={this.handleInputChange}
                  /> Websockets
              </label>

              <label className="radio" htmlFor="sse">
                <input
                  type="radio"
                  name="type"
                  value="sse"
                  checked={type === 'sse'}
                  onChange={this.handleInputChange}
                  /> Server Sent Events
              </label>
              <p className="help">
                Type of transport protocol by which we can establish connection to RIG and communicate via Phoenix channels.
              </p>
          </div>

          <div className="field">
            <label className="label" htmlFor="username">User Name</label>
            <div className="control">
              <input
                className="input"
                type="text"
                name="username"
                placeholder="Example: mike"
                onChange={this.handleInputChange}
                />
            </div>
            <p className="help">User ID used in JWT claims to be able to recognize user. This is mandatory field for RIG's Phoenix channels authentication.</p>
          </div>

          <div className="field">
            <label className="label" htmlFor="levels">Levels</label>
            <div className="control">
              <input
                className="input"
                type="text"
                name="levels"
                placeholder="Example 1: lowlevel or Example 2: lowlevel,admin"
                onChange={this.handleInputChange}
                />
            </div>
            <p className="help">Privilegies by which RIG's Phoenix channels know if you can subscribe just to your channels or to all channels, with <strong>{PRIVILEGED_ROLES}</strong> level you can subscribe to all channels. <strong>Enter comma separated strings or leave empty.</strong></p>
          </div>

          <div className="field">
            <label className="label" htmlFor="subscriberTopic">Subscribe to topic</label>
            <div className="control">
              <input
                className="input"
                type="text"
                name="subscriberTopic"
                placeholder="Example: mike"
                onChange={this.handleInputChange}
                />
            </div>
            <p className="help">Set to which channel you want to subscribe. Without <strong>{PRIVILEGED_ROLES}</strong> level you can join only to your channels. Phoenix channel topic name is constructed from this value. <strong>If username in JWT doesn't match Phoenix channel topic name and you don't have priviliged role, your subscription will be denied.</strong></p>
          </div>

          <div className="buttons is-right">
            <button
              className={`button is-primary ${status === 'ok' ? 'is-loading' : ''}`}
              onClick={this.connectToChannel}
              disabled={status === 'ok'}
              >
              Connect
            </button>
            <button
              className="button is-danger"
              onClick={this.disconnectFromChannel}
              disabled={status !== 'ok'}
              >
              Disconnect
            </button>
          </div>
        </div>

        <div className="column is-three-fifths">
          <Events
            events={messages}
            subscriberTopic={subscriberTopic}
            status={status}
            response={response}
            clearEventLog={this.clearEventLog}
            />
        </div>
      </div>
    );
  }
}

export default Channels;
