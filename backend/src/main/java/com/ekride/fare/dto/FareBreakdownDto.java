package com.ekride.fare.dto;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class FareBreakdownDto {
    private BigDecimal totalVehicleFare;
    private BigDecimal baseFareComponent;
    private BigDecimal distanceFareComponent;
    private BigDecimal timeFareComponent;
    private BigDecimal platformFee;
    private BigDecimal driverEarnings;
    private BigDecimal detourCostComponent = BigDecimal.ZERO;
    private BigDecimal userDetourShare = BigDecimal.ZERO;
    private BigDecimal peerDetourShare = BigDecimal.ZERO;
    private List<PassengerShareDto> passengerShares = new ArrayList<>();

    public BigDecimal getTotalVehicleFare() { return totalVehicleFare; }
    public void setTotalVehicleFare(BigDecimal totalVehicleFare) { this.totalVehicleFare = totalVehicleFare; }
    public BigDecimal getBaseFareComponent() { return baseFareComponent; }
    public void setBaseFareComponent(BigDecimal baseFareComponent) { this.baseFareComponent = baseFareComponent; }
    public BigDecimal getDistanceFareComponent() { return distanceFareComponent; }
    public void setDistanceFareComponent(BigDecimal distanceFareComponent) { this.distanceFareComponent = distanceFareComponent; }
    public BigDecimal getTimeFareComponent() { return timeFareComponent; }
    public void setTimeFareComponent(BigDecimal timeFareComponent) { this.timeFareComponent = timeFareComponent; }
    public BigDecimal getPlatformFee() { return platformFee; }
    public void setPlatformFee(BigDecimal platformFee) { this.platformFee = platformFee; }
    public BigDecimal getDriverEarnings() { return driverEarnings; }
    public void setDriverEarnings(BigDecimal driverEarnings) { this.driverEarnings = driverEarnings; }
    public BigDecimal getDetourCostComponent() { return detourCostComponent; }
    public void setDetourCostComponent(BigDecimal detourCostComponent) { this.detourCostComponent = detourCostComponent; }
    public BigDecimal getUserDetourShare() { return userDetourShare; }
    public void setUserDetourShare(BigDecimal userDetourShare) { this.userDetourShare = userDetourShare; }
    public BigDecimal getPeerDetourShare() { return peerDetourShare; }
    public void setPeerDetourShare(BigDecimal peerDetourShare) { this.peerDetourShare = peerDetourShare; }
    public List<PassengerShareDto> getPassengerShares() { return passengerShares; }
    public void setPassengerShares(List<PassengerShareDto> passengerShares) { this.passengerShares = passengerShares; }
}
