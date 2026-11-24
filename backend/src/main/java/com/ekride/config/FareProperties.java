package com.ekride.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import java.math.BigDecimal;

@Configuration
@ConfigurationProperties(prefix = "ekride.fare")
public class FareProperties {
    private BigDecimal baseFare = new BigDecimal("50.00");
    private BigDecimal perKmRate = new BigDecimal("25.00");
    private BigDecimal perMinuteRate = new BigDecimal("0.00");
    private BigDecimal minimumFare = new BigDecimal("60.00");
    private BigDecimal platformFeePercent = new BigDecimal("10.00");
    private BigDecimal sharedDiscountPercent = new BigDecimal("25.00");

    public BigDecimal getBaseFare() { return baseFare; }
    public void setBaseFare(BigDecimal baseFare) { this.baseFare = baseFare; }
    public BigDecimal getPerKmRate() { return perKmRate; }
    public void setPerKmRate(BigDecimal perKmRate) { this.perKmRate = perKmRate; }
    public BigDecimal getPerMinuteRate() { return perMinuteRate; }
    public void setPerMinuteRate(BigDecimal perMinuteRate) { this.perMinuteRate = perMinuteRate; }
    public BigDecimal getMinimumFare() { return minimumFare; }
    public void setMinimumFare(BigDecimal minimumFare) { this.minimumFare = minimumFare; }
    public BigDecimal getPlatformFeePercent() { return platformFeePercent; }
    public void setPlatformFeePercent(BigDecimal platformFeePercent) { this.platformFeePercent = platformFeePercent; }
    public BigDecimal getSharedDiscountPercent() { return sharedDiscountPercent; }
    public void setSharedDiscountPercent(BigDecimal sharedDiscountPercent) { this.sharedDiscountPercent = sharedDiscountPercent; }
}
