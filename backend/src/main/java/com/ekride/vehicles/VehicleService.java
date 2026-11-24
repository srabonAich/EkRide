package com.ekride.vehicles;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class VehicleService {
    private final VehicleRepository vehicleRepository;

    public VehicleService(VehicleRepository vehicleRepository) {
        this.vehicleRepository = vehicleRepository;
    }

    public List<Vehicle> getVehiclesByDriver(Long driverId) {
        return vehicleRepository.findByDriverId(driverId);
    }

    public Vehicle getActiveVehicle(Long driverId) {
        return vehicleRepository.findFirstByDriverIdAndActiveTrue(driverId).orElse(null);
    }

    @Transactional
    public Vehicle registerVehicle(Long driverId, String make, String model, String licensePlate, Integer seats, String color) {
        Vehicle vehicle = new Vehicle();
        vehicle.setDriverId(driverId);
        vehicle.setMake(make);
        vehicle.setModel(model);
        vehicle.setLicensePlate(licensePlate);
        vehicle.setTotalSeats(seats != null ? seats : 4);
        vehicle.setColor(color);
        vehicle.setActive(true);
        return vehicleRepository.save(vehicle);
    }
}
