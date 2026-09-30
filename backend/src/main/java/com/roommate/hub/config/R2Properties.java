package com.roommate.hub.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "storage.r2")
public class R2Properties {
    private boolean enabled;
    private String endpoint;
    private String accessKeyId;
    private String secretAccessKey;
    private String bucket;
    private String publicUrl;
    private long presignDurationMinutes = 10;
    private long maxUploadBytes = 5 * 1024 * 1024;
}
