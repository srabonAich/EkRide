package com.ekride.bookings.dto;

import com.ekride.routes.dto.LocationDto;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class CreateBookingRequest {
    @NotNull(message = "Ride ID is required")
    private Long rideId;

    @NotNull(message = "Pickup location is required")
    private LocationDto pickup;

    @NotNull(message = "Dropoff location is required")
    private LocationDto dropoff;

    private Integer seatsBooked = 1;
    private BigDecimal individualFare;
    private BigDecimal savings;

    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public LocationDto getPickup() { return pickup; }
    public void setPickup(LocationDto pickup) { this.pickup = pickup; }
    public LocationDto getDropoff() { return dropoff; }
    public void setDropoff(LocationDto dropoff) { this.dropoff = dropoff; }
    public Integer getSeatsBooked() { return seatsBooked; }
    public void setSeatsBooked(Integer seatsBooked) { this.seatsBooked = seatsBooked; }
    public BigDecimal getIndividualFare() { return individualFare; }
    public void setIndividualFare(BigDecimal individualFare) { this.individualFare = individualFare; }
    public BigDecimal getSavings() { return savings; }
    public void setSavings(BigDecimal savings) { this.savings = savings; }
}
