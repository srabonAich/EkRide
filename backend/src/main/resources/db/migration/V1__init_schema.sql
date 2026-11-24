-- V1__init_schema.sql: Initial schema for Smart Student Ride-Sharing Application

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    university VARCHAR(255),
    student_id VARCHAR(100),
    role VARCHAR(50) NOT NULL DEFAULT 'PASSENGER',
    rating NUMERIC(3, 2) DEFAULT 5.00,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicles (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    license_plate VARCHAR(50) NOT NULL UNIQUE,
    total_seats INTEGER NOT NULL DEFAULT 4,
    color VARCHAR(50),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rides (
    id BIGSERIAL PRIMARY KEY,
    creator_id BIGINT NOT NULL REFERENCES users(id),
    driver_id BIGINT REFERENCES users(id),
    origin_lat DOUBLE PRECISION NOT NULL,
    origin_lng DOUBLE PRECISION NOT NULL,
    origin_address VARCHAR(500) NOT NULL,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lng DOUBLE PRECISION NOT NULL,
    destination_address VARCHAR(500) NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_seats INTEGER NOT NULL DEFAULT 4,
    available_seats INTEGER NOT NULL DEFAULT 3,
    status VARCHAR(50) NOT NULL DEFAULT 'REQUESTED',
    estimated_total_fare NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    estimated_distance_meters BIGINT DEFAULT 0,
    estimated_duration_seconds BIGINT DEFAULT 0,
    encoded_polyline TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ride_stops (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    passenger_id BIGINT REFERENCES users(id),
    stop_order INTEGER NOT NULL,
    stop_type VARCHAR(50) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    address VARCHAR(500),
    estimated_arrival_time TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS bookings (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    passenger_id BIGINT NOT NULL REFERENCES users(id),
    seats_booked INTEGER NOT NULL DEFAULT 1,
    pickup_lat DOUBLE PRECISION NOT NULL,
    pickup_lng DOUBLE PRECISION NOT NULL,
    pickup_address VARCHAR(500),
    dropoff_lat DOUBLE PRECISION NOT NULL,
    dropoff_lng DOUBLE PRECISION NOT NULL,
    dropoff_address VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    individual_fare NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    savings NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS location_updates (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT REFERENCES rides(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    is_simulated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_origin_coords ON rides(origin_lat, origin_lng);
CREATE INDEX IF NOT EXISTS idx_rides_dest_coords ON rides(destination_lat, destination_lng);
CREATE INDEX IF NOT EXISTS idx_bookings_ride ON bookings(ride_id);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger ON bookings(passenger_id);
CREATE INDEX IF NOT EXISTS idx_location_ride_time ON location_updates(ride_id, created_at);

-- Seed Initial Users (Password: 'password123' BCrypt hash: $2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem)
INSERT INTO users (email, password_hash, full_name, phone, university, student_id, role, rating)
VALUES 
('student1@univ.edu', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Abrar Rahman', '+8801711000001', 'Dhaka University', 'DU-CSE-2021-042', 'PASSENGER', 4.95),
('student2@univ.edu', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Nusrat Jahan', '+8801711000002', 'BRAC University', 'BRAC-CS-2022-118', 'PASSENGER', 4.88),
('student3@univ.edu', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Tanvir Hasan', '+8801711000003', 'North South University', 'NSU-ECE-2020-077', 'PASSENGER', 4.90),
('driver1@univ.edu', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Kazi Farhan', '+8801711000004', 'Dhaka University', 'DU-BBA-2019-015', 'DRIVER', 4.97),
('admin@ekride.com', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'System Administrator', '+8801711999999', 'EkRide Central', 'ADM-001', 'ADMIN', 5.00)
ON CONFLICT (email) DO NOTHING;

-- Seed Driver Vehicle
INSERT INTO vehicles (driver_id, make, model, license_plate, total_seats, color)
VALUES (4, 'Toyota', 'Corolla Hybrid', 'DHAKA-METRO-GA-45-8899', 4, 'Silver Metallic')
ON CONFLICT (license_plate) DO NOTHING;

-- Seed Sample Active Ride Request (Dhaka University Curzon Hall -> Banani 11)
INSERT INTO rides (creator_id, origin_lat, origin_lng, origin_address, destination_lat, destination_lng, destination_address, total_seats, available_seats, status, estimated_total_fare, estimated_distance_meters, estimated_duration_seconds)
VALUES 
(2, 23.7262, 90.4013, 'Curzon Hall, University of Dhaka', 23.7937, 90.4066, 'Road 11, Banani, Dhaka', 4, 3, 'REQUESTED', 280.00, 9500, 1800),
(3, 23.7465, 90.3760, 'Dhanmondi 32, Dhaka', 23.7937, 90.4066, 'Road 11, Banani, Dhaka', 4, 2, 'REQUESTED', 220.00, 7200, 1400);
