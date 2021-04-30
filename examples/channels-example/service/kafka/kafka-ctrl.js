'use strict';

const { Kafka } = require('kafkajs');

const KAFKA_HOSTS = process.env.KAFKA_HOSTS || 'localhost:9092';
const KAFKA_SOURCE_TOPICS = process.env.KAFKA_SOURCE_TOPICS || 'example';

const kafka = new Kafka({
  clientId: 'channel-service',
  brokers: [KAFKA_HOSTS],
});
const producer = kafka.producer();

exports.produce = {
  handler: async (request) => {
    const msg = request.payload;

    try {
      await producer.connect();
      await producer.send({
        topic: KAFKA_SOURCE_TOPICS,
        messages: [{ value: JSON.stringify(msg) }],
      });
      await producer.disconnect();
      console.log('Message successfully produced to Kafka');

      return { status: 'ok' };
    } catch (error) {
      console.error('Failed to produce message to Kafka', error);
      return { status: 'error', message: error };
    }
  },
};
