package com.adamasorho.mindapax_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;

@Configuration
public class OpenAPIConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Mindapax API")
                .version("v1.0")
                .description("Empowering Your Mental, Physical & Financial Well-being")
                .contact(new Contact()
                    .name("Adama Sorho")
                    .email("adamasorho36@gmail.com")
                    .url("https://adamasorho.com")
                )
            );
    }
}
