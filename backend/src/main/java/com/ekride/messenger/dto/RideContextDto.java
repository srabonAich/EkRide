package com.ekride.messenger.dto;

import com.ekride.rides.Ride;
import com.ekride.rides.RideStatus;

import java.math.BigDecimal;

public class RideContextDto {
    private Long rideId;
    private String originAddress;
    private String destinationAddress;
    private Integer totalSeats;
    private Integer availableSeats;
    private Integer occupiedSeats;
    private RideStatus rideStatus;
    private String vehicleType; // "BIKE", "RICKSHAW_CNG", "CAR_UBER"
    private BigDecimal estimatedTotalFare;

    public RideContextDto() {}

    public static RideContextDto fromRide(Ride ride) {
        RideContextDto dto = new RideContextDto();
        dto.setRideId(ride.getId());
        dto.setOriginAddress(ride.getOriginAddress());
        dto.setDestinationAddress(ride.getDestinationAddress());
        dto.setTotalSeats(ride.getTotalSeats());
        dto.setAvailableSeats(ride.getAvailableSeats());
        dto.setOccupiedSeats(Math.max(0, ride.getTotalSeats() - ride.getAvailableSeats()));
        dto.setRideStatus(ride.getStatus());
        dto.setEstimatedTotalFare(ride.getEstimatedTotalFare());

        int seats = ride.getTotalSeats() != null ? ride.getTotalSeats() : 4;
        if (seats <= 2) {
            dto.setVehicleType("BIKE");
        } else if (seats == 3) {
            dto.setVehicleType("CNG");
        } else {
            dto.setVehicleType("CAR");
        }
        return dto;
    }

    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }

    public String getOriginAddress() { return originAddress; }
    public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }

    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }

    public Integer getTotalSeats() { return totalSeats; }
    public void setTotalSeats(Integer totalSeats) { this.totalSeats = totalSeats; }

    public Integer getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(Integer availableSeats) { this.availableSeats = availableSeats; }

    public Integer getOccupiedSeats() { return occupiedSeats; }
    public void setOccupiedSeats(Integer occupiedSeats) { this.occupiedSeats = occupiedSeats; }

    public RideStatus getRideStatus() { return rideStatus; }
    public void setRideStatus(RideStatus rideStatus) { this.rideStatus = rideStatus; }

    public String getVehicleType() { return vehicleType; }
    public void setVehicleType(String vehicleType) { this.vehicleType = vehicleType; }

    public BigDecimal getEstimatedTotalFare() { return estimatedTotalFare; }
    public void setEstimatedTotalFare(BigDecimal estimatedTotalFare) { this.estimatedTotalFare = estimatedTotalFare; }
}
