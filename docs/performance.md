---
id: performance
title: Performance
sidebar_label: Performance
---

We identified couple of scenarios to ensure that RIG is able to handle enterprise-grade traffic.

## Run 1: Time it takes to consume and drop 1M messages from Kafka

One of the assumptions behind RIG's design is that many of the messages flowing through Kafka can actually be ignored from RIG's perspective, that is, are not subscribed to by any frontend that might be connected to it. This test validates that RIG is indeed capable of dropping large amounts of messages quickly.

1. Load 1M Kafka messages, each 1 kB in size, during the ramp up, where the first and the last message have eventType set to to_be_delivered, while all others have eventType set to ignored.
2. Connect a client and subscribe to events of type to_be_delivered. This causes all except the first and the last messages to be dropped.
3. Measure time between the first and the last message as received at the client.

Hypothesis: this takes 1-2 seconds.

## Run 2: Resource consumption when all clients use the same configuration

If RIG is run with a dedicated Kafka topic attached to it, all messages consumed from Kafka are potentially relevant to frontends. This tests the case where there is only one frontend, instantiated once for each client, where the subscriptions are not user-specific.

Configurations: (a) 10k, (b) 20k, (c) 30k, (d) 40k clients

1. Load 1M Kafka messages, each 1 kB in size, during the ramp up, where all messages have eventType set to to_be_delivered.
2. Connect all clients with subscriptions for events of type to_be_delivered. This causes all clients to receive all messages.
3. Measure time, memory and cpu consumption over time until all clients have received 1M messages each.

Hypothesis: this takes <5 seconds.

## Run 3: Resource consumption when clients receive a presumably realistic share of the events

If RIG is run with a dedicated Kafka topic attached to it, all messages consumed from Kafka are potentially relevant to frontends. This tests the case where there is only one frontend, instantiated once for each client, where the subscriptions are user-specific. In practice, the events would not be differentiated by their event type but by dedicated "user" field. However, for the purpose of this benchmark the eventType field is used to ease the comparison with Run 2.

Configurations: (a) 10k, (b) 20k, (c) 30k, (d) 40k clients

1. Create 1M Kafka messages, each 1 kB in size. Use the numbers from 1 to 5 as the messages' eventType, such that the "partitions" are interleaved. Load the messages during ramp up.
2. Connect the clients. Make sure that a fifth of them is subscribed to eventType 1, a fifth to eventType 2, etc. This causes all clients to receive a fifth of all messages.
3. Measure time, memory and cpu consumption over time until all clients have received 200k messages each.

Hypothesis: this is 5 times faster than Run 2.

TODO:

- resulted numbers
- test setup
