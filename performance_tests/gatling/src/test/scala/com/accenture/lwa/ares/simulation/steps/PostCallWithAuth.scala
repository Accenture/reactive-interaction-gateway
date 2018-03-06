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

object PostCallWithAuth {

  implicit val formats = DefaultFormats

  val sessionHeaders = Map(
    "authorization" -> "${token}",
    "Content-Type" -> "application/json"
  )

  val postRequest = http("postCallWithAuth")
    .post("api")
    .headers(sessionHeaders)
    .body(StringBody("""{
      "a": "1",
      "b": "2@example.com",
      "c": "3",
      "d": "4"
    }"""))
    .check(status.is(200))

  val postCallWithAuth = exec(postRequest)
}