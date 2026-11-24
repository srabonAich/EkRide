package com.ekride;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class EkRideApplication {
    public static void main(String[] args) {
        SpringApplication.run(EkRideApplication.class, args);
    }
}
