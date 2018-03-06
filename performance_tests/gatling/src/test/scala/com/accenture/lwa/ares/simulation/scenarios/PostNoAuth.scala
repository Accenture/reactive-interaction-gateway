package com.accenture.lwa.ares.simulation.scenarios

import com.accenture.lwa.ares.simulation._
import io.gatling.http.Predef._
import io.gatling.core.Predef._
import com.accenture.lwa.ares.simulation.steps.PostCallNoAuth

object PostNoAuth {
  val requestsNumber = Integer.parseInt(sys.env.getOrElse("REQUESTS_N", "1"))
  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))

  val scn = scenario("Post call no auth")
    .rendezVous(targetUsers)
    .repeat(requestsNumber) {
      exec(PostCallNoAuth.postCallNoAuth)
    }
    .rendezVous(targetUsers)
}