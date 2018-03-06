package com.accenture.lwa.ares.simulation.scenarios

import com.accenture.lwa.ares.simulation._
import io.gatling.http.Predef._
import io.gatling.core.Predef._
import com.accenture.lwa.ares.simulation.steps.RestProduce
import com.accenture.lwa.ares.simulation.steps.KafkaProduce
import com.accenture.lwa.ares.simulation.steps.WebSockets
import com.accenture.lwa.ares.simulation.steps.SetUsername
import com.accenture.lwa.ares.simulation.steps.JwtGenerator
import scala.concurrent.duration.DurationInt

object BroadcastLoadRest {
  val messagesNumber = Integer.parseInt(sys.env.getOrElse("MESSAGES_N", "1"))
  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))
  val asyncWait = Integer.parseInt(sys.env.getOrElse("ASYNC_WAIT", "10"))

  val scn = scenario("Multiple broadcast websockets")
    .exec(SetUsername.setUsername)
    .exec(JwtGenerator.setToken)
    .exec(WebSockets.join)
    .rendezVous(targetUsers)
    .exec(WebSockets.checkAsyncMessage)
    .repeat(messagesNumber) {
      exec(RestProduce.restProduce)
    }
    .rendezVous(targetUsers)
    .pause(asyncWait)
    .exec(WebSockets.closeWebSocket)
}