# RIG Kinesis Client

A Java application used to consume messages from Amazon Kinesis Data Streams. It uses the official AWS Java SDK and the [Amazon Kinesis Client Library (KCL)](https://docs.aws.amazon.com/streams/latest/dev/developing-consumers-with-kcl.html).

Compile with `mvn package` or `mix compile_kinesis_client` from the root folder. During development, `mvn exec:java` may be helpful as well. Note that maven uses a [local version of JInterface](local-maven-repo/org/erlang/otp/jinterface/) instead of the one included in your system Erlang distribution. This is just convenience in case your Erlang is not compiled with Java support. At runtime, the Jar file is expected to be on the classpath, i.e., considered a `provided` dependency.

## Why Java and not Elixir?

The KCL is the only Amazon-supported way of integration with Kinesis and it is responsible for a lot of complexity:

- Connects to the stream
- Enumerates the shards
- Coordinates shard associations with other workers (if any)
- Instantiates a record processor for every shard it manages
- Pulls data records from the stream
- Pushes the records to the corresponding record processor
- Checkpoints processed records
- Balances shard-worker associations when the worker instance count changes
- Balances shard-worker associations when shards are split or merged

Implementing this in Elixir (and keeping the implementation up-to-date with the Kinesis API) seems more effort than using the library in a separate Java app.

## Interface with RIG

RIG manages the lifecycle of the Java app and processes its log messages. Messages coming from Kinesis are sent from the Java app to RIG using Erlang RPCs (see [`ErlangInterface.java`](src/main/java/com/accenture/rig/ErlangInterface.java) for details).

The Java app is configured through RIG (a user should not have to deal with properties-files or any other Java stuff). The environment variables are documented in [the operator's guide](../guides/operator-guide.md).
