package com.accenture.lwa.ares.simulation.scenarios

import com.accenture.lwa.ares.simulation._
import io.gatling.http.Predef._
import io.gatling.core.Predef._
import com.accenture.lwa.ares.simulation.steps.GetCallWithAuth
import com.accenture.lwa.ares.simulation.steps.SetUsername
import com.accenture.lwa.ares.simulation.steps.JwtGenerator

object GetWithAuth {
  val requestsNumber = Integer.parseInt(sys.env.getOrElse("REQUESTS_N", "1"))
  val targetUsers = Integer.parseInt(sys.env.getOrElse("TARGET_USERS", "1"))

  val scn = scenario("Get call with auth")
    .exec(SetUsername.setUsername)
    .exec(JwtGenerator.setToken)
    .rendezVous(targetUsers)
    .repeat(requestsNumber) {
      exec(GetCallWithAuth.getCallWithAuth)
    }
    .rendezVous(targetUsers)
}