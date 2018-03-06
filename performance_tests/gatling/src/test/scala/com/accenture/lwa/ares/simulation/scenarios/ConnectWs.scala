package com.accenture.lwa.ares.simulation.scenarios

import com.accenture.lwa.ares.simulation._
import io.gatling.http.Predef._
import io.gatling.core.Predef._
import com.accenture.lwa.ares.simulation.steps.WebSockets
import com.accenture.lwa.ares.simulation.steps.SetUsername
import com.accenture.lwa.ares.simulation.steps.JwtGenerator

object ConnectWs {
  val pauseNumber = Integer.parseInt(sys.env.getOrElse("PAUSE_N", "10"))
  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))

  val scn = scenario("Max websockets connections")
    .exec(SetUsername.setUsername)
    .exec(JwtGenerator.setToken)
    .exec(WebSockets.join)
    .rendezVous(targetUsers)
    .pause(pauseNumber)
    .exec(WebSockets.closeWebSocket)
}