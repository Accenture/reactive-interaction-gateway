# NATS integration test

Ensures that RIG can subscribe to a NATS topic and forwards a consumed event to a connected client.

```bash
- run.sh                           # The test script. Relies on Docker and HTTPie.
- publish_event_to_nats_topic.exs  # Simple script that publishes an event to the target NATS topic.
- received                         # The generated file, which is created/overwritten on each run.
```

For debugging purposes, the `received` file is not deleted in the script's cleanup phase.
