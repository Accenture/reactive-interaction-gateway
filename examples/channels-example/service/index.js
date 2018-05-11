'use strict';

const Hapi = require('hapi');
const kafkaRoutes = require('./kafka/kafka-routes');

const port = 8000;
const server = new Hapi.Server({ port });

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
