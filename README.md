# EkRide — Smart Student Ride-Sharing Application

EkRide is a full-stack, map-based student ride-sharing application engineered with **Flutter Web**, **Spring Boot 3 (Java 21)**, **PostgreSQL (`map_db`)**, and **Google Maps Platform** integration.

The application enables university students commuting along similar corridors to discover active peers, compare direct solo routes against shared rides, evaluate transparent fare splits, and book seats with live location tracking.

---

## 1. Architecture Overview

EkRide is architected as a lightweight, modular system designed specifically for local laptop development without heavyweight infrastructure (no Android Studio, no emulators, no Docker containers required).

```
   ┌─────────────────────────────────────────────────────────────┐
   │                  Flutter Web Frontend                       │
   │   - Modern Obsidian/Emerald Design System                   │
   │   - Interactive Canvas Map (Polylines, Waypoints, Markers)   │
   │   - Real-time Campus Commute Planner & Option Cards         │
   │   - Port: 3000                                              │
   └──────────────────────────────┬──────────────────────────────┘
                                  │ REST / WebSocket (STOMP)
                                  ▼
   ┌─────────────────────────────────────────────────────────────┐
   │                Spring Boot 3.3.5 Backend                    │
   │   - Java 21 Modular Monolith                                │
   │   - Spring Security + Stateless JWT Authentication          │
   │   - Route-Aware Matching Engine & Heuristic Insertion       │
   │   - Reconciled Fare Calculation Engine (BigDecimal)         │
   │   - Concurrency Control with Pessimistic Row Locking        │
   │   - Google Routes API v2 & Places API Client (with Demo)    │
   │   - Port: 8080                                              │
   └──────────────────────────────┬──────────────────────────────┘
                                  │ JDBC / JPA / Flyway
                                  ▼
   ┌─────────────────────────────────────────────────────────────┐
   │             PostgreSQL 18.1 Database (`map_db`)             │
   │   - Port: 5434 (Safe isolated project instance)             │
   │   - Bounding-box spatial queries (Haversine coordinate)     │
   │   - Versioned Flyway Migrations                             │
   └─────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```text
EkRide/
├── backend/
│   ├── pom.xml                               # Maven build configuration
│   └── src/
│       ├── main/
│       │   ├── java/com/ekride/
│       │   │   ├── auth/                     # Authentication & JWT tokens
│       │   │   ├── bookings/                 # Seat reservations & concurrency locks
│       │   │   ├── common/                   # Global exception handler & ApiResponse
│       │   │   ├── config/                   # Security, CORS, WebSocket, properties
│       │   │   ├── fare/                     # Transparent proportional fare splitting
│       │   │   ├── location/                 # Live GPS updates & WebSocket broadcast
│       │   │   ├── matching/                 # Route-aware peer discovery & insertion
│       │   │   ├── rides/                    # Ride requests, statuses, and stops
│       │   │   ├── routes/                   # Google Routes API & Places Autocomplete
│       │   │   ├── security/                 # JwtAuthFilter & CustomUserDetailsService
│       │   │   ├── users/                    # User entities, roles, and profiles
│       │   │   └── vehicles/                 # Vehicle and capacity management
│       │   └── resources/
│       │       ├── application.yml           # Database and application properties
│       │       └── db/migration/
│       │           └── V1__init_schema.sql   # Flyway schema migration & seed data
│       └── test/                             # Unit tests for fare, routes, bookings
├── frontend/
│   ├── pubspec.yaml                          # Flutter package dependencies
│   └── lib/
│       ├── core/theme.dart                   # Dark Obsidian/Emerald Theme
│       ├── models/                           # User, RouteOption, Stop, Booking models
│       ├── services/                         # ApiService, AuthProvider, RideProvider
│       ├── widgets/
│       │   ├── interactive_map_view.dart     # Web canvas map with vector polylines
│       │   ├── route_option_card.dart        # Comparison card (travel time, fare, detour)
│       │   └── fare_breakdown_dialog.dart    # Transparent cost reconciliation modal
│       ├── screens/
│       │   ├── auth_screen.dart              # Student sign-in & peer registration
│       │   ├── main_screen.dart              # Interactive campus commute dashboard
│       │   ├── my_bookings_screen.dart       # Booking management & live tracking
│       │   ├── driver_screen.dart            # Driver vehicle & corridor offers hub
│       │   └── profile_screen.dart           # Student ID, ratings, role switcher
│       └── main.dart                         # App entrypoint
├── scripts/
│   ├── start_db.sh                           # Start PostgreSQL on port 5434
│   ├── start_backend.sh                      # Launch Spring Boot backend
│   ├── start_frontend.sh                     # Launch Flutter Web server
│   └── stop_all.sh                           # Stop background services
├── .env.example                              # Environment template
└── README.md                                 # Documentation
```

---

## 3. Technology Stack & Key Features

### Backend
- **Framework**: Spring Boot 3.3.5 on OpenJDK 21.
- **Database**: PostgreSQL 18.1 (`map_db`).
- **Migrations**: Flyway versioned migrations.
- **Security**: Spring Security 6 with BCrypt hashing and stateless HMAC-SHA512 JWT tokens.
- **Concurrency**: Pessimistic write locking (`@Lock(LockModeType.PESSIMISTIC_WRITE)`) on seat reservation transactions to strictly eliminate overbooking under race conditions.
- **Geospatial & Spatial Indexing**: Coordinate-based bounding box filtering with spherical Haversine formulas in Java and SQL (no external C extensions required).
- **Google Maps Platform Integration**:
  - **Routes API v2**: `https://routes.googleapis.com/directions/v2:computeRoutes` for traffic-aware duration, distance, and encoded polylines.
  - **Places API (New)**: `https://places.googleapis.com/v1/places:autocomplete` for place search.
  - **Graceful Demo Fallback**: When the API key is missing or quota-limited, real-time simulated Dhaka corridor routing automatically engages with clear indicator labels.

