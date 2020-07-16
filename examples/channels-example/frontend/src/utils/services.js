import { sign } from 'jsonwebtoken';
import { JWT_SECRET_KEY } from '../constants';

const randomString = () => {
  return (
    Math.random()
      .toString(36)
      .substring(2, 15) +
    Math.random()
      .toString(36)
      .substring(2, 15)
  );
};

/**
 * Generates JWT with required fields
 * @param   {string} username
 * @returns {string} generated JWT
 */
export const getJwtToken = username => {
  // Populates claims with required fields
  const claims = { username };

  return sign(claims, JWT_SECRET_KEY, { expiresIn: '60m' });
};

/**
 * Calls external service which produces message to Kafka
 * @param   {object} data
 * @returns {promise}
 */
export const produceKafkaMessageAsync = (subscriberEvent, data) => {
  return fetch('/produce', {
    method: 'POST',
    body: JSON.stringify({
      cloudEventsVersion: '0.1',
      eventID: randomString(),
      eventType: subscriberEvent,
      source: 'events-example-ui',
      contentType: 'text/plain',
      // RIG will simply forward this traceparent to the backend
      // As the backend of this example simply takes the message and produces an event back to Kafka (which will be consequently read by RIG),
      // RIG will also create a new span out of this trace context then and emits it in the outgoing events
      traceparent: '00-15aa5a4ee009a477e7e1430b08551c6c-08833e446a3adb55-01',
      data
    }),
    // RIG reads this traceparent from the header and creates a new span out of it
    // RIG will additionally be able to forward the ne trace context as Kafka header in issue #311
    headers: { 'Content-Type': 'application/json', 'traceparent': '00-39fb839b1d9a53e8a5e0306526669021-8472fb1fee6307e5-01' } 
  }).then(response => response.json());
};
