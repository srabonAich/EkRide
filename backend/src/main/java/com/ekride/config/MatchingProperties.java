package com.ekride.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "ekride.matching")
public class MatchingProperties {
    private double maxSearchRadiusMeters = 3000.0;
    private double maxDetourMeters = 4000.0;
    private double maxDetourMinutes = 15.0;

    public double getMaxSearchRadiusMeters() { return maxSearchRadiusMeters; }
    public void setMaxSearchRadiusMeters(double maxSearchRadiusMeters) { this.maxSearchRadiusMeters = maxSearchRadiusMeters; }
    public double getMaxDetourMeters() { return maxDetourMeters; }
    public void setMaxDetourMeters(double maxDetourMeters) { this.maxDetourMeters = maxDetourMeters; }
    public double getMaxDetourMinutes() { return maxDetourMinutes; }
    public void setMaxDetourMinutes(double maxDetourMinutes) { this.maxDetourMinutes = maxDetourMinutes; }
}
