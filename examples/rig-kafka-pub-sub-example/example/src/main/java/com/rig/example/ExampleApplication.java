package com.rig.example;

import com.rig.example.config.KafkaConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ExampleApplication {

	@Autowired
	private KafkaConfig kafkaConfig;

	public static void main(String[] args) {
		SpringApplication.run(ExampleApplication.class, args);
	}

}
