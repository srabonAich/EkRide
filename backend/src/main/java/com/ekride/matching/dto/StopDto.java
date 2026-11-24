package com.ekride.matching.dto;

public class StopDto {
    private int order;
    private String type; // ORIGIN, PICKUP, DROPOFF, DESTINATION
    private double lat;
    private double lng;
    private String address;
    private String passengerName;

    public StopDto() {}

    public StopDto(int order, String type, double lat, double lng, String address, String passengerName) {
        this.order = order;
        this.type = type;
        this.lat = lat;
        this.lng = lng;
        this.address = address;
        this.passengerName = passengerName;
    }

    public int getOrder() { return order; }
    public void setOrder(int order) { this.order = order; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public double getLat() { return lat; }
    public void setLat(double lat) { this.lat = lat; }
    public double getLng() { return lng; }
    public void setLng(double lng) { this.lng = lng; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getPassengerName() { return passengerName; }
    public void setPassengerName(String passengerName) { this.passengerName = passengerName; }
}
