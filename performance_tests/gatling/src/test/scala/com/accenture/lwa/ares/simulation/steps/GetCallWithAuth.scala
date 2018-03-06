package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import scala.concurrent.duration._
import io.gatling.http.request.builder.HttpRequestBuilder.toActionBuilder
import java.util.Base64
import org.json4s._
import org.json4s.native.JsonMethods._
import java.nio.charset.StandardCharsets
import scala.reflect.ManifestFactory.classType

object GetCallWithAuth {

  implicit val formats = DefaultFormats

  val sessionHeaders = Map(
    "authorization" -> "${token}",
    "Content-Type" -> "application/json"
  )

  val getRequest = http("getCallWithAuth")
    .get("/api")
    .headers(sessionHeaders)
    .check(status.is(200))

  val getCallWithAuth = exec(getRequest)
}