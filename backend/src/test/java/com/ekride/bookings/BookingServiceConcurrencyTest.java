package com.ekride.bookings;

import com.ekride.bookings.dto.CreateBookingRequest;
import com.ekride.rides.*;
import com.ekride.routes.dto.LocationDto;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BookingServiceConcurrencyTest {

    @Test
    @DisplayName("Should prevent overbooking when available seats is less than requested")
    void testOverbookingPrevention() {
        BookingRepository bookingRepo = Mockito.mock(BookingRepository.class);
        RideRepository rideRepo = Mockito.mock(RideRepository.class);
        RideStopRepository stopRepo = Mockito.mock(RideStopRepository.class);
        UserRepository userRepo = Mockito.mock(UserRepository.class);

        BookingService bookingService = new BookingService(bookingRepo, rideRepo, stopRepo, userRepo);

        Ride ride = new Ride();
        ride.setId(10L);
        ride.setAvailableSeats(1); // Only 1 seat left
        ride.setTotalSeats(4);
        ride.setStatus(RideStatus.REQUESTED);

        when(rideRepo.findByIdWithLock(10L)).thenReturn(Optional.of(ride));

        CreateBookingRequest req = new CreateBookingRequest();
        req.setRideId(10L);
        req.setSeatsBooked(2); // Attempt to book 2 seats
        req.setPickup(new LocationDto(23.7, 90.4, "Pickup"));
        req.setDropoff(new LocationDto(23.8, 90.4, "Dropoff"));

        IllegalStateException ex = assertThrows(IllegalStateException.class, () -> {
            bookingService.createBooking(1L, req);
        });

        assertTrue(ex.getMessage().contains("Not enough seats available"));
        verify(rideRepo, never()).save(any());
        verify(bookingRepo, never()).save(any());
    }

    @Test
    @DisplayName("Should successfully book available seat and deduct capacity")
    void testSuccessfulBookingAndSeatDeduction() {
        BookingRepository bookingRepo = Mockito.mock(BookingRepository.class);
        RideRepository rideRepo = Mockito.mock(RideRepository.class);
        RideStopRepository stopRepo = Mockito.mock(RideStopRepository.class);
        UserRepository userRepo = Mockito.mock(UserRepository.class);

        BookingService bookingService = new BookingService(bookingRepo, rideRepo, stopRepo, userRepo);

        Ride ride = new Ride();
        ride.setId(20L);
        ride.setAvailableSeats(3);
        ride.setTotalSeats(4);
        ride.setStatus(RideStatus.REQUESTED);

        when(rideRepo.findByIdWithLock(20L)).thenReturn(Optional.of(ride));
        when(bookingRepo.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        User user = new User();
        user.setId(2L);
        user.setFullName("Peer Student");
        when(userRepo.findById(2L)).thenReturn(Optional.of(user));

        CreateBookingRequest req = new CreateBookingRequest();
        req.setRideId(20L);
        req.setSeatsBooked(1);
        req.setPickup(new LocationDto(23.7, 90.4, "Pickup"));
        req.setDropoff(new LocationDto(23.8, 90.4, "Dropoff"));
        req.setIndividualFare(new BigDecimal("150.00"));
        req.setSavings(new BigDecimal("50.00"));

        var result = bookingService.createBooking(2L, req);

        assertNotNull(result);
        assertEquals(2, ride.getAvailableSeats(), "Available seats must decrease by 1");
        assertEquals(RideStatus.CONFIRMED, ride.getStatus(), "Ride status should transition to CONFIRMED");
    }
}
