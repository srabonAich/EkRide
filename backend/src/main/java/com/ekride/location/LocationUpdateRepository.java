package com.ekride.location;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LocationUpdateRepository extends JpaRepository<LocationUpdate, Long> {
    List<LocationUpdate> findTop20ByRideIdOrderByCreatedAtDesc(Long rideId);
    LocationUpdate findTopByRideIdOrderByCreatedAtDesc(Long rideId);
}
