package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import scala.concurrent.duration._
import io.gatling.http.request.builder.HttpRequestBuilder.toActionBuilder
import io.gatling.http.request.builder.ws.WsOpenRequestBuilder.toActionBuilder
import java.util.Base64
import org.json4s._
import org.json4s.native.JsonMethods._
import java.nio.charset.StandardCharsets
import scala.reflect.ManifestFactory.classType

object RestProduce {

  implicit val formats = DefaultFormats

  val testServer = sys.env.getOrElse("TEST_SERVER_API", "localhost:4010")

  val restProduce = http("eventMessage")
    .post("http://" + testServer + "/v1/messages")
    .body(StringBody("""{
      "username": "${username}",
      "message": "sent"
    }"""))
    //.check(status.is(202))
}