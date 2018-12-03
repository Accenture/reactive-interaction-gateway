import React, { Component } from 'react';
import Channels from './components/Channels/Channels';
import Message from './components/Channels/Message';
import 'bulma/css/bulma.css';

class App extends Component {
  render() {
    return (
      <div>
        <section className="hero is-link">
          <div className="hero-body">
            <div className="container">
              <h1 className="title">
                Reactive Interaction Gateway Events Example
              </h1>
            </div>
          </div>
        </section>
        <div className="section has-text-left">
          <Channels />
          <Message />
        </div>
      </div>
    );
  }
}

export default App;
