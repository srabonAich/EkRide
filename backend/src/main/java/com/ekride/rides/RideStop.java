package com.ekride.rides;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "ride_stops")
public class RideStop {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ride_id", nullable = false)
    private Long rideId;

    @Column(name = "passenger_id")
    private Long passengerId;

    @Column(name = "stop_order", nullable = false)
    private Integer stopOrder;

    @Enumerated(EnumType.STRING)
    @Column(name = "stop_type", nullable = false)
    private StopType stopType;

    @Column(nullable = false)
    private Double lat;

    @Column(nullable = false)
    private Double lng;

    private String address;

    @Column(name = "estimated_arrival_time")
    private Instant estimatedArrivalTime;

    public RideStop() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }
    public Integer getStopOrder() { return stopOrder; }
    public void setStopOrder(Integer stopOrder) { this.stopOrder = stopOrder; }
    public StopType getStopType() { return stopType; }
    public void setStopType(StopType stopType) { this.stopType = stopType; }
    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }
    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public Instant getEstimatedArrivalTime() { return estimatedArrivalTime; }
    public void setEstimatedArrivalTime(Instant estimatedArrivalTime) { this.estimatedArrivalTime = estimatedArrivalTime; }
}
