import React, { PureComponent } from 'react';
import { produceKafkaMessageAsync } from '../../utils/services';

class Message extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      message: '',
      callStatus: null,
      sendEventType: ''
    };
  }

  handleProduceKafkaMessage = () => {
    const { message, sendEventType } = this.state;
    const messageJSON = JSON.parse(message);
    // Add timestamp to each message, just to have nicer format of messages in UI
    const updatedMessage = Object.assign(messageJSON, {
      timestamp: Date.now()
    });

    produceKafkaMessageAsync(sendEventType, updatedMessage)
      .then(res => this.setState({ callStatus: res }))
      .catch(res => this.setState({ callStatus: res }));
  };

  handleInputChange = ev => {
    const { name, value } = ev.target;
    const newState = Object.assign({}, this.state);
    newState[name] = value;

    this.setState(newState);
  };

  errorCall(message) {
    return (
      <p className="notification is-danger">
        Couldn't call REST API. Error <strong>{message}</strong>.
      </p>
    );
  }

  successCall(message) {
    return (
      <p className="notification is-success">
        Successful REST API call. Response <strong>{message}</strong>.
      </p>
    );
  }

  render() {
    const { callStatus } = this.state;

    const notification = (
      <div>
        {(() => {
          if (!callStatus) {
            return null;
          }

          const messageString = JSON.stringify(callStatus.message);

          if (callStatus.status === 'ok') {
            return this.successCall(messageString);
          }
          return this.errorCall(messageString);
        })()}
      </div>
    );

    return (
      <div>
        <div className="field">
          <label className="label" htmlFor="sendEventType">
            Set event type
          </label>
          <div className="control">
            <input
              className="input"
              type="text"
              name="sendEventType"
              placeholder="message"
              onChange={this.handleInputChange}
            />
          </div>
          <p className="help">
            This will set event type for event and only users subscribed to it
            will receive this event.
          </p>
        </div>
        <div className="field">
          <label className="label" htmlFor="message">
            Event message
          </label>
          <div className="control">
            <input
              className="input"
              type="text"
              name="message"
              onChange={this.handleInputChange}
              placeholder={`{"name":"username","foo":"bar"}`}
            />
          </div>
          <p className="help">
            Construct message that will be sent to Kafka, consumed by RIG and
            distributed to all subscribers of the given event type.{' '}
            <strong>
              Example: <code>&#123;"name":"username","foo":"bar"&#125;</code>
            </strong>
          </p>
        </div>

        <div className="buttons is-right">
          <button
            className="button is-primary"
            onClick={this.handleProduceKafkaMessage}
          >
            Send event
          </button>
        </div>

        {notification}
      </div>
    );
  }
}

export default Message;
