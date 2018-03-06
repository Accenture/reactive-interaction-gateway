package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import scala.concurrent.duration._
import org.json4s._
import org.json4s.native.JsonMethods._
import java.nio.charset.StandardCharsets
import scala.reflect.ManifestFactory.classType
import java.util.UUID

object SetUsername {

  implicit val formats = DefaultFormats

  def username() = UUID.randomUUID().toString()

  val setUsername = exec(_.set("username", username))
}