### Frontend
- **Framework**: Flutter 3.32.5 (Dart 3.8.1).
- **Target**: Flutter Web running in Google Chrome (no emulator required).
- **State Management**: Reactive `Provider` architecture.
- **Interactive Map**: High-performance canvas vector map with real-time polyline rendering, dynamic pan/zoom, coordinate transformation, and custom beacons for student origins, destinations, peer pickups, and driver vehicle animations.
- **Responsive Layout**: Adapts between widescreen laptop layout (split panel and map) and compact browser windows.

---

## 4. Transparent Fare Allocation & Route-Aware Matching

### The Matching Engine
1. **Corridor Bounding Box**: Discovers active rides and student peers within a configurable radius (default: 3 km).
2. **Heuristic Waypoint Insertion**: Generates candidate sequences respecting the **pickup-before-dropoff constraint**:
   - `Origin_A → Pickup_B → Dropoff_B → Destination_A`
   - `Origin_A → Pickup_B → Destination_A → Dropoff_B`
3. **Detour Constraints**: Calculates $\Delta \text{Distance}$ and $\Delta \text{Duration}$ against the baseline solo route. Rejects or flags routes that exceed maximum detour limits.
4. **Ranking Algorithm**: Ranks feasible options using a balanced composite score:
   $$\text{Score} = (1.5 \times \text{Savings}) - (2.0 \times \text{Detour Minutes}) + (5.0 \times \text{Peer Rating})$$

### The Fare Splitting Algorithm
- **Base Tariff**: ৳50.00
- **Distance Rate**: ৳25.00 / km
- **Time Rate**: ৳2.00 / min
- **Minimum Fare**: ৳60.00
- **Platform Fee**: 10%
- **Reconciliation Rule**: Baseline solo fares are computed for every participant. Total vehicle fare is then allocated proportionally, with the final passenger absorbing rounding deltas so that:
  $$\sum \text{Individual Shares} \equiv \text{Total Vehicle Meter Fare}$$
  All calculations use `BigDecimal` with `RoundingMode.HALF_UP` (zero floating-point precision leaks).

---

## 5. Quick Start Instructions (Cross-Platform / Any Machine)

### Prerequisites
- Java 21 (`java -version`)
- Maven (`mvn -version`)
- Python 3 (`python3 --version`)
- Flutter SDK (`flutter --version`) *(Optional if serving pre-built web)*
- Docker / Docker Compose *(Optional, recommended for instant PostgreSQL setup)*
- Google Chrome

---

### Step 1: Clone & Configure Environment
```bash
cp .env.example .env
```
*(Optional: If you have a Google Maps Platform key, add it in `.env` or in an `Api-key.txt` file. If left blank, EkRide automatically runs in offline demo mode with real-road OSRM routing!)*

---

### Step 2: Start PostgreSQL Database (`map_db`)

**Option A (Using Docker Compose - Recommended on any OS):**
```bash
docker compose up -d
```

