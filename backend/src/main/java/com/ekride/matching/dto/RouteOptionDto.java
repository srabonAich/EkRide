package com.ekride.matching.dto;

import com.ekride.fare.dto.FareBreakdownDto;
import com.ekride.routes.service.RoutePolylineUtils;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class RouteOptionDto {
    private String optionId;
    private String title;
    private String description;
    private long totalDistanceMeters;
    private long totalDurationSeconds;
    private long extraDistanceMeters;
    private long extraDurationSeconds;
    private BigDecimal estimatedTotalFare;
    private BigDecimal userIndividualFare;
    private BigDecimal directSoloFare;
    private BigDecimal estimatedSavings;
    private BigDecimal savingsPercent;
    private int availableSeats;
    private String encodedPolyline;
    private List<double[]> pathCoordinates = new ArrayList<>();
    private List<StopDto> stops = new ArrayList<>();
    private FareBreakdownDto fareBreakdown;
    private double matchingScore;
    private List<String> warnings = new ArrayList<>();

    public String getOptionId() { return optionId; }
    public void setOptionId(String optionId) { this.optionId = optionId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public long getTotalDistanceMeters() { return totalDistanceMeters; }
    public void setTotalDistanceMeters(long totalDistanceMeters) { this.totalDistanceMeters = totalDistanceMeters; }
    public long getTotalDurationSeconds() { return totalDurationSeconds; }
    public void setTotalDurationSeconds(long totalDurationSeconds) { this.totalDurationSeconds = totalDurationSeconds; }
    public long getExtraDistanceMeters() { return extraDistanceMeters; }
    public void setExtraDistanceMeters(long extraDistanceMeters) { this.extraDistanceMeters = extraDistanceMeters; }
    public long getExtraDurationSeconds() { return extraDurationSeconds; }
    public void setExtraDurationSeconds(long extraDurationSeconds) { this.extraDurationSeconds = extraDurationSeconds; }
    public BigDecimal getEstimatedTotalFare() { return estimatedTotalFare; }
    public void setEstimatedTotalFare(BigDecimal estimatedTotalFare) { this.estimatedTotalFare = estimatedTotalFare; }
    public BigDecimal getUserIndividualFare() { return userIndividualFare; }
    public void setUserIndividualFare(BigDecimal userIndividualFare) { this.userIndividualFare = userIndividualFare; }
    public BigDecimal getDirectSoloFare() { return directSoloFare; }
    public void setDirectSoloFare(BigDecimal directSoloFare) { this.directSoloFare = directSoloFare; }
    public BigDecimal getEstimatedSavings() { return estimatedSavings; }
    public void setEstimatedSavings(BigDecimal estimatedSavings) { this.estimatedSavings = estimatedSavings; }
    public BigDecimal getSavingsPercent() { return savingsPercent; }
    public void setSavingsPercent(BigDecimal savingsPercent) { this.savingsPercent = savingsPercent; }
    public int getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(int availableSeats) { this.availableSeats = availableSeats; }
    
    public String getEncodedPolyline() { return encodedPolyline; }
    public void setEncodedPolyline(String encodedPolyline) { 
        this.encodedPolyline = encodedPolyline; 
        if (encodedPolyline != null && !encodedPolyline.isEmpty()) {
            try {
                this.pathCoordinates = RoutePolylineUtils.decode(encodedPolyline);
            } catch (Exception ignored) {}
        }
    }

    public List<double[]> getPathCoordinates() { return pathCoordinates; }
    public void setPathCoordinates(List<double[]> pathCoordinates) { this.pathCoordinates = pathCoordinates; }

    public List<StopDto> getStops() { return stops; }
    public void setStops(List<StopDto> stops) { this.stops = stops; }
    public FareBreakdownDto getFareBreakdown() { return fareBreakdown; }
    public void setFareBreakdown(FareBreakdownDto fareBreakdown) { this.fareBreakdown = fareBreakdown; }
    public double getMatchingScore() { return matchingScore; }
    public void setMatchingScore(double matchingScore) { this.matchingScore = matchingScore; }
    public List<String> getWarnings() { return warnings; }
    public void setWarnings(List<String> warnings) { this.warnings = warnings; }
}
