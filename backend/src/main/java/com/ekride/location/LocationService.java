package com.ekride.location;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class LocationService {
    private final LocationUpdateRepository locationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public LocationService(LocationUpdateRepository locationRepository, SimpMessagingTemplate messagingTemplate) {
        this.locationRepository = locationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public LocationUpdate saveAndBroadcastLocation(LocationUpdateDto dto) {
        LocationUpdate update = new LocationUpdate();
        update.setRideId(dto.getRideId());
        update.setUserId(dto.getUserId());
        update.setLat(dto.getLat());
        update.setLng(dto.getLng());
        update.setHeading(dto.getHeading());
        update.setSpeed(dto.getSpeed());
        update.setIsSimulated(dto.isSimulated());

        LocationUpdate saved = locationRepository.save(update);

        // Broadcast to WebSocket subscribers for this specific active ride
        if (dto.getRideId() != null) {
            messagingTemplate.convertAndSend("/topic/rides/" + dto.getRideId() + "/location", dto);
        }

        return saved;
    }

    public List<LocationUpdate> getRecentLocations(Long rideId) {
        return locationRepository.findTop20ByRideIdOrderByCreatedAtDesc(rideId);
    }
}
