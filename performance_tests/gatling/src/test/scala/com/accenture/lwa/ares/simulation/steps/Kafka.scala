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

import java.util.{Date, Properties}
import org.apache.kafka.clients.producer.{KafkaProducer, ProducerRecord}
import org.json.JSONObject
import scala.util.Random

object Kafka {

  val TOPIC = sys.env.getOrElse("KAFKA_TOPIC", "message");
  val BOOTSTRAP_SERVERS = sys.env.getOrElse("KAFKA_HOSTS", "localhost:9092");

  val props = new Properties();
  props.put("bootstrap.servers", BOOTSTRAP_SERVERS)
  props.put("client.id", "ProducerGatling")
  props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
  props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
  val producer = new KafkaProducer[String, String](props)

  val send = (username: String) => {
    val record = new JSONObject();
    record.put("username", username);
    record.put("foo", "bar");

    val data = new ProducerRecord[String, String](TOPIC, username, record.toString())

    producer.send(data)
  }
}
