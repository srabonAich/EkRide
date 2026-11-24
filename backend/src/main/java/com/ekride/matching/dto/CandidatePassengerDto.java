package com.ekride.matching.dto;

public class CandidatePassengerDto {
    private Long rideId;
    private Long passengerId;
    private String passengerName;
    private String university;
    private double rating;
    private double pickupLat;
    private double pickupLng;
    private String pickupAddress;
    private double dropoffLat;
    private double dropoffLng;
    private String dropoffAddress;
    private double pickupDistanceMeters;
    private double dropoffDistanceMeters;
    private int availableSeats;

    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }
    public String getPassengerName() { return passengerName; }
    public void setPassengerName(String passengerName) { this.passengerName = passengerName; }
    public String getUniversity() { return university; }
    public void setUniversity(String university) { this.university = university; }
    public double getRating() { return rating; }
    public void setRating(double rating) { this.rating = rating; }
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
    public double getPickupDistanceMeters() { return pickupDistanceMeters; }
    public void setPickupDistanceMeters(double pickupDistanceMeters) { this.pickupDistanceMeters = pickupDistanceMeters; }
    public double getDropoffDistanceMeters() { return dropoffDistanceMeters; }
    public void setDropoffDistanceMeters(double dropoffDistanceMeters) { this.dropoffDistanceMeters = dropoffDistanceMeters; }
    public int getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(int availableSeats) { this.availableSeats = availableSeats; }
}
