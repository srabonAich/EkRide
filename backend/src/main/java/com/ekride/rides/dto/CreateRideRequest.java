package com.ekride.rides.dto;

import com.ekride.routes.dto.LocationDto;
import jakarta.validation.constraints.NotNull;

public class CreateRideRequest {
    @NotNull(message = "Origin is required")
    private LocationDto origin;

    @NotNull(message = "Destination is required")
    private LocationDto destination;

    private Integer totalSeats = 4;
    private String departureTime;

    public LocationDto getOrigin() { return origin; }
    public void setOrigin(LocationDto origin) { this.origin = origin; }
    public LocationDto getDestination() { return destination; }
    public void setDestination(LocationDto destination) { this.destination = destination; }
    public Integer getTotalSeats() { return totalSeats; }
    public void setTotalSeats(Integer totalSeats) { this.totalSeats = totalSeats; }
    public String getDepartureTime() { return departureTime; }
    public void setDepartureTime(String departureTime) { this.departureTime = departureTime; }
}
