const http = require('http');
const querystring = require('querystring');
const axios = require('axios');

const port = 3000;
const RIG_RESPONSE_URL =
  process.env.RIG_RESPONSE_URL || 'http://localhost:4010/v3/responses';
const RIG_VERSION = process.env.RIG_VERSION || '3.0.0';

// used timeout to artificially introduce some delay
const sendResponseToRig = (correlation) => {
  let options = {};

  switch (RIG_VERSION) {
    case '2.4.0':
      options = {
        method: 'POST',
        data: {
          id: '1',
          specversion: '0.2',
          source: 'my-service',
          type: 'com.example',
          rig: {
            correlation,
          },
          data: {
            foo: { bar: 'baz' },
          },
        },
        url: RIG_RESPONSE_URL,
      };
      break;

    default:
      options = {
        method: 'POST',
        headers: { 'rig-correlation': correlation, 'rig-response-code': '200' },
        data: {
          foo: {
            bar: 'baz',
          },
        },
        url: RIG_RESPONSE_URL,
      };
      break;
  }

  setTimeout(async () => {
    await axios(options);
  }, 3000);
};

const handler = (req, res) => {
  console.log(`Request URL: ${req.url}`);
  const correlation = querystring.parse(req.url)['/foo?correlation'];
  console.log(`correlation ID: ${correlation}`);

  // not resolving promise on purpose to let finish the initial request from RIG
  sendResponseToRig(correlation);

  res.statusCode = 202;
  res.end("Hi, I'm a demo service!\n");
};

const server = http.createServer(handler);

server.listen(port, (err) => {
  if (err) {
    return console.error(err);
  }
  console.log(`server is listening on ${port}`);
});
