package com.ekride.location;

public class LocationUpdateDto {
    private Long rideId;
    private Long userId;
    private double lat;
    private double lng;
    private Double heading;
    private Double speed;
    private boolean isSimulated;

    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public double getLat() { return lat; }
    public void setLat(double lat) { this.lat = lat; }
    public double getLng() { return lng; }
    public void setLng(double lng) { this.lng = lng; }
    public Double getHeading() { return heading; }
    public void setHeading(Double heading) { this.heading = heading; }
    public Double getSpeed() { return speed; }
    public void setSpeed(Double speed) { this.speed = speed; }
    public boolean isSimulated() { return isSimulated; }
    public void setSimulated(boolean simulated) { isSimulated = simulated; }
}
