package com.ekride.bookings;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "bookings")
public class Booking {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ride_id", nullable = false)
    private Long rideId;

    @Column(name = "passenger_id", nullable = false)
    private Long passengerId;

    @Column(name = "seats_booked", nullable = false)
    private Integer seatsBooked = 1;

    @Column(name = "pickup_lat", nullable = false)
    private Double pickupLat;

    @Column(name = "pickup_lng", nullable = false)
    private Double pickupLng;

    @Column(name = "pickup_address")
    private String pickupAddress;

    @Column(name = "dropoff_lat", nullable = false)
    private Double dropoffLat;

    @Column(name = "dropoff_lng", nullable = false)
    private Double dropoffLng;

    @Column(name = "dropoff_address")
    private String dropoffAddress;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BookingStatus status = BookingStatus.PENDING;

    @Column(name = "individual_fare", nullable = false)
    private BigDecimal individualFare = BigDecimal.ZERO;

    @Column(nullable = false)
    private BigDecimal savings = BigDecimal.ZERO;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public Booking() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }
    public Integer getSeatsBooked() { return seatsBooked; }
    public void setSeatsBooked(Integer seatsBooked) { this.seatsBooked = seatsBooked; }
    public Double getPickupLat() { return pickupLat; }
    public void setPickupLat(Double pickupLat) { this.pickupLat = pickupLat; }
    public Double getPickupLng() { return pickupLng; }
    public void setPickupLng(Double pickupLng) { this.pickupLng = pickupLng; }
    public String getPickupAddress() { return pickupAddress; }
    public void setPickupAddress(String pickupAddress) { this.pickupAddress = pickupAddress; }
    public Double getDropoffLat() { return dropoffLat; }
    public void setDropoffLat(Double dropoffLat) { this.dropoffLat = dropoffLat; }
    public Double getDropoffLng() { return dropoffLng; }
    public void setDropoffLng(Double dropoffLng) { this.dropoffLng = dropoffLng; }
    public String getDropoffAddress() { return dropoffAddress; }
    public void setDropoffAddress(String dropoffAddress) { this.dropoffAddress = dropoffAddress; }
    public BookingStatus getStatus() { return status; }
    public void setStatus(BookingStatus status) { this.status = status; }
    public BigDecimal getIndividualFare() { return individualFare; }
    public void setIndividualFare(BigDecimal individualFare) { this.individualFare = individualFare; }
    public BigDecimal getSavings() { return savings; }
    public void setSavings(BigDecimal savings) { this.savings = savings; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
