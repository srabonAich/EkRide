package com.ekride.rides.dto;

import com.ekride.rides.Ride;
import com.ekride.rides.RideStatus;
import com.ekride.rides.RideStop;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public class RideDto {
    private Long id;
    private Long creatorId;
    private String creatorName;
    private Long driverId;
    private String driverName;
    private double originLat;
    private double originLng;
    private String originAddress;
    private double destinationLat;
    private double destinationLng;
    private String destinationAddress;
    private Instant departureTime;
    private int totalSeats;
    private int availableSeats;
    private RideStatus status;
    private BigDecimal estimatedTotalFare;
    private long estimatedDistanceMeters;
    private long estimatedDurationSeconds;
    private String encodedPolyline;
    private List<RideStop> stops;

    public static RideDto fromEntity(Ride ride, String creatorName, String driverName, List<RideStop> stops) {
        RideDto dto = new RideDto();
        dto.setId(ride.getId());
        dto.setCreatorId(ride.getCreatorId());
        dto.setCreatorName(creatorName);
        dto.setDriverId(ride.getDriverId());
        dto.setDriverName(driverName);
        dto.setOriginLat(ride.getOriginLat());
        dto.setOriginLng(ride.getOriginLng());
        dto.setOriginAddress(ride.getOriginAddress());
        dto.setDestinationLat(ride.getDestinationLat());
        dto.setDestinationLng(ride.getDestinationLng());
        dto.setDestinationAddress(ride.getDestinationAddress());
        dto.setDepartureTime(ride.getDepartureTime());
        dto.setTotalSeats(ride.getTotalSeats());
        dto.setAvailableSeats(ride.getAvailableSeats());
        dto.setStatus(ride.getStatus());
        dto.setEstimatedTotalFare(ride.getEstimatedTotalFare());
        dto.setEstimatedDistanceMeters(ride.getEstimatedDistanceMeters() != null ? ride.getEstimatedDistanceMeters() : 0L);
        dto.setEstimatedDurationSeconds(ride.getEstimatedDurationSeconds() != null ? ride.getEstimatedDurationSeconds() : 0L);
        dto.setEncodedPolyline(ride.getEncodedPolyline());
        dto.setStops(stops);
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getCreatorId() { return creatorId; }
    public void setCreatorId(Long creatorId) { this.creatorId = creatorId; }
    public String getCreatorName() { return creatorName; }
    public void setCreatorName(String creatorName) { this.creatorName = creatorName; }
    public Long getDriverId() { return driverId; }
    public void setDriverId(Long driverId) { this.driverId = driverId; }
    public String getDriverName() { return driverName; }
    public void setDriverName(String driverName) { this.driverName = driverName; }
    public double getOriginLat() { return originLat; }
    public void setOriginLat(double originLat) { this.originLat = originLat; }
    public double getOriginLng() { return originLng; }
    public void setOriginLng(double originLng) { this.originLng = originLng; }
    public String getOriginAddress() { return originAddress; }
    public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }
    public double getDestinationLat() { return destinationLat; }
    public void setDestinationLat(double destinationLat) { this.destinationLat = destinationLat; }
    public double getDestinationLng() { return destinationLng; }
    public void setDestinationLng(double destinationLng) { this.destinationLng = destinationLng; }
    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }
    public Instant getDepartureTime() { return departureTime; }
    public void setDepartureTime(Instant departureTime) { this.departureTime = departureTime; }
    public int getTotalSeats() { return totalSeats; }
    public void setTotalSeats(int totalSeats) { this.totalSeats = totalSeats; }
    public int getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(int availableSeats) { this.availableSeats = availableSeats; }
    public RideStatus getStatus() { return status; }
    public void setStatus(RideStatus status) { this.status = status; }
    public BigDecimal getEstimatedTotalFare() { return estimatedTotalFare; }
    public void setEstimatedTotalFare(BigDecimal estimatedTotalFare) { this.estimatedTotalFare = estimatedTotalFare; }
    public long getEstimatedDistanceMeters() { return estimatedDistanceMeters; }
    public void setEstimatedDistanceMeters(long estimatedDistanceMeters) { this.estimatedDistanceMeters = estimatedDistanceMeters; }
    public long getEstimatedDurationSeconds() { return estimatedDurationSeconds; }
    public void setEstimatedDurationSeconds(long estimatedDurationSeconds) { this.estimatedDurationSeconds = estimatedDurationSeconds; }
    public String getEncodedPolyline() { return encodedPolyline; }
    public void setEncodedPolyline(String encodedPolyline) { this.encodedPolyline = encodedPolyline; }
    public List<RideStop> getStops() { return stops; }
    public void setStops(List<RideStop> stops) { this.stops = stops; }
}
