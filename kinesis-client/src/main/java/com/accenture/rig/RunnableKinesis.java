package com.accenture.rig;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Optional;
import java.util.UUID;

import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessorFactory;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.InitialPositionInStream;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.KinesisClientLibConfiguration;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.Worker;
import com.ericsson.otp.erlang.OtpAuthException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public final class RunnableKinesis implements Runnable {
  private static final Log LOG = LogFactory.getLog(RunnableKinesis.class);

  @Override
  public void run() {
    try {
      doRun();
    } catch (Throwable e) {
      e.printStackTrace();
    } finally {
      // the worker has stopped, so let's bring down the VM:
      System.exit(1);
    }
  }

  public void doRun() {
    final String rigErlangName = fetchEnv("RIG_ERLANG_NAME");
    final String rigErlangCookie = fetchEnv("RIG_ERLANG_COOKIE");

    LOG.info(String.format("Connecting to RIG (%s)..", rigErlangName));
    ErlangInterface erlInterface = null;
    try {
      erlInterface = new ErlangInterface(rigErlangName, rigErlangCookie);
    } catch (OtpAuthException | IOException e) {
      e.printStackTrace();
      System.exit(1);
    }

    // Ensure the JVM will refresh the cached IP values of AWS resources (e.g. service endpoints).
    java.security.Security.setProperty("networkaddress.cache.ttl", "60");

    String workerId = null;
    try {
      workerId = InetAddress.getLocalHost().getCanonicalHostName() + ":" + UUID.randomUUID();
    } catch (UnknownHostException e) {
      e.printStackTrace();
      System.exit(1);
    }
    final String appName = fetchEnv("KINESIS_APP_NAME");
    final String awsRegion = fetchEnv("KINESIS_AWS_REGION");
    final String kinesisStream = fetchEnv("KINESIS_STREAM");
    final Optional<String> kinesisEndpoint = getEnv("KINESIS_ENDPOINT");
    final Optional<String> dynamoDbEndpoint = getEnv("KINESIS_DYNAMODB_ENDPOINT");
    LOG.info(String.format("Kinesis config: app-name=%s aws-region=%s stream-name=%s", appName, awsRegion, kinesisStream));

    final KinesisClientLibConfiguration config = new KinesisClientLibConfiguration(appName, kinesisStream,
        new DefaultAWSCredentialsProviderChain(), workerId);
    config.withRegionName(awsRegion);
    config.withInitialPositionInStream(InitialPositionInStream.LATEST);

    if (kinesisEndpoint.isPresent()) {
      LOG.info(String.format("Kinesis endpoint: %s", kinesisEndpoint.get()));
      config.withKinesisEndpoint(kinesisEndpoint.get());
    }

    if (dynamoDbEndpoint.isPresent()) {
      LOG.info(String.format("DynamoDB endpoint: %s", dynamoDbEndpoint.get()));
      config.withDynamoDBEndpoint(dynamoDbEndpoint.get());
    }

    final IRecordProcessorFactory recordProcessorFactory = new RecordProcessorFactory(erlInterface);
    final Worker worker = new Worker.Builder().recordProcessorFactory(recordProcessorFactory).config(config).build();

    LOG.info(String.format("Running %s to process stream %s as worker %s...\n", appName, kinesisStream, workerId));

    worker.run();
  }

  private static Optional<String> getEnv(final String var) {
    final String val = System.getenv(var);
    if (val == null || val.isEmpty())
      return Optional.empty();
    else
      return Optional.of(val);
  }

  private static String fetchEnv(final String var) {
    return getEnv(var).orElseThrow(() -> new RuntimeException(String.format("%s not set", var)));
  }

}
