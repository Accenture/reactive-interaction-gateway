package com.accenture.rig;

import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessor;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessorFactory;

public class RecordProcessorFactory implements IRecordProcessorFactory {
  private final ErlangInterface erlangInterface;

  public RecordProcessorFactory(final ErlangInterface erlangInterface) {
    this.erlangInterface = erlangInterface;
	}

/**
   * Returns a record processor to be used for processing data records for a (assigned) shard.
   *
   * @return Returns a processor object.
   */
  @Override
  public IRecordProcessor createProcessor() {
    return new RecordProcessor(erlangInterface);
  }
}
