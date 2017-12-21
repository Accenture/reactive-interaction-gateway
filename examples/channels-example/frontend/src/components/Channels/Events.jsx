import React, { PureComponent } from 'react';
import PropTypes from 'proptypes';

class Events extends PureComponent {

  noSubscription() {
    return (<p className="notification is-warning">You are not subscribed to any topic.</p>);
  }

  errorSubscription() {
    const { subscriberTopic, response } = this.props;
    return (<p className="notification is-danger">Couldn't subscribe to <strong>{subscriberTopic}</strong> topic. Error <strong>{response}</strong>.</p>);
  }

  existingSubscription() {
    const { subscriberTopic } = this.props;
    return (<p className="notification is-success">You are now subscribed to <strong>{subscriberTopic}</strong> topic. Try to send some event.</p>);
  }

  render() {
    const { events, status, clearEventLog } = this.props;
    const notification = <div>
      {(() => {
        switch (status) {
          case 'ok':    return this.existingSubscription();
          case 'error': return this.errorSubscription();
          default:      return this.noSubscription();
        }
      })()}
    </div>

    return (
      <div>
        {notification}

        <div className="box" style={{height: '435px', overflowY: 'auto'}}>
          {events.map((ev, index) => {
            const {username, timestamp} = ev;
            const time = new Date(timestamp).toISOString().slice(-13, -5);
            return (
              <div key={index}>
                <div>{time}: {username} - <code>{JSON.stringify(ev)}</code></div>
                <hr />
              </div>
            );
          })}
        </div>

        <div className="buttons is-right">
          <button
            className="button is-primary"
            onClick={clearEventLog}
            >
            Clear event log
          </button>
        </div>
      </div>
    );
  }
}

Events.props = {
  events: PropTypes.array,
  subscriberTopic: PropTypes.string,
  status: PropTypes.string,
  response: PropTypes.string,
  clearEventLog: PropTypes.func.isRequired
};

Events.defaultProps = {
  events: [],
  subscriberTopic: '',
  status: 'None',
  response: '',
};

export default Events;
