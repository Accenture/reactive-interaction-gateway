import React, { PureComponent } from 'react';
import ws from '../../utils/ws';
import sse from '../../utils/sse';
import Events from './Events';

class Channels extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      protocols: { ws, sse },
      type: 'ws',
      username: '',
      subscriberEvent: '',
      status: 'None',
      response: '',
      messages: []
    };
  }

  connectToChannel = () => {
    const { type, username, subscriberEvent, protocols } = this.state;
    // Choose one of the imported protocol types (ws, sse), controlled by radio buttons
    const channels = protocols[type];

    // Create WS/SSE connection and join to user's Phoenix channel
    channels.connect(
      username,
      subscriberEvent,
      ({ status, response }) => {
        // Listen to broadcasted messages in connected Phoenix channel
        channels.listenForUserMessage(subscriberEvent, message => {
          const updatedMessages = [message, ...this.state.messages];
          this.setState({ messages: updatedMessages });
        });

        this.setState({ status, response });
      }
    );
  };

  disconnectFromChannel = () => {
    const { type, protocols, subscriberEvent } = this.state;
    // Choose one of the imported protocol types (ws, sse), controlled by radio buttons
    const channels = protocols[type];

    // Close WS/SSE connection - subscriptions are eventually removed as well
    channels.disconnect(() => {
      this.setState({ status: 'None' });
    });
  };

  clearEventLog = () => {
    this.setState({ messages: [] });
  };

  handleInputChange = ev => {
    const { name, value } = ev.target;
    const newState = Object.assign({}, this.state);
    newState[name] = value;

    this.setState(newState);
  };

  render() {
    const { type, status, response, messages, subscriberEvent } = this.state;

    return (
      <div className="columns">
        <div className="column is-two-fifths">
          <div className="field">
            <label className="label" htmlFor="type">
              Transport protocol type
            </label>
            <label className="radio" htmlFor="ws">
              <input
                type="radio"
                name="type"
                value="ws"
                checked={type === 'ws'}
                onChange={this.handleInputChange}
              />{' '}
              Websocket
            </label>

            <label className="radio" htmlFor="sse">
              <input
                type="radio"
                name="type"
                value="sse"
                checked={type === 'sse'}
                onChange={this.handleInputChange}
              />{' '}
              Server-Sent Events
            </label>
            <p className="help">
              Type of transport protocol by which we can establish connection to
              RIG and communicate.
            </p>
          </div>

          <div className="field">
            <label className="label" htmlFor="username">
              User Name
            </label>
            <div className="control">
              <input
                className="input"
                type="text"
                name="username"
                placeholder="Example: mike"
                onChange={this.handleInputChange}
              />
            </div>
            <p className="help">
              Username to be used in JWT claims to be able to recognize user.
              RIG will automatically infer subscriptions from this value (if
              EXTRACTORS are configured in RIG). You can think of it as private
              subscriptions. In this example we'll use event type{' '}
              <strong>message</strong> for this private behavior.
            </p>
          </div>

          <div className="field">
            <label className="label" htmlFor="subscriberEvent">
              Subscribe to public event
            </label>
            <div className="control">
              <input
                className="input"
                type="text"
                name="subscriberEvent"
                placeholder="Example: my.public.event"
                onChange={this.handleInputChange}
              />
            </div>
            <p className="help">
              Set additional event type you want to subscribe to. Events are
              using cloud events specification.
              <strong>
                You'll only get events you are subscribed to either by
                subscription call or inferred from JWT.
              </strong>
            </p>
          </div>

          <div className="buttons is-right">
            <button
              className={`button is-primary ${
                status === 'ok' ? 'is-loading' : ''
              }`}
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
            subscriberEvent={subscriberEvent}
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
