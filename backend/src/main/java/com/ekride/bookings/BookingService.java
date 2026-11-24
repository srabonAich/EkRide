package com.ekride.bookings;

import com.ekride.bookings.dto.BookingDto;
import com.ekride.bookings.dto.CreateBookingRequest;
import com.ekride.rides.*;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class BookingService {
    private final BookingRepository bookingRepository;
    private final RideRepository rideRepository;
    private final RideStopRepository stopRepository;
    private final UserRepository userRepository;

    public BookingService(
            BookingRepository bookingRepository,
            RideRepository rideRepository,
            RideStopRepository stopRepository,
            UserRepository userRepository) {
        this.bookingRepository = bookingRepository;
        this.rideRepository = rideRepository;
        this.stopRepository = stopRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public BookingDto createBooking(Long passengerId, CreateBookingRequest request) {
        // Pessimistic write lock on Ride row to guarantee concurrent seat reservation safety!
        Ride ride = rideRepository.findByIdWithLock(request.getRideId())
                .orElseThrow(() -> new IllegalArgumentException("Ride not found: " + request.getRideId()));

        int seats = request.getSeatsBooked() != null ? request.getSeatsBooked() : 1;

        if (ride.getAvailableSeats() < seats) {
            throw new IllegalStateException("Not enough seats available! Requested: " + seats + ", Available: " + ride.getAvailableSeats());
        }

        if (ride.getStatus() == RideStatus.COMPLETED || ride.getStatus() == RideStatus.CANCELLED) {
            throw new IllegalStateException("Ride is no longer open for booking (status: " + ride.getStatus() + ")");
        }

        // Deduct seats and update ride status
        ride.setAvailableSeats(ride.getAvailableSeats() - seats);
        if (ride.getStatus() == RideStatus.REQUESTED) {
            ride.setStatus(RideStatus.CONFIRMED);
        }
        rideRepository.save(ride);

        Booking booking = new Booking();
        booking.setRideId(ride.getId());
        booking.setPassengerId(passengerId);
        booking.setSeatsBooked(seats);
        booking.setPickupLat(request.getPickup().getLat());
        booking.setPickupLng(request.getPickup().getLng());
        booking.setPickupAddress(request.getPickup().getAddress());
        booking.setDropoffLat(request.getDropoff().getLat());
        booking.setDropoffLng(request.getDropoff().getLng());
        booking.setDropoffAddress(request.getDropoff().getAddress());
        booking.setStatus(BookingStatus.CONFIRMED);
        booking.setIndividualFare(request.getIndividualFare() != null ? request.getIndividualFare() : BigDecimal.ZERO);
        booking.setSavings(request.getSavings() != null ? request.getSavings() : BigDecimal.ZERO);

        Booking savedBooking = bookingRepository.save(booking);

        // Add intermediate pickup and dropoff stops
        List<RideStop> existingStops = stopRepository.findByRideIdOrderByStopOrderAsc(ride.getId());
        int nextOrder = existingStops.size() + 1;

        RideStop pickupStop = new RideStop();
        pickupStop.setRideId(ride.getId());
        pickupStop.setPassengerId(passengerId);
        pickupStop.setStopOrder(nextOrder++);
        pickupStop.setStopType(StopType.PICKUP);
        pickupStop.setLat(booking.getPickupLat());
        pickupStop.setLng(booking.getPickupLng());
        pickupStop.setAddress(booking.getPickupAddress());
        stopRepository.save(pickupStop);

        RideStop dropoffStop = new RideStop();
        dropoffStop.setRideId(ride.getId());
        dropoffStop.setPassengerId(passengerId);
        dropoffStop.setStopOrder(nextOrder);
        dropoffStop.setStopType(StopType.DROPOFF);
        dropoffStop.setLat(booking.getDropoffLat());
        dropoffStop.setLng(booking.getDropoffLng());
        dropoffStop.setAddress(booking.getDropoffAddress());
        stopRepository.save(dropoffStop);

        User passenger = userRepository.findById(passengerId).orElse(null);
        return BookingDto.fromEntity(savedBooking, passenger != null ? passenger.getFullName() : "Passenger");
    }

    public List<BookingDto> getBookingsForPassenger(Long passengerId) {
        List<Booking> list = bookingRepository.findByPassengerIdOrderByCreatedAtDesc(passengerId);
        User passenger = userRepository.findById(passengerId).orElse(null);
        String name = passenger != null ? passenger.getFullName() : "Passenger";

        List<BookingDto> dtos = new ArrayList<>();
        for (Booking b : list) {
            dtos.add(BookingDto.fromEntity(b, name));
        }
        return dtos;
    }

    @Transactional
    public BookingDto cancelBooking(Long bookingId, Long userId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new IllegalArgumentException("Booking not found: " + bookingId));

        if (!booking.getPassengerId().equals(userId)) {
            throw new IllegalStateException("Only booking creator can cancel this booking");
        }

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            return BookingDto.fromEntity(booking, "Passenger");
        }

        booking.setStatus(BookingStatus.CANCELLED);
        bookingRepository.save(booking);

        // Release seats back to ride
        Ride ride = rideRepository.findByIdWithLock(booking.getRideId()).orElse(null);
        if (ride != null) {
            ride.setAvailableSeats(Math.min(ride.getTotalSeats(), ride.getAvailableSeats() + booking.getSeatsBooked()));
            rideRepository.save(ride);
        }

        User passenger = userRepository.findById(userId).orElse(null);
        return BookingDto.fromEntity(booking, passenger != null ? passenger.getFullName() : "Passenger");
    }
}
