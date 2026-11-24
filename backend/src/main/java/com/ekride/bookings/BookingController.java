package com.ekride.bookings;

import com.ekride.bookings.dto.BookingDto;
import com.ekride.bookings.dto.CreateBookingRequest;
import com.ekride.common.ApiResponse;
import com.ekride.security.CustomUserDetails;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/bookings")
public class BookingController {
    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BookingDto>> createBooking(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateBookingRequest request) {
        BookingDto booking = bookingService.createBooking(userDetails.getUser().getId(), request);
        return ResponseEntity.ok(ApiResponse.ok("Booking confirmed", booking));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<BookingDto>>> getMyBookings(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<BookingDto> list = bookingService.getBookingsForPassenger(userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PostMapping("/{bookingId}/cancel")
    public ResponseEntity<ApiResponse<BookingDto>> cancelBooking(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Long bookingId) {
        BookingDto cancelled = bookingService.cancelBooking(bookingId, userDetails.getUser().getId());
        return ResponseEntity.ok(ApiResponse.ok("Booking cancelled", cancelled));
    }
}
