-- V2__messenger_schema.sql: In-App Messenger Module (1-on-1 and Group Chats)

CREATE TABLE IF NOT EXISTS conversations (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL UNIQUE REFERENCES rides(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL DEFAULT 'DIRECT', -- 'DIRECT' | 'GROUP'
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE' | 'ARCHIVED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS conversation_participants (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'SEEKER', -- 'PROVIDER' | 'SEEKER'
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP WITH TIME ZONE NULL,
    last_read_message_id BIGINT NULL,
    last_read_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT uq_conversation_user UNIQUE (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id BIGINT REFERENCES users(id) ON DELETE SET NULL, -- NULL for SYSTEM messages
    message_type VARCHAR(20) NOT NULL DEFAULT 'TEXT', -- 'TEXT' | 'SYSTEM'
    content VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for optimal messenger querying and inbox sorting
CREATE INDEX IF NOT EXISTS idx_messages_conv_created ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conv_participants_user ON conversation_participants(user_id, left_at);
CREATE INDEX IF NOT EXISTS idx_conversations_ride ON conversations(ride_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_msg ON conversations(last_message_at DESC);

-- Seed initial conversations for existing seed rides (Ride 1 and Ride 2)
INSERT INTO conversations (id, ride_id, type, status, created_at, updated_at, last_message_at)
VALUES 
(1, 1, 'DIRECT', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2, 2, 'DIRECT', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (ride_id) DO NOTHING;

-- Seed creators into conversation participants
INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
VALUES 
(1, 2, 'PROVIDER', CURRENT_TIMESTAMP),
(2, 3, 'PROVIDER', CURRENT_TIMESTAMP)
ON CONFLICT (conversation_id, user_id) DO NOTHING;

-- Seed welcome system messages
INSERT INTO messages (conversation_id, sender_id, message_type, content, created_at)
VALUES 
(1, NULL, 'SYSTEM', 'Ride created. Chat is ready for matched campus peers.', CURRENT_TIMESTAMP),
(2, NULL, 'SYSTEM', 'Ride created. Chat is ready for matched campus peers.', CURRENT_TIMESTAMP);

-- Ensure demo users have the verified BCrypt hash for 'password123'
UPDATE users 
SET password_hash = '$2a$10$CsJK2qdPhdLumZISawvknerVObDUY.rvoRFYGpYbibfyas8IRrMXO'
WHERE email IN ('student1@univ.edu', 'student2@univ.edu', 'student3@univ.edu', 'driver1@univ.edu', 'admin@ekride.com');

INSERT INTO users (email, password_hash, full_name, phone, university, student_id, role, rating)
VALUES ('teststudent@univ.edu', '$2a$10$CsJK2qdPhdLumZISawvknerVObDUY.rvoRFYGpYbibfyas8IRrMXO', 'Test Student', '+8801700000000', 'University of Dhaka', 'DU-TEST-001', 'PASSENGER', 5.00)
ON CONFLICT (email) DO NOTHING;

