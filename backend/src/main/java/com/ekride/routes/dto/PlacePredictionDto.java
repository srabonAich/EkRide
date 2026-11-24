package com.ekride.routes.dto;

public class PlacePredictionDto {
    private String placeId;
    private String primaryText;
    private String secondaryText;
    private String fullText;
    private Double lat;
    private Double lng;

    public PlacePredictionDto() {}

    public PlacePredictionDto(String placeId, String primaryText, String secondaryText, String fullText, Double lat, Double lng) {
        this.placeId = placeId;
        this.primaryText = primaryText;
        this.secondaryText = secondaryText;
        this.fullText = fullText;
        this.lat = lat;
        this.lng = lng;
    }

    public String getPlaceId() { return placeId; }
    public void setPlaceId(String placeId) { this.placeId = placeId; }
    public String getPrimaryText() { return primaryText; }
    public void setPrimaryText(String primaryText) { this.primaryText = primaryText; }
    public String getSecondaryText() { return secondaryText; }
    public void setSecondaryText(String secondaryText) { this.secondaryText = secondaryText; }
    public String getFullText() { return fullText; }
    public void setFullText(String fullText) { this.fullText = fullText; }
    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }
    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
}
