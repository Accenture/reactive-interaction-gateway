package com.accenture.lwa.ares

import java.util.Base64
import org.json4s._
import org.json4s.native.JsonMethods._
import java.nio.charset.StandardCharsets

object ScalaTest {
  def main(args: Array[String]) {
    
    implicit val formats = DefaultFormats
    
    val jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjpbImN1c3RvbWVyIl0sInVzZXJuYW1lIjoiZmlyc3QudXNlciIsImZ1bGxuYW1lIjoiRmlyc3QgVXNlciIsImVtYWlsIjoiSm9obmF0aGFuN0B5YWhvby5jb20iLCJhdmF0YXIiOiJodHRwczovL3MzLmFtYXpvbmF3cy5jb20vdWlmYWNlcy9mYWNlcy90d2l0dGVyL0NoYWtpbnRvc2gvMTI4LmpwZyIsImliYW4iOiJERTAzMDcyOTQxNjE5MzE3ODEzOCIsInNjb3BlcyI6e30sImlhdCI6MTUwMzMwMDI4NCwiZXhwIjoxNTAzMzAzODg0LCJqdGkiOiJkZWMzMjQwZS0wNzJjLTRjNGYtOWY3Ny04N2QwYTVlMjhiOGUifQ.ATYQvQum_fcF9esJeqO3KPB7oSmf7oKICeQLw9cUSew"
    val base64 = Base64.getDecoder().decode(jwt.split("\\.")(1));
    val decodedToken = parse(new String(base64, StandardCharsets.UTF_8))
    val jti = (decodedToken \ "jti").extract[String]
    
    println("Hello world")
    println(jti)
  }
}