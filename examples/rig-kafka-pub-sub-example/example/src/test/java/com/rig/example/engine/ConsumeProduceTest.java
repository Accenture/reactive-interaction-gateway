package com.rig.example.engine;

import com.google.gson.Gson;
import com.rig.example.config.KafkaConfig;
import com.rig.example.model.EventBody;
import com.rig.example.model.EventData;
import com.rig.example.model.EventPayload;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.assertj.core.api.Assertions;
import org.junit.After;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.ContainerProperties;
import org.springframework.kafka.listener.KafkaMessageListenerContainer;
import org.springframework.kafka.listener.MessageListener;
import org.springframework.kafka.test.rule.EmbeddedKafkaRule;
import org.springframework.kafka.test.utils.ContainerTestUtils;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.Assert.assertThat;
import static org.springframework.kafka.test.assertj.KafkaConditions.key;
import static org.springframework.kafka.test.hamcrest.KafkaMatchers.hasValue;

@RunWith(SpringRunner.class)
@SpringBootTest
@DirtiesContext
public class ConsumeProduceTest {
    // logger and constants
    private static final Logger LOGGER = LoggerFactory.getLogger(ConsumeProduceTest.class);
    private static String OUTPUT_TOPIC = "rig-consumed";
    private static String INPUT_TOPIC = "rig";

    // components
    @Autowired
    private KafkaListenerEndpointRegistry kafkaListenerEndpointRegistry;

    @Autowired
    private KafkaConfig kafkaConfig;

    @ClassRule
    public static EmbeddedKafkaRule embeddedKafka =
            new EmbeddedKafkaRule(1, true, OUTPUT_TOPIC);

    private KafkaMessageListenerContainer<String, String> container;

    private BlockingQueue<ConsumerRecord<String, String>> records;

    private KafkaTemplate<String, String> mockExternalProducer;

    @Before
    public void setUp() throws Exception {
        // set up the Kafka consumer properties
        Map<String, Object> consumerProperties =
                KafkaTestUtils.consumerProps("sender", "false",
                        embeddedKafka.getEmbeddedKafka());

        // set up the Kafka producer properties
        Map<String, Object> senderProperties =
                KafkaTestUtils.senderProps(
                        embeddedKafka.getEmbeddedKafka().getBrokersAsString());

        // create a Kafka consumer factory
        DefaultKafkaConsumerFactory<String, String> consumerFactory =
                new DefaultKafkaConsumerFactory<String, String>(
                        consumerProperties);

        // create a Kafka producer factory
        ProducerFactory<String, String> producerFactory =
                new DefaultKafkaProducerFactory<String, String>(
                        senderProperties);

        // create a Kafka template
        mockExternalProducer = new KafkaTemplate<>(producerFactory);
        // set the default topic to send to
        mockExternalProducer.setDefaultTopic(INPUT_TOPIC);

        // set the topic that needs to be consumed
        ContainerProperties containerProperties =
                new ContainerProperties(OUTPUT_TOPIC);

        // create a Kafka MessageListenerContainer
        container = new KafkaMessageListenerContainer<>(consumerFactory,
                containerProperties);

        // create a thread safe queue to store the received message
        records = new LinkedBlockingQueue<>();

        // setup a Kafka message listener
        container
                .setupMessageListener(new MessageListener<String, String>() {
                    @Override
                    public void onMessage(
                            ConsumerRecord<String, String> record) {
                        LOGGER.debug("test-listener received message='{}'",
                                record.toString());
                        records.add(record);
                    }
                });

        // start the container and underlying message listener
        container.start();

        // wait until the container has the required number of assigned partitions
        ContainerTestUtils.waitForAssignment(container,
                embeddedKafka.getEmbeddedKafka().getPartitionsPerTopic());
    }

    @After
    public void tearDown() {
        // stop the container
        container.stop();
    }

    @Test
    public void testConsumeAndProduceWithTransformation() throws InterruptedException {
        EventPayload eventPayload = new EventPayload();
        eventPayload.payload = "Payload";
        eventPayload.number  = 2;

        // data set up
        EventData eventData = new EventData();
        eventData.payload   = eventPayload;

        EventBody event = new EventBody();
        event.id          = "1";
        event.type        = "com.example";
        event.time        = "timestamp";
        event.specversion = "0.2";
        event.source      = "/test";
        event.rig         = "key-value";
        event.id          = "12345";
        event.contenttype = "application/json";
        event.data        = eventData;

        // expected
        EventPayload expectedEventPayload = new EventPayload();
        expectedEventPayload.payload = "Payload TRANSFORMED";
        expectedEventPayload.number  = 4;

        EventData expectedEventData = new EventData();
        expectedEventData.payload   = expectedEventPayload;

        EventBody expectedEvent = new EventBody();
        expectedEvent.id          = "1";
        expectedEvent.type        = "com.example";
        expectedEvent.time        = "timestamp";
        expectedEvent.specversion = "0.2";
        expectedEvent.source      = "/test";
        expectedEvent.rig         = "key-value";
        expectedEvent.id          = "12345";
        expectedEvent.contenttype = "application/json";
        expectedEvent.data        = expectedEventData;

        // make json
        Gson gson       = new Gson();
        String json     = gson.toJson(event);
        String expected = gson.toJson(expectedEvent);

        // send the message
        mockExternalProducer.sendDefault(json);

        // check that the transformed outbound message was received
        ConsumerRecord<String, String> received =
                records.poll(10, TimeUnit.SECONDS);

        // check the value
        assertThat(received, hasValue(expected));
        // AssertJ Condition to check the key
        Assertions.assertThat(received).has(key(null));
    }
}
