package com.accenture.rig;

import java.io.IOException;
import java.io.InputStream;
import java.util.Optional;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

/**
 * App entrypoint.
 *
 * Credentials are expected at ~/.aws/credentials; template:
 *
 * [default]
 * aws_access_key_id=
 * aws_secret_access_key=
 */
public final class App {

  public static void main(final String[] args) throws Exception {
    setupLogging(getLogLevel());

    final Thread t = new Thread(new RunnableKinesis());
    t.setDaemon(true);
    t.start();

    // if RIG dies, System.in is closed and we can exit as well
    awaitEOF();
    System.exit(0);
  }

  private static Level getLogLevel() {
    final Level defaultLevel = Level.INFO;
    final Optional<String> setting = Optional.ofNullable(System.getenv("LOG_LEVEL"));
    if (setting.isPresent() && setting.get().length() > 0) {
      try {
        return Level.parse(setting.get());
      } catch (IllegalArgumentException e) {
        System.err.format(
          "'%s' is an illegal value for the LOGLEVEL environment parameter.\n" +
          "\n" +
          "The levels in descending order are:\n" +
          "\n" +
          "  - SEVERE (highest value)\n" +
          "  - WARNING\n" +
          "  - INFO\n" +
          "  - CONFIG\n" +
          "  - FINE\n" +
          "  - FINER\n" +
          "  - FINEST (lowest value)\n" +
          "\n" +
          "In addition there is a level OFF that can be used to turn off logging, and a level ALL that can be used to enable logging of all messages.\n",
          setting.get());
        System.exit(1);
        return null;  // Java says so
      }
    }
    else {
      return defaultLevel;
    }
  }

  private static void setupLogging(Level level) throws SecurityException, IOException {
    final LogManager logManager = LogManager.getLogManager();
    final InputStream propsStream = App.class.getClassLoader().getResourceAsStream("/log-config.properties");
    if (propsStream != null) {
      System.out.println("INFO: Logging configured via properties file.");
      logManager.readConfiguration(propsStream);
    } else {
      System.out.format("INFO: Logging configured using defaults for level %s.\n", level.toString());
      final Logger rootLogger = logManager.getLogger("");
      rootLogger.setLevel(level);
      for (final Handler h : rootLogger.getHandlers()) {
        h.setFormatter(new SimpleFormatter());
        h.setLevel(level);
      }
    }
  }

  private static void awaitEOF() {
    try {
      while (System.in.read() != -1) {
        // ignore
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}
