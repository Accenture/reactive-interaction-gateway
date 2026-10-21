package com.accenture.rig;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;

import org.junit.Test;

public class AppTest {
  @Test
  public void closesLoggingConfigurationStream() throws Exception {
    final TrackingInputStream stream = new TrackingInputStream();
    final ClassLoader classLoader = new ClassLoader(null) {
      @Override
      public InputStream getResourceAsStream(String name) {
        assertEquals("log-config.properties", name);
        return stream;
      }
    };

    App.setupLogging(Level.INFO, classLoader);

    assertTrue(stream.isClosed());
  }

  private static final class TrackingInputStream extends ByteArrayInputStream {
    private boolean closed;

    TrackingInputStream() {
      super(".level=INFO\n".getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public void close() throws IOException {
      closed = true;
      super.close();
    }

    boolean isClosed() {
      return closed;
    }
  }
}
