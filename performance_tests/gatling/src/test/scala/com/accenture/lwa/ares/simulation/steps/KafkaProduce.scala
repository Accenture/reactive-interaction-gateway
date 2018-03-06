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
import scala.util.parsing.json._

object KafkaProduce {

  implicit val formats = DefaultFormats

  val sendKafkaMessage = (session: Session) => session("username").validate[String].map { username =>
    Kafka.send(username)
    session.set("message", "sent")
  }

}