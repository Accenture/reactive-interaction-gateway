package com.rig.example.engine;

import static org.assertj.core.api.Assertions.assertThat;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import com.google.gson.Gson;
import com.rig.example.model.EventBody;
import com.rig.example.model.EventData;
import com.rig.example.model.EventPayload;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.config.KafkaListenerEndpointRegistry;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.MessageListenerContainer;
import org.springframework.kafka.test.rule.EmbeddedKafkaRule;
import org.springframework.kafka.test.utils.ContainerTestUtils;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
@DirtiesContext
public class ProducerTest {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(ProducerTest.class);

    private static String RECEIVER_TOPIC = "rig";

    @Autowired
    private Consumer receiver;

    private KafkaTemplate<String, String> template;

    @Autowired
    private KafkaListenerEndpointRegistry kafkaListenerEndpointRegistry;

    @ClassRule
    public static EmbeddedKafkaRule embeddedKafka =
            new EmbeddedKafkaRule(1, true, RECEIVER_TOPIC);

    @Before
    public void setUp() throws Exception {
        // set up the Kafka producer properties
        Map<String, Object> senderProperties =
                KafkaTestUtils.senderProps(
                        embeddedKafka.getEmbeddedKafka().getBrokersAsString());

        // create a Kafka producer factory
        ProducerFactory<String, String> producerFactory =
                new DefaultKafkaProducerFactory<String, String>(
                        senderProperties);

        // create a Kafka template
        template = new KafkaTemplate<>(producerFactory);
        // set the default topic to send to
        template.setDefaultTopic(RECEIVER_TOPIC);

        // wait until the partitions are assigned
        for (MessageListenerContainer messageListenerContainer : kafkaListenerEndpointRegistry
                .getListenerContainers()) {
            ContainerTestUtils.waitForAssignment(messageListenerContainer,
                    embeddedKafka.getEmbeddedKafka().getPartitionsPerTopic());
        }
    }

    @Test
    public void testReceive() throws Exception {
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
        template.sendDefault(json);
        LOGGER.debug("test-sender sent message='{}'", json);

        receiver.getLatch().await(1000, TimeUnit.MILLISECONDS);
        // check that the message was received
        assertThat(receiver.getLatch().getCount()).isEqualTo(0);
    }
}