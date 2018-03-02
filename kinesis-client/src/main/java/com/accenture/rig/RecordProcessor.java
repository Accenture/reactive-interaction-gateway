package com.accenture.rig;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.amazonaws.services.kinesis.clientlibrary.exceptions.InvalidStateException;
import com.amazonaws.services.kinesis.clientlibrary.exceptions.KinesisClientLibDependencyException;
import com.amazonaws.services.kinesis.clientlibrary.exceptions.ShutdownException;
import com.amazonaws.services.kinesis.clientlibrary.exceptions.ThrottlingException;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessor;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.ShutdownReason;
import com.amazonaws.services.kinesis.clientlibrary.types.InitializationInput;
import com.amazonaws.services.kinesis.clientlibrary.types.ProcessRecordsInput;
import com.amazonaws.services.kinesis.clientlibrary.types.ShutdownInput;
import com.amazonaws.services.kinesis.model.Record;
import com.ericsson.otp.erlang.OtpAuthException;
import com.ericsson.otp.erlang.OtpErlangDecodeException;
import com.ericsson.otp.erlang.OtpErlangExit;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class RecordProcessor implements IRecordProcessor {
  private static final Log LOG = LogFactory.getLog(RecordProcessor.class);

  private final ErlangInterface erlangInterface;
  private String shardId;

  public RecordProcessor(final ErlangInterface erlangInterface) {
    this.erlangInterface = erlangInterface;
  }

  /**
   * Invoked by the Amazon Kinesis Client Library before data records are delivered to the RecordProcessor instance
   * (via processRecords).
   *
   * @param initializationInput Provides information related to initialization
   */
  @Override
  public void initialize(final InitializationInput initializationInput) {
    shardId = initializationInput.getShardId();
    LOG.info("Initializing record processor for shard: " + shardId);
  }

  /**
   * Process data records. The Amazon Kinesis Client Library will invoke this method to deliver data records to the
   * application.
   * Upon fail over, the new instance will get records with sequence number > checkpoint position
   * for each partition key.
   *
   * @param processRecordsInput Provides the records to be processed as well as information and capabilities related
   *                            to them (eg checkpointing).
   */
  @Override
  public void processRecords(final ProcessRecordsInput processRecordsInput) {
    final List<Record> records = processRecordsInput.getRecords();
    LOG.info(String.format("Shard %s: received %d records for processing", shardId, records.size()));
    records.stream().map(record -> {
      final Map<String, Object> map = new HashMap<>();
      map.put("shardId", shardId);
      map.put("partitionKey", record.getPartitionKey());
      map.put("sequenceNumber", record.getSequenceNumber());
      map.put("approximateArrivalTimestamp", record.getApproximateArrivalTimestamp());
      map.put("body", record.getData());
      return map;
    }).forEach(recordMap -> {
      try {
        erlangInterface.forward(recordMap);
      } catch (IOException | OtpErlangDecodeException | OtpErlangExit | OtpAuthException e) {
        final String incoming = recordMap.entrySet().stream()
            .map(entry -> String.format("%s => %s", entry.getKey(), entry.getValue()))
            .collect(Collectors.joining(", "));
        LOG.error(String.format("Failed to forward message: %s", incoming), e);
        // Fail fast - RIG will supervise/restart...
        System.exit(1);
      }
    });
  }

  /**
   * Invoked by the Amazon Kinesis Client Library to indicate it will no longer send data records to this
   * RecordProcessor instance.
   * <p>
   * <h2><b>Warning</b></h2>
   * <p>
   * When the value of {@link ShutdownInput#getShutdownReason()} is
   * {@link ShutdownReason#TERMINATE} it is required that you
   * checkpoint. Failure to do so will result in an IllegalArgumentException, and the KCL no longer making progress.
   *
   * @param shutdownInput Provides information and capabilities (eg checkpointing) related to shutdown of this record processor.
   */
  @Override
  public void shutdown(final ShutdownInput shutdownInput) {
    LOG.info("Shutting down record processor for shard " + shardId);
    if (shutdownInput.getShutdownReason().equals(ShutdownReason.TERMINATE)) {
      LOG.info(String.format("Writing checkpoint for shard %s (shutdown reason 'terminate')", shardId));

      try {
        shutdownInput.getCheckpointer().checkpoint();
      } catch (KinesisClientLibDependencyException | InvalidStateException | ThrottlingException
          | ShutdownException e) {
        LOG.error("Failed to checkpoing shard " + shardId, e);
      }
    }
  }
}
