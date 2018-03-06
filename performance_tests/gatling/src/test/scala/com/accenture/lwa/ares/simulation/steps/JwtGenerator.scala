package com.accenture.lwa.ares.simulation.steps

import io.gatling.http.Predef._
import io.gatling.core.Predef._
import scala.concurrent.duration._
import org.json4s._
import org.json4s.native.JsonMethods._
import java.nio.charset.StandardCharsets
import scala.reflect.ManifestFactory.classType
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.JWT;
import java.util.Date;
import java.util.Calendar;

object JwtGenerator {

  implicit val formats = DefaultFormats

  val algorithm = Algorithm.HMAC256("jwttoken");
  val ONE_MINUTE_IN_MILLIS = 60000;
  val date = Calendar.getInstance();
  val t = date.getTimeInMillis();

  val token = (session: Session) => session("username").validate[String].map { username =>
    val tt = JWT.create()
      .withIssuer("auth0")
      .withExpiresAt(new Date(t + (10 * ONE_MINUTE_IN_MILLIS)))
      .withClaim("username", username)
      //.withArrayClaim("role", Array("customer"))
      //.withArrayClaim("role", Array[String]())
      .withClaim("jti", username)
      .sign(algorithm);
    session.set("token", tt)
  }

  val setToken = exec(token)
}
