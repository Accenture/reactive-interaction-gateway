'use strict';

const kafka = require('no-kafka');

const KAFKA_HOSTS = process.env.KAFKA_HOSTS || 'localhost:9092';
const KAFKA_SOURCE_TOPICS = process.env.KAFKA_SOURCE_TOPICS || 'example';

const kafkaProducer = (message) => {
    const producer = new kafka.Producer({
        connectionString: KAFKA_HOSTS,
    });

    const stringMessageValue = JSON.stringify(message);

    return producer.init()
        .then(() => {
            const data = {
                topic: KAFKA_SOURCE_TOPICS,
                message: {
                    value: stringMessageValue,
                },
            };

            return producer.send(data);
        })
        .then((result) => {
            console.log(`Message successfully produced to Kafka ${JSON.stringify(result)}`);
            producer.end();
            return result;
        })
        .catch((e) => {
            console.log(`Could not produce message to topic ${KAFKA_SOURCE_TOPICS}`);
            console.log(e);
            producer.end();
            return e;
        });
};

exports.produce = {
    handler: (request, reply) => {
        const msg = request.payload;

        kafkaProducer(msg)
        .then(message => reply({ status: 'ok', message }))
        .catch(message => reply({ status: 'error', message }));
    },
};
