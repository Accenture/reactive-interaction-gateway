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

object GetCallNoAuth {

  implicit val formats = DefaultFormats

  val getRequest = http("getCallNoAuth")
    .get("/api")
    .check(status.is(200))

  val getCallNoAuth = exec(getRequest)
}