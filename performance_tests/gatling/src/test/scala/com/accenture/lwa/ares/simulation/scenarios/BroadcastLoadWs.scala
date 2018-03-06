package com.accenture.lwa.ares.simulation.scenarios

import com.accenture.lwa.ares.simulation._
import io.gatling.http.Predef._
import io.gatling.core.Predef._
import com.accenture.lwa.ares.simulation.steps.KafkaProduce
import com.accenture.lwa.ares.simulation.steps.WebSockets
import com.accenture.lwa.ares.simulation.steps.SetUsername
import com.accenture.lwa.ares.simulation.steps.JwtGenerator

object BroadcastLoadWs {
  val messagesNumber = Integer.parseInt(sys.env.getOrElse("MESSAGES_N", "1"))
  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))

  val scn = scenario("Multiple broadcast websockets")
    .exec(SetUsername.setUsername)
    .exec(JwtGenerator.setToken)
    .exec(WebSockets.join)
    .rendezVous(targetUsers)
    .repeat(messagesNumber) {
      exec(KafkaProduce.sendKafkaMessage)
      .exec(WebSockets.checkSyncMessage)
    }
    .rendezVous(targetUsers)
    .exec(WebSockets.closeWebSocket)
}