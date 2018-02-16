const express = require('express');
const kafka = require('no-kafka');
const logger = require('winston');

const router = express.Router();

const KAFKA_HOSTS = process.env.KAFKA_HOSTS || 'localhost:9092';
const KAFKA_SOURCE_TOPICS = process.env.KAFKA_SOURCE_TOPICS || 'rig';

const kafkaProducer = async (message) => {
    const producer = new kafka.Producer({
        connectionString: KAFKA_HOSTS,
    });

    const stringMessageValue = JSON.stringify(message);

    try {
        await producer.init();

        const data = {
            topic: KAFKA_SOURCE_TOPICS,
            message: {
                value: stringMessageValue,
            },
        };

        const result = await producer.send(data);
        logger.info(`Message successfully produced to Kafka ${JSON.stringify(result)}`);
        return result;
    } catch (error) {
        logger.info(`Could not produce message to topic ${KAFKA_SOURCE_TOPICS}`);
        throw error;
    } finally {
        producer.end();
    }
};

router.post('/produce', async (req, res) => {
    const msg = req.body;

    try {
        const response = await kafkaProducer(msg);
        res.send({ msg: response });
    } catch (error) {
        res.status(500).send({ error });
    }
});

module.exports = router;
