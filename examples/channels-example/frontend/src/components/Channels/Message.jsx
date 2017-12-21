import React, { PureComponent } from 'react';
import { produceKafkaMessageAsync } from '../../utils/services';
import { KAFKA_USER_FIELD } from '../../constants';

class Message extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      message: '',
      callStatus: null
    };
  }

  handleProduceKafkaMessage = () => {
    const { message } = this.state;
    const messageJSON = JSON.parse(message);
    // Add timestamp to each message, just to have nicer format of messages in UI
    const updatedMessage = Object.assign(messageJSON, { timestamp: Date.now() } );

    produceKafkaMessageAsync(updatedMessage)
    .then((res) => this.setState({ callStatus: res }))
    .catch((res) => this.setState({ callStatus: res }));
  }

  handleInputChange = (ev) => {
    const { value } = ev.target;

    this.setState({ message: value });
  }

  errorCall(message) {
    return (<p className="notification is-danger">Couldn't call REST API. Error <strong>{message}</strong>.</p>);
  }

  successCall(message) {
    return (<p className="notification is-success">Successful REST API call. Response <strong>{message}</strong>.</p>);
  }

  render() {
    const { callStatus } = this.state;

    const notification = <div>
      {(() => {
        if (!callStatus) { return null; }

        const messageString = JSON.stringify(callStatus.message);

        if (callStatus.status === 'ok') {
          return this.successCall(messageString);
        }
        return this.errorCall(messageString);
      })()}
    </div>

    return (
      <div>
        <div className="field">
          <label className="label" htmlFor="subscriberTopic">Event message</label>
          <div className="control">
            <input
              className="input"
              type="text"
              name="event"
              onChange={this.handleInputChange}
              placeholder={`{"${KAFKA_USER_FIELD}":"mike", "payload":"this field is optional and put here just as an example"}`}
              />
          </div>
          <p className="help">Construct message that will be sent to Kafka, consumed by RIG and distributed to all subcribers of the given Phoenix channel, <strong>{KAFKA_USER_FIELD}</strong> is mandatory field. <strong>Example: <code>&#123;"{KAFKA_USER_FIELD}":"mike", "payload":"rest of the JSON may be whatever you want"&#125;</code></strong></p>
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
