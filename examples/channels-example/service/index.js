'use strict';

const Hapi = require('hapi');
const kafkaRoutes = require('./kafka/kafka-routes');

const port = 8000;
const server = new Hapi.Server();

server.connection({ port });
server.route(kafkaRoutes);

server.start((error) => {
    if (error) {
        throw error;
    }

    console.log(`Server running at: ${server.info.uri}`);
});
