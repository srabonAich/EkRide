package com.ekride.routes.dto;

public class RouteCalculationResult {
    private long distanceMeters;
    private long durationSeconds;
    private String encodedPolyline;
    private boolean isSimulated;
    private String routeSummary;

    public RouteCalculationResult() {}

    public RouteCalculationResult(long distanceMeters, long durationSeconds, String encodedPolyline, boolean isSimulated, String routeSummary) {
        this.distanceMeters = distanceMeters;
        this.durationSeconds = durationSeconds;
        this.encodedPolyline = encodedPolyline;
        this.isSimulated = isSimulated;
        this.routeSummary = routeSummary;
    }

    public long getDistanceMeters() { return distanceMeters; }
    public void setDistanceMeters(long distanceMeters) { this.distanceMeters = distanceMeters; }
    public long getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(long durationSeconds) { this.durationSeconds = durationSeconds; }
    public String getEncodedPolyline() { return encodedPolyline; }
    public void setEncodedPolyline(String encodedPolyline) { this.encodedPolyline = encodedPolyline; }
    public boolean isSimulated() { return isSimulated; }
    public void setSimulated(boolean simulated) { isSimulated = simulated; }
    public String getRouteSummary() { return routeSummary; }
    public void setRouteSummary(String routeSummary) { this.routeSummary = routeSummary; }
}
