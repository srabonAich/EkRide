package com.ekride.matching.dto;

import com.ekride.routes.dto.LocationDto;

public class MatchRequest {
    private LocationDto origin;
    private LocationDto destination;
    private Integer seatsRequired = 1;

    public LocationDto getOrigin() { return origin; }
    public void setOrigin(LocationDto origin) { this.origin = origin; }
    public LocationDto getDestination() { return destination; }
    public void setDestination(LocationDto destination) { this.destination = destination; }
    public Integer getSeatsRequired() { return seatsRequired; }
    public void setSeatsRequired(Integer seatsRequired) { this.seatsRequired = seatsRequired; }
}
