package com.ekride.bookings;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Long> {
    List<Booking> findByPassengerIdOrderByCreatedAtDesc(Long passengerId);
    List<Booking> findByRideId(Long rideId);
    List<Booking> findByRideIdAndStatus(Long rideId, BookingStatus status);
    boolean existsByRideIdAndPassengerIdAndStatusIn(Long rideId, Long passengerId, List<BookingStatus> statuses);
}
