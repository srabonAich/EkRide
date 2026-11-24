package com.ekride.routes.dto;

public class LocationDto {
    private Double lat;
    private Double lng;
    private String address;
    private String placeId;
    private Double bearing;

    public LocationDto() {}

    public LocationDto(Double lat, Double lng, String address) {
        this.lat = lat;
        this.lng = lng;
        this.address = address;
    }

    public LocationDto(Double lat, Double lng, String address, Double bearing) {
        this.lat = lat;
        this.lng = lng;
        this.address = address;
        this.bearing = bearing;
    }

    public LocationDto(Double lat, Double lng, String address, String placeId) {
        this.lat = lat;
        this.lng = lng;
        this.address = address;
        this.placeId = placeId;
    }

    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }
    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getPlaceId() { return placeId; }
    public void setPlaceId(String placeId) { this.placeId = placeId; }
    public Double getBearing() { return bearing; }
    public void setBearing(Double bearing) { this.bearing = bearing; }
}
