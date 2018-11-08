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
            producer.end();

            const { error } = result[0];
            if (error) {
                return error;
            }

            console.log(`Message successfully produced to Kafka ${JSON.stringify(result)}`);
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
    handler: (request) => {
        const msg = request.payload;

        return kafkaProducer(msg)
            .then(message => ({ status: 'ok', message }))
            .catch(message => ({ status: 'error', message }));
    },
};
