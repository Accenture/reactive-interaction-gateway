const proxy = require('http-proxy-middleware');

module.exports = (app) => {
  app.use(proxy('/*', { target: 'http://localhost:7000', ws: true }));
};
