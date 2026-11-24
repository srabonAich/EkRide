package com.ekride.bookings.dto;

import com.ekride.bookings.Booking;
import com.ekride.bookings.BookingStatus;
import java.math.BigDecimal;
import java.time.Instant;

public class BookingDto {
    private Long id;
    private Long rideId;
    private Long passengerId;
    private String passengerName;
    private int seatsBooked;
    private double pickupLat;
    private double pickupLng;
    private String pickupAddress;
    private double dropoffLat;
    private double dropoffLng;
    private String dropoffAddress;
    private BookingStatus status;
    private BigDecimal individualFare;
    private BigDecimal savings;
    private Instant createdAt;

    public static BookingDto fromEntity(Booking b, String passengerName) {
        BookingDto dto = new BookingDto();
        dto.setId(b.getId());
        dto.setRideId(b.getRideId());
        dto.setPassengerId(b.getPassengerId());
        dto.setPassengerName(passengerName);
        dto.setSeatsBooked(b.getSeatsBooked());
        dto.setPickupLat(b.getPickupLat());
        dto.setPickupLng(b.getPickupLng());
        dto.setPickupAddress(b.getPickupAddress());
        dto.setDropoffLat(b.getDropoffLat());
        dto.setDropoffLng(b.getDropoffLng());
        dto.setDropoffAddress(b.getDropoffAddress());
        dto.setStatus(b.getStatus());
        dto.setIndividualFare(b.getIndividualFare());
        dto.setSavings(b.getSavings());
        dto.setCreatedAt(b.getCreatedAt());
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }
    public String getPassengerName() { return passengerName; }
    public void setPassengerName(String passengerName) { this.passengerName = passengerName; }
    public int getSeatsBooked() { return seatsBooked; }
    public void setSeatsBooked(int seatsBooked) { this.seatsBooked = seatsBooked; }
    public double getPickupLat() { return pickupLat; }
    public void setPickupLat(double pickupLat) { this.pickupLat = pickupLat; }
    public double getPickupLng() { return pickupLng; }
    public void setPickupLng(double pickupLng) { this.pickupLng = pickupLng; }
    public String getPickupAddress() { return pickupAddress; }
    public void setPickupAddress(String pickupAddress) { this.pickupAddress = pickupAddress; }
    public double getDropoffLat() { return dropoffLat; }
    public void setDropoffLat(double dropoffLat) { this.dropoffLat = dropoffLat; }
    public double getDropoffLng() { return dropoffLng; }
    public void setDropoffLng(double dropoffLng) { this.dropoffLng = dropoffLng; }
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
