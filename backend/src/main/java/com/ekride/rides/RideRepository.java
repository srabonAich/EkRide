package com.ekride.rides;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;

public interface RideRepository extends JpaRepository<Ride, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Ride r WHERE r.id = :id")
    Optional<Ride> findByIdWithLock(@Param("id") Long id);

    List<Ride> findByStatusIn(List<RideStatus> statuses);

    List<Ride> findByCreatorIdOrDriverId(Long creatorId, Long driverId);

    // PostgreSQL bounding box coordinate calculation when PostGIS is not available
    @Query("SELECT r FROM Ride r WHERE r.status IN ('REQUESTED', 'MATCHING') " +
           "AND r.originLat BETWEEN :minLat AND :maxLat " +
           "AND r.originLng BETWEEN :minLng AND :maxLng " +
           "AND r.availableSeats >= :seats")
    List<Ride> findNearbyCandidateRides(
            @Param("minLat") double minLat,
            @Param("maxLat") double maxLat,
            @Param("minLng") double minLng,
            @Param("maxLng") double maxLng,
            @Param("seats") int seats);
}
