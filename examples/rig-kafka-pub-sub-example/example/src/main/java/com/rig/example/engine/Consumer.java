package com.rig.example.engine;

import com.google.gson.Gson;
import com.rig.example.model.EventBody;
import com.rig.example.model.EventData;
import com.rig.example.model.EventPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class Consumer {
    private static final Logger logger = LoggerFactory.getLogger(Consumer.class);

    @Autowired
    private Producer producer;

    @KafkaListener(topics = "rig", groupId = "group_id")
    public void consumePolicyOwner(String message) {
        Gson gson = new Gson();
        EventBody eventBody = gson.fromJson(message, EventBody.class);

        EventData    eventData               = eventBody.getData();
        EventPayload eventPayload            = eventData.getPayload();
        EventPayload eventPayloadTransformed = eventPayload.transform();

        // mutates the eventBody with transformed payload
        eventBody.getData().setPayload(eventPayloadTransformed);

        String transformed = gson.toJson(eventBody);

        producer.send(transformed);

        logger.debug("consumed input message and produced output message");
    }
}