**Option B (Using the automated helper script):**
```bash
./scripts/start_db.sh
```
*Note: Connects to PostgreSQL on port 5434 with database `map_db` (username: `postgres`, password: `postgres`).*

---

### Step 3: Run the Full Application

You can start everything with a single command:
```bash
./start.sh
```
Or start each service separately:

**In Terminal 1 (Spring Boot Backend):**
```bash
./scripts/start_backend.sh
```
*Backend initializes on `http://localhost:8080`. Flyway automatically verifies the schema and pre-loads sample student seed data.*

**In Terminal 2 (Flutter Web Frontend):**
```bash
./scripts/start_frontend.sh
```
Or run directly with Flutter in development mode:
```bash
cd frontend
flutter run -d chrome --web-port=3000
```
Open **`http://localhost:3000`** in Google Chrome!

To stop all background services at any time:
```bash
./stop.sh
```

---

## 6. Seed Accounts & Verification

The database includes pre-seeded verified university student accounts:

| Email | Password | Role | University |
|---|---|---|---|
| `teststudent@univ.edu` | `password123` | PASSENGER | University of Dhaka |
| `student1@univ.edu` | `password123` | PASSENGER | University of Dhaka |
| `student2@univ.edu` | `password123` | PASSENGER | BRAC University |
| `student3@univ.edu` | `password123` | PASSENGER | North South University |
| `driver1@univ.edu` | `password123` | DRIVER | University of Dhaka |

### Testing the Workflow in the App:
1. Open `http://localhost:3000` and sign in with `teststudent@univ.edu` / `password123`.
2. Notice the pre-loaded Dhaka University TSC to Banani 11 corridor.
3. Observe **Nearby Student Peers** along the corridor (e.g., Nusrat Jahan from BRAC University, Tanvir Hasan from NSU).
4. Review the **Feasible Route Options**:
   - **Direct Solo Ride**: ৳346.81 (Fastest, zero detour).
   - **Shared Ride Option 1**: Detour of only 4 mins (+1.4 km), fare drops to **৳183.90** (saving **৳162.91** or **47%**!).
5. Click **"Transparent Fare Breakdown"** to inspect the mathematical cost allocation.
6. Click **"Select & Confirm"** to book the seat with concurrency protection.
7. Click **"My Rides"** to view active bookings and trigger live simulated tracking on the interactive map!

---

## 7. Backend REST API Reference

All REST endpoints are versioned under `/api/v1`:

### Authentication & Profiles
- `POST /api/v1/auth/register` — Register a new student account.
- `POST /api/v1/auth/login` — Sign in and receive a JWT token.
- `GET /api/v1/users/me` — Retrieve current user profile.
- `PUT /api/v1/users/me` — Update student profile.
- `POST /api/v1/users/switch-role` — Switch between PASSENGER and DRIVER modes.

### Routes & Google Maps Integration
- `POST /api/v1/routes/calculate` — Compute direct or multi-stop waypoint routes with distance, duration, and encoded polylines.
- `GET /api/v1/routes/autocomplete?query={q}` — Places autocomplete with Dhaka campus landmarks.

### Matching & Passenger Discovery
- `GET /api/v1/rides/nearby?lat={lat}&lng={lng}` — Discover active student peers along the corridor.
- `POST /api/v1/rides/options` — Compute feasible route alternatives (solo vs. shared) with detour metrics and savings.

### Rides & Bookings
- `POST /api/v1/rides` — Post a new ride request or driver offer.
- `GET /api/v1/rides/{rideId}` — Get ride details and ordered stops.
- `GET /api/v1/rides` — List rides created by the user.
- `POST /api/v1/bookings` — Reserve seats on a ride (pessimistic lock concurrency control).
- `GET /api/v1/bookings/me` — List current user bookings.
- `POST /api/v1/bookings/{bookingId}/cancel` — Cancel a booking and release reserved seats.

### Location & Real-Time Tracking
- `POST /api/v1/location/update` — Record live GPS position (simulated or real).
- `GET /api/v1/location/rides/{rideId}` — Retrieve recent breadcrumb locations.
- `WS /ws` — WebSocket STOMP endpoint (`/topic/rides/{rideId}/location`).

---

## 8. Automated Tests

Run backend unit and concurrency tests:
```bash
cd backend && mvn test
# or from root:
mvn test -f backend/pom.xml
```

Run frontend Flutter tests:
```bash
cd frontend && flutter test
```
