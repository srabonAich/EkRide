import re

file_path = 'backend/src/main/java/com/ekride/matching/service/PassengerDiscoveryService.java'

with open(file_path, 'r') as f:
    code = f.read()

# Replacement to add c4, c5, c6 right after c3
addition = """
        // ─────────────────────────────────────────────────────────────
        // CANDIDATE 4: Abrar Fahim - Commercial / Transit Node Student
        // ─────────────────────────────────────────────────────────────
        double p4Lat, p4Lng;
        String p4Addr;
        double d4Lat, d4Lng;
        String d4Addr;

        if (isBracOrigin) {
            p4Lat = 23.7665; p4Lng = 90.4042;
            p4Addr = "Tejgaon Nabisco Commercial Area";
            d4Lat = 23.7540; d4Lng = 90.3750;
            d4Addr = "Dhanmondi 27 / Sobhanbagh";
        } else if (isDuOrigin) {
            p4Lat = 23.7485; p4Lng = 90.3945;
            p4Addr = "Banglamotor Intersection Curbside";
            d4Lat = 23.7905; d4Lng = 90.4035;
            d4Addr = "Banani Chairman Bari";
        } else if (isNsuOrigin) {
            p4Lat = 23.7780; p4Lng = 90.4010;
            p4Addr = "Mohakhali Flyover Approach";
            d4Lat = 23.7480; d4Lng = 90.3950;
            d4Addr = "Banglamotor Central Stop";
        } else {
            p4Lat = oLat + 0.35 * (dLat - oLat) + 0.0015;
            p4Lng = oLng + 0.35 * (dLng - oLng) - 0.0015;
            p4Addr = "Commercial Transit Hub";
            d4Lat = oLat + 0.80 * (dLat - oLat);
            d4Lng = oLng + 0.80 * (dLng - oLng);
            d4Addr = "Destination Transit Hub";
        }

        CandidatePassengerDto c4 = new CandidatePassengerDto();
        c4.setRideId(104L);
        c4.setPassengerId(5L);
        c4.setPassengerName("Abrar Fahim");
        c4.setUniversity(isBracOrigin ? "BUET" : isDuOrigin ? "IBA, University of Dhaka" : "BUET");
        c4.setRating(4.91);
        c4.setPickupLat(p4Lat);
        c4.setPickupLng(p4Lng);
        c4.setPickupAddress(p4Addr);
        c4.setDropoffLat(d4Lat);
        c4.setDropoffLng(d4Lng);
        c4.setDropoffAddress(d4Addr);
        c4.setPickupDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(oLat, oLng, p4Lat, p4Lng));
        c4.setDropoffDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(dLat, dLng, d4Lat, d4Lng));
        c4.setAvailableSeats(3);
        list.add(c4);

        // ─────────────────────────────────────────────────────────────
        // CANDIDATE 5: Mehjabin Chowdhury - Multi-Lane Curbside Passenger
        // ─────────────────────────────────────────────────────────────
        double p5Lat, p5Lng;
        String p5Addr;
        double d5Lat, d5Lng;
        String d5Addr;

        if (isBracOrigin) {
            p5Lat = 23.7515; p5Lng = 90.3895;
            p5Addr = "Panthapath Bashundhara City Curbside";
            d5Lat = 23.7470; d5Lng = 90.3765;
            d5Addr = "Dhanmondi 32 Lake Gate";
        } else if (isDuOrigin) {
            p5Lat = 23.7580; p5Lng = 90.3880;
            p5Addr = "Farmgate / Indira Road Curbside";
            d5Lat = 23.7945; d5Lng = 90.4040;
            d5Addr = "Kakoli Bus Stand / Banani";
        } else if (isNsuOrigin) {
            p5Lat = 23.8220; p5Lng = 90.4180;
            p5Addr = "Bishwa Road / Airport Road Junction";
            d5Lat = 23.7310; d5Lng = 90.4030;
            d5Addr = "Matsya Bhaban / Shahbagh";
        } else {
            p5Lat = oLat + 0.50 * (dLat - oLat) - 0.0018;
            p5Lng = oLng + 0.50 * (dLng - oLng) + 0.0018;
            p5Addr = "Mid-Corridor Station";
            d5Lat = oLat + 0.90 * (dLat - oLat);
            d5Lng = oLng + 0.90 * (dLng - oLng);
            d5Addr = "Near-Destination Stop";
        }

        CandidatePassengerDto c5 = new CandidatePassengerDto();
        c5.setRideId(105L);
        c5.setPassengerId(6L);
        c5.setPassengerName("Mehjabin Chowdhury");
        c5.setUniversity(isBracOrigin ? "Dhaka Medical College" : "North South University");
        c5.setRating(4.87);
        c5.setPickupLat(p5Lat);
        c5.setPickupLng(p5Lng);
        c5.setPickupAddress(p5Addr);
        c5.setDropoffLat(d5Lat);
        c5.setDropoffLng(d5Lng);
        c5.setDropoffAddress(d5Addr);
        c5.setPickupDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(oLat, oLng, p5Lat, p5Lng));
        c5.setDropoffDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(dLat, dLng, d5Lat, d5Lng));
        c5.setAvailableSeats(2);
        list.add(c5);

        // ─────────────────────────────────────────────────────────────
        // CANDIDATE 6: Rafid Ahmed - Destination Alight-Together Student
        // ─────────────────────────────────────────────────────────────
        double p6Lat, p6Lng;
        String p6Addr;
        double d6Lat, d6Lng;
        String d6Addr;

        if (isBracOrigin) {
            p6Lat = 23.7480; p6Lng = 90.3800;
            p6Addr = "Kalabagan Bus Stand";
            d6Lat = 23.7465; d6Lng = 90.3760;
            d6Addr = "Dhanmondi 32 (Alight Together)";
        } else if (isDuOrigin) {
            p6Lat = 23.7735; p6Lng = 90.3925;
            p6Addr = "Jahangir Gate (Near Cantonment)";
            d6Lat = 23.7937; d6Lng = 90.4066;
            d6Addr = "Banani 11 Gate (Alight Together)";
        } else if (isNsuOrigin) {
            p6Lat = 23.7600; p6Lng = 90.3970;
            p6Addr = "Tejgaon Prime Transit";
            d6Lat = 23.7380; d6Lng = 90.3950;
            d6Addr = "Shahbagh (Alight Together)";
        } else {
            p6Lat = oLat + 0.65 * (dLat - oLat);
            p6Lng = oLng + 0.65 * (dLng - oLng);
            p6Addr = "Corridor Alight Station";
            d6Lat = dLat;
            d6Lng = dLng;
            d6Addr = destination.getAddress();
        }

        CandidatePassengerDto c6 = new CandidatePassengerDto();
        c6.setRideId(106L);
        c6.setPassengerId(7L);
        c6.setPassengerName("Rafid Ahmed");
        c6.setUniversity(isBracOrigin ? "AIUB" : "BRAC University");
        c6.setRating(4.93);
        c6.setPickupLat(p6Lat);
        c6.setPickupLng(p6Lng);
        c6.setPickupAddress(p6Addr);
        c6.setDropoffLat(d6Lat);
        c6.setDropoffLng(d6Lng);
        c6.setDropoffAddress(d6Addr);
        c6.setPickupDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(oLat, oLng, p6Lat, p6Lng));
        c6.setDropoffDistanceMeters(RoutePolylineUtils.haversineDistanceMeters(dLat, dLng, d6Lat, d6Lng));
        c6.setAvailableSeats(3);
        list.add(c6);

        return list;
    }
"""

old_target = "        list.add(c3);\n\n        return list;\n    }"
if old_target in code:
    code = code.replace(old_target, "        list.add(c3);" + addition)
    with open(file_path, 'w') as f:
        f.write(code)
    print("Added Candidates 4, 5, 6 successfully to PassengerDiscoveryService.java")
else:
    print("Target string not found in PassengerDiscoveryService.java")
