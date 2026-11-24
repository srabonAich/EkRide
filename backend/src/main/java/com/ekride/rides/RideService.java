package com.ekride.rides;

import com.ekride.common.ApiResponse;
import com.ekride.fare.service.FareCalculationService;
import com.ekride.rides.dto.CreateRideRequest;
import com.ekride.rides.dto.RideDto;
import com.ekride.routes.dto.RouteCalculationResult;
import com.ekride.routes.service.RouteService;
import com.ekride.users.User;
import com.ekride.users.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class RideService {
    private final RideRepository rideRepository;
    private final RideStopRepository stopRepository;
    private final UserRepository userRepository;
    private final RouteService routeService;
    private final FareCalculationService fareCalculationService;

    public RideService(
            RideRepository rideRepository,
            RideStopRepository stopRepository,
            UserRepository userRepository,
            RouteService routeService,
            FareCalculationService fareCalculationService) {
        this.rideRepository = rideRepository;
        this.stopRepository = stopRepository;
        this.userRepository = userRepository;
        this.routeService = routeService;
        this.fareCalculationService = fareCalculationService;
    }

    @Transactional
    public RideDto createRide(Long userId, CreateRideRequest request) {
        User creator = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        RouteCalculationResult route = routeService.calculateDirectRoute(request.getOrigin(), request.getDestination());
        BigDecimal totalFare = fareCalculationService.calculateDirectSoloFare(route.getDistanceMeters(), route.getDurationSeconds());

        Ride ride = new Ride();
        ride.setCreatorId(userId);
        ride.setOriginLat(request.getOrigin().getLat());
        ride.setOriginLng(request.getOrigin().getLng());
        ride.setOriginAddress(request.getOrigin().getAddress());
        ride.setDestinationLat(request.getDestination().getLat());
        ride.setDestinationLng(request.getDestination().getLng());
        ride.setDestinationAddress(request.getDestination().getAddress());
        ride.setTotalSeats(request.getTotalSeats() != null ? request.getTotalSeats() : 4);
        ride.setAvailableSeats(ride.getTotalSeats() - 1);
        ride.setStatus(RideStatus.REQUESTED);
        ride.setEstimatedTotalFare(totalFare);
        ride.setEstimatedDistanceMeters(route.getDistanceMeters());
        ride.setEstimatedDurationSeconds(route.getDurationSeconds());
        ride.setEncodedPolyline(route.getEncodedPolyline());
        ride.setDepartureTime(Instant.now());

        Ride savedRide = rideRepository.save(ride);

        // Create Origin and Destination Stops
        RideStop originStop = new RideStop();
        originStop.setRideId(savedRide.getId());
        originStop.setPassengerId(userId);
        originStop.setStopOrder(1);
        originStop.setStopType(StopType.ORIGIN);
        originStop.setLat(ride.getOriginLat());
        originStop.setLng(ride.getOriginLng());
        originStop.setAddress(ride.getOriginAddress());
        stopRepository.save(originStop);

        RideStop destStop = new RideStop();
        destStop.setRideId(savedRide.getId());
        destStop.setPassengerId(userId);
        destStop.setStopOrder(2);
        destStop.setStopType(StopType.DESTINATION);
        destStop.setLat(ride.getDestinationLat());
        destStop.setLng(ride.getDestinationLng());
        destStop.setAddress(ride.getDestinationAddress());
        stopRepository.save(destStop);

        List<RideStop> stops = List.of(originStop, destStop);
        return RideDto.fromEntity(savedRide, creator.getFullName(), null, stops);
    }

    public RideDto getRideById(Long rideId) {
        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new IllegalArgumentException("Ride not found: " + rideId));
        User creator = userRepository.findById(ride.getCreatorId()).orElse(null);
        User driver = ride.getDriverId() != null ? userRepository.findById(ride.getDriverId()).orElse(null) : null;
        List<RideStop> stops = stopRepository.findByRideIdOrderByStopOrderAsc(rideId);

        return RideDto.fromEntity(ride,
                creator != null ? creator.getFullName() : "Creator",
                driver != null ? driver.getFullName() : null,
                stops);
    }

    public List<RideDto> getRidesForUser(Long userId) {
        List<Ride> rides = rideRepository.findByCreatorIdOrDriverId(userId, userId);
        List<RideDto> dtos = new ArrayList<>();
        for (Ride r : rides) {
            User creator = userRepository.findById(r.getCreatorId()).orElse(null);
            User driver = r.getDriverId() != null ? userRepository.findById(r.getDriverId()).orElse(null) : null;
            List<RideStop> stops = stopRepository.findByRideIdOrderByStopOrderAsc(r.getId());
            dtos.add(RideDto.fromEntity(r,
                    creator != null ? creator.getFullName() : "Creator",
                    driver != null ? driver.getFullName() : null,
                    stops));
        }
        return dtos;
    }

    @Transactional
    public RideDto updateRideStatus(Long rideId, RideStatus newStatus, Long userId) {
        Ride ride = rideRepository.findByIdWithLock(rideId)
                .orElseThrow(() -> new IllegalArgumentException("Ride not found"));

        // Validate state transitions
        if (ride.getStatus() == RideStatus.COMPLETED || ride.getStatus() == RideStatus.CANCELLED) {
            throw new IllegalStateException("Cannot transition from terminal state: " + ride.getStatus());
        }

        ride.setStatus(newStatus);
        rideRepository.save(ride);
        return getRideById(rideId);
    }
}
