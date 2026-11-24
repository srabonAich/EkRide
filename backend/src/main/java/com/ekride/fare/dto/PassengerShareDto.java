package com.ekride.fare.dto;

import java.math.BigDecimal;

public class PassengerShareDto {
    private Long passengerId;
    private String passengerName;
    private BigDecimal individualFare;
    private BigDecimal directSoloFare;
    private BigDecimal savings;
    private BigDecimal savingsPercent;

    public PassengerShareDto() {}

    public PassengerShareDto(Long passengerId, String passengerName, BigDecimal individualFare, BigDecimal directSoloFare, BigDecimal savings, BigDecimal savingsPercent) {
        this.passengerId = passengerId;
        this.passengerName = passengerName;
        this.individualFare = individualFare;
        this.directSoloFare = directSoloFare;
        this.savings = savings;
        this.savingsPercent = savingsPercent;
    }

    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }
    public String getPassengerName() { return passengerName; }
    public void setPassengerName(String passengerName) { this.passengerName = passengerName; }
    public BigDecimal getIndividualFare() { return individualFare; }
    public void setIndividualFare(BigDecimal individualFare) { this.individualFare = individualFare; }
    public BigDecimal getDirectSoloFare() { return directSoloFare; }
    public void setDirectSoloFare(BigDecimal directSoloFare) { this.directSoloFare = directSoloFare; }
    public BigDecimal getSavings() { return savings; }
    public void setSavings(BigDecimal savings) { this.savings = savings; }
    public BigDecimal getSavingsPercent() { return savingsPercent; }
    public void setSavingsPercent(BigDecimal savingsPercent) { this.savingsPercent = savingsPercent; }
}
