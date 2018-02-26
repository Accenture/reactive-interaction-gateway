package com.accenture.rig;

import java.io.IOException;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Map.Entry;

import com.ericsson.otp.erlang.OtpAuthException;
import com.ericsson.otp.erlang.OtpConnection;
import com.ericsson.otp.erlang.OtpErlangAtom;
import com.ericsson.otp.erlang.OtpErlangBinary;
import com.ericsson.otp.erlang.OtpErlangDecodeException;
import com.ericsson.otp.erlang.OtpErlangExit;
import com.ericsson.otp.erlang.OtpErlangList;
import com.ericsson.otp.erlang.OtpErlangObject;
import com.ericsson.otp.erlang.OtpErlangTuple;
import com.ericsson.otp.erlang.OtpPeer;
import com.ericsson.otp.erlang.OtpSelf;

public class ErlangInterface {
  private final OtpConnection conn;

  public ErlangInterface(final String remote, final String cookie)
      throws UnknownHostException, OtpAuthException, IOException {
    final OtpSelf client = new OtpSelf("kinesis-client", cookie);
    final OtpPeer rig = new OtpPeer(remote);
    conn = client.connect(rig);
  }

  public void forward(final Map<String, Object> map)
      throws IOException, OtpErlangDecodeException, OtpErlangExit, OtpAuthException {
    final OtpErlangObject[] args = new OtpErlangObject[] { asErlangDict(map) };
    conn.sendRPC("Elixir.RigOutboundGateway.Kinesis.JavaClient", "java_client_callback", args);
    final OtpErlangObject response = conn.receiveMsg().getMsg();
    if (!isExpectedResponse(response)) {
      throw new IOException(String.format("Invalid response when forwarding message: %s", response));
    }
  }

  private OtpErlangList asErlangDict(final Map<String, Object> map) {
    final int nItems = map.size();
    final OtpErlangObject[] items = new OtpErlangObject[nItems];
    int i = 0;
    for (final Entry<String, Object> entry : map.entrySet()) {
      final Object javaObject = entry.getValue();

      OtpErlangObject erlangObject;
      if (javaObject instanceof String)
        erlangObject = new OtpErlangBinary(((String) javaObject).getBytes(StandardCharsets.UTF_8));
      else if (javaObject instanceof ByteBuffer)
        erlangObject = new OtpErlangBinary(((ByteBuffer) javaObject).array());
      else if (javaObject instanceof java.util.Date)
        erlangObject = new OtpErlangBinary(formatTimestamp((java.util.Date) javaObject).getBytes(StandardCharsets.UTF_8));
      else
        throw new RuntimeException("cannot convert " + javaObject.getClass().getCanonicalName());

      items[i] = new OtpErlangTuple(
          new OtpErlangObject[] { new OtpErlangAtom(entry.getKey()), erlangObject });

      ++i;
    }
    return new OtpErlangList(items);
  }

  private static String formatTimestamp(final java.util.Date plainOldDate) {
    return DateTimeFormatter.ISO_INSTANT.format(plainOldDate.toInstant().atZone(ZoneId.of("UTC")));
  }

  /**
   * This only checks whether the RPC went through.
   */
  private boolean isExpectedResponse(OtpErlangObject response) {
    if (response == null || !(response instanceof OtpErlangTuple))
      return false;

    final OtpErlangTuple tuple = (OtpErlangTuple) response;

    if (tuple.arity() != 2)
      return false;

    final OtpErlangObject first = tuple.elementAt(0);
    if (!(first instanceof OtpErlangAtom) || !((OtpErlangAtom) first).atomValue().equals("rex"))
      return false;

    final OtpErlangObject second = tuple.elementAt(1);
    if (!(second instanceof OtpErlangAtom) || !((OtpErlangAtom) second).atomValue().equals("ok"))
      return false;

    return true;
  }
}
