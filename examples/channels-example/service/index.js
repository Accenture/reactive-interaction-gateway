'use strict';

const Hapi = require('@hapi/hapi');
const kafkaRoutes = require('./kafka/kafka-routes');

const port = 8000;
const server = Hapi.server({
  port,
});

server.route(kafkaRoutes);

const init = async () => {
  await server.start();
  console.log(`Server running at: ${server.info.uri}`);
};

process.on('unhandledRejection', (err) => {
  console.log(err);
  process.exit(1);
});

init();
