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

object PostCallNoAuth {

  implicit val formats = DefaultFormats

  val postRequest = http("postCallNoAuth")
    .post("/api")
    .body(StringBody("""{
      "a": "1",
      "b": "2@example.com",
      "c": "3",
      "d": "4"
    }"""))
    .check(status.is(200))
  val postCallNoAuth = exec(postRequest)
}