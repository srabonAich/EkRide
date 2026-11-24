package com.ekride.matching.dto;

import com.ekride.routes.dto.LocationDto;
import java.util.List;

public class CustomPoolRequest {
    private LocationDto origin;
    private LocationDto destination;
    private List<Long> selectedCandidateIds;

    public LocationDto getOrigin() { return origin; }
    public void setOrigin(LocationDto origin) { this.origin = origin; }
    public LocationDto getDestination() { return destination; }
    public void setDestination(LocationDto destination) { this.destination = destination; }
    public List<Long> getSelectedCandidateIds() { return selectedCandidateIds; }
    public void setSelectedCandidateIds(List<Long> selectedCandidateIds) { this.selectedCandidateIds = selectedCandidateIds; }
}
