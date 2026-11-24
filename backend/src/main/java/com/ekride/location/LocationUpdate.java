package com.ekride.location;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "location_updates")
public class LocationUpdate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ride_id")
    private Long rideId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private Double lat;

    @Column(nullable = false)
    private Double lng;

    private Double heading;
    private Double speed;

    @Column(name = "is_simulated")
    private Boolean isSimulated = false;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public LocationUpdate() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRideId() { return rideId; }
    public void setRideId(Long rideId) { this.rideId = rideId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }
    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
    public Double getHeading() { return heading; }
    public void setHeading(Double heading) { this.heading = heading; }
    public Double getSpeed() { return speed; }
    public void setSpeed(Double speed) { this.speed = speed; }
    public Boolean getIsSimulated() { return isSimulated; }
    public void setIsSimulated(Boolean isSimulated) { this.isSimulated = isSimulated; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
