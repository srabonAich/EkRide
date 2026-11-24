-- V2__add_behind_ahead_test_users.sql: Test users starting 1-2 km behind origin and destination ahead
INSERT INTO users (id, email, password_hash, full_name, phone, university, student_id, role, rating, active)
VALUES 
(13, 'mahir@buet.ac.bd', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Mahir Faisal', '+8801711000013', 'BUET', 'BUET-ME-2021-019', 'PASSENGER', 4.90, true),
(14, 'khadija@eden.edu.bd', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Khadija Akter', '+8801711000014', 'Eden Mohila College', 'EMC-ENG-2022-045', 'PASSENGER', 4.86, true),
(15, 'rohan@dmc.edu.bd', '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYem', 'Rohan Farooq', '+8801711000015', 'Dhaka Medical College', 'DMC-MBBS-2020-088', 'PASSENGER', 4.88, true)
ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name, university = EXCLUDED.university;

INSERT INTO rides (id, creator_id, origin_lat, origin_lng, origin_address, destination_lat, destination_lng, destination_address, total_seats, available_seats, status, estimated_total_fare)
VALUES
(112, 13, 23.7258, 90.3895, 'Palashi Intersection, BUET Campus Gate', 23.7995, 90.4035, 'Kakoli Bus Stand, New Airport Road', 4, 3, 'REQUESTED', 320.00),
(113, 14, 23.7220, 90.3840, 'Azimpur Bus Stand, Near Eden College', 23.8055, 90.4045, 'Army Golf Club, New Airport Road', 4, 2, 'REQUESTED', 350.00),
(114, 15, 23.7185, 90.3985, 'Chankharpul Mor, Old Dhaka', 23.8160, 90.4180, 'Kuril Flyover / Bishwa Road Intersection', 4, 3, 'REQUESTED', 380.00)
ON CONFLICT (id) DO UPDATE SET creator_id = EXCLUDED.creator_id, origin_lat = EXCLUDED.origin_lat, origin_lng = EXCLUDED.origin_lng, origin_address = EXCLUDED.origin_address, destination_lat = EXCLUDED.destination_lat, destination_lng = EXCLUDED.destination_lng, destination_address = EXCLUDED.destination_address, status = EXCLUDED.status;
