'use strict';

const kafkaController = require('./kafka-ctrl');

module.exports = [
    {
        method: 'POST',
        path: '/produce',
        config: kafkaController.produce,
    },
];
