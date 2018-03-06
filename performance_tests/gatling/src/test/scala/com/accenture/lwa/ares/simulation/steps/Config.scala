package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import io.gatling.core.controller.inject.InjectionStep
import scala.concurrent.duration._

object Config {

  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))
  val rampUpPeriod = Integer.parseInt(sys.env.getOrElse("RAMP_UP_PERIOD", "1"))

  val users = rampUsers(targetUsers) over (rampUpPeriod seconds)
  //val users = constantUsersPerSec(10) during (50 seconds)

  val testServer = sys.env.getOrElse("TEST_SERVER", "localhost:4000")
  val httpConf = http.baseURL("http://" + testServer)
    .acceptHeader("application/json")
    .acceptEncodingHeader("gzip, deflate, br")
    .contentTypeHeader("application/json")
    .wsBaseURL("ws://" + testServer)

}