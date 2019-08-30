package com.rig.example.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.junit.Assert;
import org.junit.ClassRule;
import org.junit.Test;
import org.springframework.kafka.test.rule.EmbeddedKafkaRule;

import java.util.HashSet;
import java.util.Set;

public class EmbeddedKafkaExploreTest {

    @ClassRule
    public static EmbeddedKafkaRule embeddedKafkaRule = new EmbeddedKafkaRule(1, false, 5, "cat", "hat");

    @Test
    public void embeddedKafkaRuleTest() {
        embeddedKafkaRule.getEmbeddedKafka()
                .addTopics(new NewTopic("thing1", 10, (short) 1), new NewTopic("thing2", 15, (short) 1));

        Set<String> topics = embeddedKafkaRule.getEmbeddedKafka().getTopics();

        Set<String> expected = new HashSet<>();
        expected.add("cat");
        expected.add("thing2");
        expected.add("hat");
        expected.add("thing1");

        Assert.assertEquals(expected, topics);
    }
}