package com.kimibank.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "kimibank.otp")
public class OtpProperties {
    private int length = 6;
    private int ttlSeconds = 300;
    private int maxAttempts = 5;
    private boolean devMode = true;

    public int getLength() { return length; }
    public void setLength(int length) { this.length = length; }
    public int getTtlSeconds() { return ttlSeconds; }
    public void setTtlSeconds(int ttlSeconds) { this.ttlSeconds = ttlSeconds; }
    public int getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(int maxAttempts) { this.maxAttempts = maxAttempts; }
    public boolean isDevMode() { return devMode; }
    public void setDevMode(boolean devMode) { this.devMode = devMode; }
}
