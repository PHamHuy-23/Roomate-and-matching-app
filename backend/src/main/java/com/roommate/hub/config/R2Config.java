package com.roommate.hub.config;

import java.net.URI;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
@EnableConfigurationProperties(R2Properties.class)
public class R2Config {

    @Bean(destroyMethod = "close")
    @ConditionalOnProperty(name = "storage.r2.enabled", havingValue = "true")
    S3Presigner r2Presigner(R2Properties properties) {
        requireConfigured(properties.getEndpoint(), "R2_ENDPOINT");
        requireConfigured(properties.getAccessKeyId(), "R2_ACCESS_KEY_ID");
        requireConfigured(properties.getSecretAccessKey(), "R2_SECRET_ACCESS_KEY");
        requireConfigured(properties.getBucket(), "R2_BUCKET_NAME");
        requireConfigured(properties.getPublicUrl(), "R2_PUBLIC_URL");

        // A missing private bucket must fail closed only for private operations,
        // without taking public avatar/room-post uploads offline.

        return S3Presigner.builder()
                .endpointOverride(URI.create(properties.getEndpoint()))
                .region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(
                                properties.getAccessKeyId(),
                                properties.getSecretAccessKey())))
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(true)
                        .build())
                .build();
    }

    private static void requireConfigured(String value, String variableName) {
        if (value == null || value.isBlank() || value.startsWith("YOUR_")) {
            throw new IllegalStateException(variableName + " chưa được cấu hình");
        }
    }
}
