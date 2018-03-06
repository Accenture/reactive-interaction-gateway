package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import scala.concurrent.duration._
import io.gatling.http.request.builder.ws.WsOpenRequestBuilder.toActionBuilder

object WebSockets {

  val messagesNumber = Integer.parseInt(sys.env.getOrElse("MESSAGES_N", "1"))
  val asyncWait = Integer.parseInt(sys.env.getOrElse("ASYNC_WAIT", "10"))

  val openWebSocket = ws("Connect WS")
   .open("/socket/websocket?token=${token}&vsn=1.0.0")

  val joinTopic = ws("Join user topic")
    .sendText("""{"topic":"user:${username}","event":"phx_join","payload":{},"ref":"1"}""")
    .check(wsAwait.within(5 second).until(1))

  val closeWebSocket = ws("Close WS").close

  val checkSyncMessage = ws("Check incoming ws message")
    .check(wsAwait.within(5 second).until(1))

  val checkAsyncMessage = ws("Check incoming async ws message")
    .check(wsListen.within(asyncWait second).until(messagesNumber))

  val join = exec(openWebSocket).exec(joinTopic)
}