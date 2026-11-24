package com.ekride.rides;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "rides")
public class Ride {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "creator_id", nullable = false)
    private Long creatorId;

    @Column(name = "driver_id")
    private Long driverId;

    @Column(name = "origin_lat", nullable = false)
    private Double originLat;

    @Column(name = "origin_lng", nullable = false)
    private Double originLng;

    @Column(name = "origin_address", nullable = false)
    private String originAddress;

    @Column(name = "destination_lat", nullable = false)
    private Double destinationLat;

    @Column(name = "destination_lng", nullable = false)
    private Double destinationLng;

    @Column(name = "destination_address", nullable = false)
    private String destinationAddress;

    @Column(name = "departure_time", nullable = false)
    private Instant departureTime = Instant.now();

    @Column(name = "total_seats", nullable = false)
    private Integer totalSeats = 4;

    @Column(name = "available_seats", nullable = false)
    private Integer availableSeats = 3;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RideStatus status = RideStatus.REQUESTED;

    @Column(name = "estimated_total_fare", nullable = false)
    private BigDecimal estimatedTotalFare = BigDecimal.ZERO;

    @Column(name = "estimated_distance_meters")
    private Long estimatedDistanceMeters = 0L;

    @Column(name = "estimated_duration_seconds")
    private Long estimatedDurationSeconds = 0L;

    @Column(name = "encoded_polyline", columnDefinition = "TEXT")
    private String encodedPolyline;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public Ride() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getCreatorId() { return creatorId; }
    public void setCreatorId(Long creatorId) { this.creatorId = creatorId; }
    public Long getDriverId() { return driverId; }
    public void setDriverId(Long driverId) { this.driverId = driverId; }
    public Double getOriginLat() { return originLat; }
    public void setOriginLat(Double originLat) { this.originLat = originLat; }
    public Double getOriginLng() { return originLng; }
    public void setOriginLng(Double originLng) { this.originLng = originLng; }
    public String getOriginAddress() { return originAddress; }
    public void setOriginAddress(String originAddress) { this.originAddress = originAddress; }
    public Double getDestinationLat() { return destinationLat; }
    public void setDestinationLat(Double destinationLat) { this.destinationLat = destinationLat; }
    public Double getDestinationLng() { return destinationLng; }
    public void setDestinationLng(Double destinationLng) { this.destinationLng = destinationLng; }
    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }
    public Instant getDepartureTime() { return departureTime; }
    public void setDepartureTime(Instant departureTime) { this.departureTime = departureTime; }
    public Integer getTotalSeats() { return totalSeats; }
    public void setTotalSeats(Integer totalSeats) { this.totalSeats = totalSeats; }
    public Integer getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(Integer availableSeats) { this.availableSeats = availableSeats; }
    public RideStatus getStatus() { return status; }
    public void setStatus(RideStatus status) { this.status = status; }
    public BigDecimal getEstimatedTotalFare() { return estimatedTotalFare; }
    public void setEstimatedTotalFare(BigDecimal estimatedTotalFare) { this.estimatedTotalFare = estimatedTotalFare; }
    public Long getEstimatedDistanceMeters() { return estimatedDistanceMeters; }
    public void setEstimatedDistanceMeters(Long estimatedDistanceMeters) { this.estimatedDistanceMeters = estimatedDistanceMeters; }
    public Long getEstimatedDurationSeconds() { return estimatedDurationSeconds; }
    public void setEstimatedDurationSeconds(Long estimatedDurationSeconds) { this.estimatedDurationSeconds = estimatedDurationSeconds; }
    public String getEncodedPolyline() { return encodedPolyline; }
    public void setEncodedPolyline(String encodedPolyline) { this.encodedPolyline = encodedPolyline; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
