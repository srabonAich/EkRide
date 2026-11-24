package com.ekride.routes.dto;

import java.util.List;

public class RouteCompareRequest {
    private LocationDto origin;
    private LocationDto destination;
    private List<LocationDto> intermediateWaypoints;

    public LocationDto getOrigin() { return origin; }
    public void setOrigin(LocationDto origin) { this.origin = origin; }
    public LocationDto getDestination() { return destination; }
    public void setDestination(LocationDto destination) { this.destination = destination; }
    public List<LocationDto> getIntermediateWaypoints() { return intermediateWaypoints; }
    public void setIntermediateWaypoints(List<LocationDto> intermediateWaypoints) { this.intermediateWaypoints = intermediateWaypoints; }
}
