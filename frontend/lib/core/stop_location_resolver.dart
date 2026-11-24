import "package:flutter/material.dart";
import "dart:math" as math;
import "package:latlong2/latlong.dart";
import "package:ekride_frontend/models/candidate.dart";
import "package:ekride_frontend/models/stop.dart";

class StopLocationDetails {
  final String exactLandmark;
  final String passengerHomeArea;
  final String walkingGuide;
  final double? walkingDistanceMeters;
  final int? walkingMinutes;
  final bool hasWalkConnection;
  final LatLng? peerLocation;

  const StopLocationDetails({
    required this.exactLandmark,
    required this.passengerHomeArea,
    required this.walkingGuide,
    this.walkingDistanceMeters,
    this.walkingMinutes,
    this.hasWalkConnection = false,
    this.peerLocation,
  });
}

class GoogleMapsWaypointPin {
  final int waypointIndex;
  final String letter; // "Start", "A", "B", "C", "D", ...
  final String pinBadge; // "Start", "Maps Pin (A)", "Maps Pin (B)", "Maps Pin (D - Final Destination)"
  final String roleText;
  final String exactLandmark;
  final String mainArea;
  final String walkingGuide;
  final Color pinColor;
  final IconData pinIcon;
  final LatLng coordinate;
  final List<RouteStop> matchedStops;
  final bool isStart;
  final bool isFinalDest;

  const GoogleMapsWaypointPin({
    required this.waypointIndex,
    required this.letter,
    required this.pinBadge,
    required this.roleText,
    required this.exactLandmark,
    required this.mainArea,
    required this.walkingGuide,
    required this.pinColor,
    required this.pinIcon,
    required this.coordinate,
    required this.matchedStops,
    this.isStart = false,
    this.isFinalDest = false,
  });
}

class StopLocationResolver {
  static String getLetter(int index) {
    if (index == 0) return "Start";
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final letterIndex = index - 1;
    if (letterIndex >= 0 && letterIndex < letters.length) {
      return letters[letterIndex];
    }
    return "$index";
  }

  static Color getStopColor(String type, int index) {
    if (index == 0) return const Color(0xFF3B82F6); // Blue for Google Maps Start
    switch (type) {
      case "PICKUP":
        return const Color(0xFF10B981); // Emerald Green for Pickup
      case "DROPOFF":
        return const Color(0xFFF59E0B); // Amber / Orange for Dropoff
      case "DESTINATION":
        return const Color(0xFFEF4444); // Red for Destination
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  static IconData getStopIcon(String type, int index) {
    if (index == 0) return Icons.trip_origin_rounded;
    switch (type) {
      case "PICKUP":
        return Icons.person_add_alt_1_rounded;
      case "DROPOFF":
        return Icons.person_remove_alt_1_rounded;
      case "DESTINATION":
        return Icons.flag_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  static String getRoleText(RouteStop s, bool isBn) {
    final name = s.passengerName ?? (isBn ? "সহযাত্রী" : "Peer");
    switch (s.type) {
      case "ORIGIN":
        return isBn ? "আপনার পিকআপ (শুরুর পয়েন্ট)" : "Your Pickup (Start Point)";
      case "PICKUP":
        return isBn ? "পিকআপ: $name" : "Pickup: $name";
      case "DROPOFF":
        return isBn ? "ড্রপঅফ: $name" : "Dropoff: $name";
      case "DESTINATION":
        return isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your Final Destination";
      default:
        return isBn ? "যাত্রাবিরতি স্টপ" : "Stop Point";
    }
  }

  static String getMicroSummary(RouteStop s, int index, bool isBn) {
    if (index == 0 || s.type == "ORIGIN") {
      return isBn ? "আপনার পিকআপ" : "Your Pickup";
    }
    final rawName = s.passengerName ?? (isBn ? "সহযাত্রী" : "Peer");
    final firstName = rawName.trim().split(" ").first;
    switch (s.type) {
      case "PICKUP":
        return isBn ? "$firstName উঠবে" : "$firstName (Pick)";
      case "DROPOFF":
        return isBn ? "$firstName নামবে" : "$firstName (Drop)";
      case "DESTINATION":
        return isBn ? "আপনার গন্তব্য" : "Your Dest";
      default:
        return isBn ? "স্টপ" : "Stop";
    }
  }

  static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Resolves the landmark name to precisely match Google Maps Places nomenclature
  static String resolveGoogleMapsLandmarkName(double lat, double lng, String fallbackAddress, bool isBn) {
    final addrLower = fallbackAddress.toLowerCase();

    // 1. Shahbagh / National Museum (Tanvir - Google Maps Pin A)
    if (addrLower.contains('shahbagh') ||
        addrLower.contains('museum') ||
        ((lat - 23.7371).abs() < 0.003 && (lng - 90.3956).abs() < 0.003)) {
      return isBn
          ? "mdripon, P9PW+R75, ঢাকা (শাহবাগ কার্বসাইড, জাতীয় জাদুঘর গেট)"
          : "mdripon, P9PW+R75, Dhaka (Shahbagh Curbside, National Museum Gate)";
    }

    // 2. Banani Road 11 / company Gold Bell Corporation (Destination / Banani Dropoffs - Google Maps Pin D)
    if (addrLower.contains('road 11') ||
        addrLower.contains('gold bell') ||
        ((lat - 23.7937).abs() < 0.003 && (lng - 90.4066).abs() < 0.004)) {
      return isBn
          ? "company Gold Bell Corporation, House #27 Road 11, Banani, ঢাকা"
          : "company Gold Bell Corporation, House #27 Road 11, Banani, Dhaka";
    }

    // 3. Mohakhali Flyover / Transit Hub (Nusrat Dropoff - Google Maps Pin C)
    if (addrLower.contains('mohakhali') ||
        ((lat - 23.7806).abs() < 0.004 && (lng - 90.3986).abs() < 0.004)) {
      return isBn
          ? "47 Mohakhali Flyover, ঢাকা (মহাখালী ট্রানজিট হাব)"
          : "47 Mohakhali Flyover, Dhaka (Mohakhali Transit Hub)";
    }

    // 4. Farmgate / Indira Road (Mehjabin - Google Maps Pin B)
    if (addrLower.contains('farmgate') ||
        addrLower.contains('indira') ||
        ((lat - 23.7580).abs() < 0.005 && (lng - 90.3880).abs() < 0.005)) {
      return isBn
          ? "ফার্মগেট মোড় Farmgate, Indira Road Curbside, ঢাকা"
          : "ফার্মগেট মোড় Farmgate, Indira Road Curbside, Dhaka";
    }

    // 5. DU / Raju Memorial Sculpture / TSC (Start Point)
    if (addrLower.contains('raju') ||
        addrLower.contains('tsc') ||
        addrLower.contains('dhaka university') ||
        ((lat - 23.7328).abs() < 0.003 && (lng - 90.3957).abs() < 0.003)) {
      return isBn
          ? "রাজু ভাস্কর্য, ঢাকা বিশ্ববিদ্যালয় (Raju Memorial Sculpture)"
          : "Raju Memorial Sculpture, University of Dhaka";
    }

    // 6. Curzon Hall
    if (addrLower.contains('curzon') ||
        ((lat - 23.7262).abs() < 0.003 && (lng - 90.4013).abs() < 0.003)) {
      return isBn
          ? "কার্জন হল, ঢাকা বিশ্ববিদ্যালয় (Curzon Hall)"
          : "Curzon Hall, University of Dhaka";
    }

    // 7. Banglamotor
    if (addrLower.contains('banglamotor') ||
        ((lat - 23.7485).abs() < 0.003 && (lng - 90.3945).abs() < 0.003)) {
      return isBn
          ? "বাংলামোটর মোড়, কাজী নজরুল ইসলাম এভিনিউ (Banglamotor Mor)"
          : "Banglamotor Mor, Kazi Nazrul Islam Ave, Dhaka";
    }

    // 8. Jahangir Gate
    if (addrLower.contains('jahangir') ||
        ((lat - 23.7735).abs() < 0.003 && (lng - 90.3925).abs() < 0.003)) {
      return isBn
          ? "জাহাঙ্গীর গেট, নিউ এয়ারপোর্ট রোড (Jahangir Gate)"
          : "Jahangir Gate, New Airport Rd, Dhaka";
    }

    // 9. Banani Chairman Bari
    if (addrLower.contains('chairman') ||
        ((lat - 23.7905).abs() < 0.0025 && (lng - 90.4035).abs() < 0.0025)) {
      return isBn
          ? "বনানী চেয়ারম্যান বাড়ি, নিউ এয়ারপোর্ট রোড"
          : "Banani Chairman Bari, New Airport Rd, Dhaka";
    }

    // 10. Dhanmondi 32 Lake Gate
    if (addrLower.contains('dhanmondi') ||
        ((lat - 23.7465).abs() < 0.004 && (lng - 90.3760).abs() < 0.004)) {
      return isBn
          ? "ধানমন্ডি ৩২ লেক গেট, মিরপুর রোড (Dhanmondi 32 Lake Gate)"
          : "Dhanmondi 32 Lake Gate, Mirpur Rd, Dhaka";
    }

    // 11. BRAC University / Merul Badda
    if (addrLower.contains('brac') ||
        ((lat - 23.7710).abs() < 0.004 && (lng - 90.4255).abs() < 0.004)) {
      return isBn
          ? "ব্র্যাক ইউনিভার্সিটি মেরুল বাড্ডা গেট (BRAC University)"
          : "BRAC University Merul Badda Gate, DIT Road";
    }

    // 12. Rampura Bridge
    if (addrLower.contains('rampura') ||
        ((lat - 23.7668).abs() < 0.004 && (lng - 90.4246).abs() < 0.004)) {
      return isBn
          ? "রামপুরা ব্রিজ / মেরুল বাড্ডা লিংক রোড"
          : "Rampura Bridge / Merul Badda Corridor, DIT Rd";
    }

    // 13. Hatirpool / Sonargaon Road (Sadia - Sonargaon Road / Katabon Curbside)
    if (addrLower.contains('hatirpool') ||
        addrLower.contains('sonargaon') ||
        addrLower.contains('katabon') ||
        addrLower.contains('eastern plaza') ||
        addrLower.contains('sheltech') ||
        addrLower.contains('cafero') ||
        ((lat - 23.7420).abs() < 0.003 && (lng - 90.3895).abs() < 0.003) ||
        ((lat - 23.7410).abs() < 0.005 && (lng - 90.3860).abs() < 0.005) ||
        ((lat - 23.7450).abs() < 0.005 && (lng - 90.3920).abs() < 0.005)) {
      return isBn
          ? "সোনারগাঁও রোড / কাটাবন মোড় কার্বসাইড, ঢাকা"
          : "Sonargaon Road / Katabon Mor Curbside, Dhaka";
    }

    // 14. Lalmatia / Mirpur Road (Nabil - Mirpur Road Aarong Curbside, 0 Goli Entry)
    if (addrLower.contains('aarong') ||
        addrLower.contains('lalmatia') ||
        ((lat - 23.7575).abs() < 0.003 && (lng - 90.3750).abs() < 0.003) ||
        ((lat - 23.7565).abs() < 0.004 && (lng - 90.3725).abs() < 0.004)) {
      return isBn
          ? "আড়ং লালমাটিয়া, মিরপুর রোড কার্বসাইড, ঢাকা"
          : "Aarong Lalmatia, Mirpur Road Curbside, Dhaka";
    }

    // 15. Moghbazar Nayatola / Tajuddin Ahmad Sarani (Anika - Tajuddin Sarani Curbside)
    if (addrLower.contains('nayatola') ||
        addrLower.contains('tajuddin') ||
        addrLower.contains('moghbazar') ||
        ((lat - 23.7550).abs() < 0.003 && (lng - 90.4050).abs() < 0.003) ||
        ((lat - 23.7540).abs() < 0.004 && (lng - 90.4080).abs() < 0.004)) {
      return isBn
          ? "শহীদ তাজউদ্দীন আহমদ সরণি, মগবাজার কার্বসাইড, ঢাকা"
          : "Shaheed Tajuddin Ahmad Sarani, Moghbazar Curbside, Dhaka";
    }

    // Fallback: clean up raw address
    final clean = fallbackAddress.replaceAll("(Curbside Stop on Route)", "")
        .replaceAll("(Curbside Dropoff on Route)", "")
        .replaceAll("(Alight Together)", "")
        .replaceAll("(Board Together)", "")
        .trim();
    return clean.isNotEmpty ? clean : (isBn ? "রোড কার্বসাইড স্পট" : "Curbside Spot");
  }

  /// Resolves unified Google Maps Waypoint Pins matching Google Maps navigation 100%
  static List<GoogleMapsWaypointPin> resolveGoogleMapsPins({
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required List<RouteStop> stops,
    List<CandidatePassenger>? candidates,
    required bool isBn,
  }) {
    final ordered = List<RouteStop>.from(stops)
      ..sort((a, b) => a.order.compareTo(b.order));

    if (ordered.isEmpty) {
      final startLandmark = resolveGoogleMapsLandmarkName(originLat, originLng, originAddress, isBn);
      final destLandmark = resolveGoogleMapsLandmarkName(destLat, destLng, destAddress, isBn);
      return [
        GoogleMapsWaypointPin(
          waypointIndex: 0,
          letter: "Start",
          pinBadge: isBn ? "শুরুর পয়েন্ট (Start)" : "Google Maps Start",
          roleText: isBn ? "আপনার পিকআপ (শুরুর পয়েন্ট)" : "Your Pickup (Start Point)",
          exactLandmark: startLandmark,
          mainArea: originAddress.isNotEmpty ? originAddress : (isBn ? "ক্যাম্পাস এরিয়া" : "Campus Area"),
          walkingGuide: isBn ? "আপনার যাত্রার শুরুর পয়েন্ট" : "Your trip starting point",
          pinColor: const Color(0xFF3B82F6),
          pinIcon: Icons.trip_origin_rounded,
          coordinate: LatLng(originLat, originLng),
          matchedStops: [],
          isStart: true,
          isFinalDest: false,
        ),
        GoogleMapsWaypointPin(
          waypointIndex: 1,
          letter: "A",
          pinBadge: isBn ? "গুগল ম্যাপস পিন (A - শেষ গন্তব্য)" : "Maps Pin (A - Final Destination)",
          roleText: isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your Final Destination",
          exactLandmark: destLandmark,
          mainArea: destAddress.isNotEmpty ? destAddress : (isBn ? "গন্তব্য এলাকা" : "Destination Area"),
          walkingGuide: isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your final destination (dropoff)",
          pinColor: const Color(0xFFEF4444),
          pinIcon: Icons.flag_rounded,
          coordinate: LatLng(destLat, destLng),
          matchedStops: [],
          isStart: false,
          isFinalDest: true,
        ),
      ];
    }

    // Cluster consecutive stops along ordered driving route within <= 120m
    final clusters = <List<RouteStop>>[];
    for (final s in ordered) {
      if (clusters.isEmpty) {
        clusters.add([s]);
      } else {
        final lastCluster = clusters.last;
        final primary = lastCluster.first;
        if (haversineMeters(primary.lat, primary.lng, s.lat, s.lng) <= 120.0) {
          lastCluster.add(s);
        } else {
          clusters.add([s]);
        }
      }
    }

    final result = <GoogleMapsWaypointPin>[];
    final totalClusters = clusters.length;

    for (int k = 0; k < totalClusters; k++) {
      final cluster = clusters[k];
      final primary = cluster.first;
      final landmark = resolveGoogleMapsLandmarkName(primary.lat, primary.lng, primary.address, isBn);

      final hasUserOrigin = cluster.any((s) => s.type == "ORIGIN");
      final hasUserDest = cluster.any((s) => s.type == "DESTINATION");
      final peerPickups = cluster
          .where((s) => s.type == "PICKUP" && s.passengerName != null && s.passengerName!.isNotEmpty)
          .map((s) => s.passengerName!)
          .toList();
      final peerDropoffs = cluster
          .where((s) => s.type == "DROPOFF" && s.passengerName != null && s.passengerName!.isNotEmpty)
          .map((s) => s.passengerName!)
          .toList();

      final isStart = (k == 0);
      final isFinalDest = (k == totalClusters - 1 && totalClusters > 1);

      String letter;
      String pinBadge;
      String roleText;
      String walkingGuide;
      Color pinColor;
      IconData pinIcon;
      String mainArea = "";

      for (final s in cluster) {
        final d = resolve(s, candidates: candidates, isBn: isBn);
        if (mainArea.isEmpty && d.passengerHomeArea.isNotEmpty) {
          mainArea = d.passengerHomeArea;
        }
      }
      if (mainArea.isEmpty) {
        mainArea = primary.address.isNotEmpty ? primary.address : (isBn ? "কার্বসাইড স্টপ" : "Curbside Spot");
      }

      if (isStart) {
        letter = "Start";
        pinColor = const Color(0xFF3B82F6);
        pinIcon = Icons.trip_origin_rounded;

        if (hasUserOrigin) {
          pinBadge = isBn ? "শুরুর পয়েন্ট (Start)" : "Google Maps Start";
          if (peerPickups.isNotEmpty) {
            final joined = peerPickups.join(" & ");
            roleText = isBn
                ? "আপনার পিকআপ (শুরুর পয়েন্ট) ও $joined (একসাথে উঠবে)"
                : "Your Pickup (Start Point) & $joined (Board Together)";
            walkingGuide = isBn
                ? "🚶 $joined আপনার সাথে একই গেট থেকে উঠবে (০ মিনিট ডিট্যুর)"
                : "🚶 $joined boards together with you at same gate (0 min detour)";
          } else {
            roleText = isBn ? "আপনার পিকআপ (শুরুর পয়েন্ট)" : "Your Pickup (Start Point)";
            walkingGuide = isBn ? "আপনার যাত্রার শুরুর পয়েন্ট" : "Your trip starting point";
          }
        } else {
          // A peer boards before user (e.g. Rohan at Chankharpul)
          final peerName = peerPickups.isNotEmpty ? peerPickups.join(" & ") : (primary.passengerName ?? "সহযাত্রী");
          pinBadge = isBn ? "শুরুর পয়েন্ট (Start)" : "Google Maps Start";
          roleText = isBn ? "$peerName এর পিকআপ (গাড়ির শুরুর পয়েন্ট)" : "$peerName's Pickup (Car Start Point)";
          walkingGuide = isBn
              ? "গাড়ি এখান থেকে যাত্রা শুরু করে আপনার দিকে এগিয়ে আসবে"
              : "Car starts from here and heads towards your pickup";
        }
      } else if (isFinalDest) {
        final letterIdx = totalClusters - 2;
        letter = String.fromCharCode(65 + (letterIdx >= 0 ? letterIdx : 0));
        pinColor = const Color(0xFFEF4444);
        pinIcon = Icons.flag_rounded;

        if (hasUserDest) {
          pinBadge = isBn
              ? "গুগল ম্যাপস পিন ($letter - শেষ গন্তব্য)"
              : "Maps Pin ($letter - Final Destination)";
          if (peerDropoffs.isNotEmpty) {
            final joined = peerDropoffs.join(" & ");
            roleText = isBn
                ? "আপনার শেষ গন্তব্য ও $joined (একসাথে নামবে)"
                : "Your Final Destination & $joined (Alight Together)";
            walkingGuide = isBn
                ? "আপনি ও $joined একসাথে শেষ গন্তব্যে পৌঁছাবেন"
                : "You & $joined arrive together at final destination";
          } else {
            roleText = isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your Final Destination";
            walkingGuide = isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your final destination (dropoff)";
          }
        } else {
          // A peer drops off after user (e.g. Rohan at Kuril)
          final peerName = peerDropoffs.isNotEmpty ? peerDropoffs.join(" & ") : (primary.passengerName ?? "সহযাত্রী");
          pinBadge = isBn ? "গুগল ম্যাপস পিন ($letter - শেষ গন্তব্য)" : "Maps Pin ($letter - Final Stop)";
          roleText = isBn ? "$peerName এর শেষ গন্তব্য (ড্রপঅফ)" : "$peerName's Final Destination (Dropoff)";
          walkingGuide = isBn
              ? "সকল যাত্রীর পর $peerName এখানে নেমে ট্রিপ সম্পন্ন করবে"
              : "$peerName alights here to complete the full trip";
        }
      } else {
        // Intermediate stops (Pins A, B, C...)
        letter = String.fromCharCode(65 + k - 1);

        if (hasUserOrigin) {
          // Primary user boards midway
          final joined = peerPickups.isNotEmpty ? " ও ${peerPickups.join(' & ')}" : "";
          roleText = isBn ? "আপনার পিকআপ$joined" : "Your Pickup${peerPickups.isNotEmpty ? ' & ' + peerPickups.join(' & ') : ''}";
          pinBadge = isBn ? "গুগল ম্যাপস পিন ($letter - আপনার পিকআপ)" : "Maps Pin ($letter - Your Pickup)";
          walkingGuide = isBn ? "গাড়ি আসার পর আপনি এখানে উঠবেন" : "You board the car here";
          pinColor = const Color(0xFF3B82F6);
          pinIcon = Icons.person_add_alt_1_rounded;
        } else if (hasUserDest) {
          // Primary user alights midway
          final joined = peerDropoffs.isNotEmpty ? " ও ${peerDropoffs.join(' & ')}" : "";
          roleText = isBn ? "আপনার শেষ গন্তব্য$joined (ড্রপঅফ)" : "Your Destination${peerDropoffs.isNotEmpty ? ' & ' + peerDropoffs.join(' & ') : ''} (Dropoff)";
          pinBadge = isBn ? "গুগল ম্যাপস পিন ($letter - আপনার গন্তব্য)" : "Maps Pin ($letter - Your Destination)";
          walkingGuide = isBn ? "আপনি এখানে নেমে আপনার গন্তব্যে পৌঁছাবেন" : "You alight here at your destination";
          pinColor = const Color(0xFFEF4444);
          pinIcon = Icons.location_on_rounded;
        } else {
          final hasPickup = cluster.any((s) => s.type == "PICKUP");
          pinColor = hasPickup ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
          pinIcon = hasPickup ? Icons.person_add_alt_1_rounded : Icons.person_remove_alt_1_rounded;
          pinBadge = isBn ? "গুগল ম্যাপস পিন ($letter)" : "Maps Pin ($letter)";

          final roleParts = <String>[];
          final guideParts = <String>[];

          for (final s in cluster) {
            final d = resolve(s, candidates: candidates, isBn: isBn);
            roleParts.add(getRoleText(s, isBn));
            if (d.walkingGuide.isNotEmpty) {
              guideParts.add(d.walkingGuide);
            }
          }

          roleText = roleParts.join(" • ");
          walkingGuide = guideParts.isNotEmpty ? guideParts.join("\n") : "";
        }
      }

      result.add(GoogleMapsWaypointPin(
        waypointIndex: k,
        letter: letter,
        pinBadge: pinBadge,
        roleText: roleText,
        exactLandmark: landmark,
        mainArea: mainArea,
        walkingGuide: walkingGuide,
        pinColor: pinColor,
        pinIcon: pinIcon,
        coordinate: LatLng(primary.lat, primary.lng),
        matchedStops: cluster,
        isStart: isStart,
        isFinalDest: isFinalDest,
      ));
    }

    return result;
  }

  static StopLocationDetails resolve(
    RouteStop stop, {
    List<CandidatePassenger>? candidates,
    required bool isBn,
  }) {
    CandidatePassenger? matchedCandidate;
    final pname = (stop.passengerName ?? "").toLowerCase();

    if (candidates != null && stop.passengerName != null) {
      for (final c in candidates) {
        if (stop.passengerName != null &&
            c.passengerName.toLowerCase().contains(stop.passengerName!.toLowerCase().split(" ").first)) {
          matchedCandidate = c;
          break;
        }
      }
    }

    final landmark = resolveGoogleMapsLandmarkName(stop.lat, stop.lng, stop.address, isBn);

    // 1. ORIGIN
    if (stop.type == "ORIGIN") {
      final mainArea = stop.address.isNotEmpty ? stop.address : (isBn ? "পিকআপ পয়েন্ট" : "Pickup Point");
      final guide = isBn ? "আপনার যাত্রার শুরুর পয়েন্ট" : "Your trip starting point";
      return StopLocationDetails(
        exactLandmark: landmark,
        passengerHomeArea: mainArea,
        walkingGuide: guide,
      );
    }

    // 2. DESTINATION
    if (stop.type == "DESTINATION") {
      final mainArea = stop.address.isNotEmpty ? stop.address : (isBn ? "গন্তব্য পয়েন্ট" : "Destination Point");
      final guide = isBn ? "আপনার শেষ গন্তব্য (ড্রপঅফ)" : "Your final destination (dropoff)";
      return StopLocationDetails(
        exactLandmark: landmark,
        passengerHomeArea: mainArea,
        walkingGuide: guide,
      );
    }

    // 3. PICKUP
    if (stop.type == "PICKUP") {
      if (pname.contains("nusrat")) {
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "ঢাকা বিশ্ববিদ্যালয় ক্যাম্পাস" : "University of Dhaka Campus",
          walkingGuide: isBn
              ? "🚶 একই স্পট থেকে আপনার সাথে একসাথে উঠবে — ০ মিনিট ডিট্যুর"
              : "🚶 Boards together with you at same gate (0 min detour)",
          walkingDistanceMeters: 20.0,
          walkingMinutes: 0,
          hasWalkConnection: false,
        );
      }

      if (pname.contains("tanvir")) {
        final peerLoc = matchedCandidate != null
            ? LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng)
            : const LatLng(23.7371, 90.3958);
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "শাহবাগ করিডোর" : "Shahbagh Corridor Curbside",
          walkingGuide: isBn
              ? "🚶 মোড়ের আগে জাতীয় জাদুঘর গেটে সরাসরি উঠবে (~১ মিনিট) — কোনো অপ্রয়োজনীয় ইউ-টার্ন নেই"
              : "🚶 Boards directly before intersection at National Museum Gate (~1 min) — 0 useless U-turns",
          walkingDistanceMeters: 40.0,
          walkingMinutes: 1,
          hasWalkConnection: true,
          peerLocation: peerLoc,
        );
      }

      if (pname.contains("mehjabin")) {
        final peerLoc = matchedCandidate != null
            ? LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng)
            : const LatLng(23.7580, 90.3880);
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "ফার্মগেট / ইন্দিরা রোড এরিয়া" : "Farmgate / Indira Road Curbside",
          walkingGuide: isBn
              ? "🚶 ইন্দিরা রোড কার্বসাইড স্পটে এসে উঠবে (~৩ মিনিট)"
              : "🚶 Walks ~205m to curbside stop (~3 mins)",
          walkingDistanceMeters: 205.0,
          walkingMinutes: 3,
          hasWalkConnection: true,
          peerLocation: peerLoc,
        );
      }

      if (pname.contains("sadia")) {
        final peerLoc = matchedCandidate != null
            ? LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng)
            : const LatLng(23.7410, 90.3860);
        final dist = haversineMeters(stop.lat, stop.lng, peerLoc.latitude, peerLoc.longitude);
        final walkMins = math.max(1, (dist / 75.0).round());
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "হাতিরপুল রেসিডেন্সিয়াল এরিয়া" : "Hatirpool Residential Area",
          walkingGuide: isBn
              ? "🚶 হাতিরপুল গলি থেকে ${dist.round()} মি. হেঁটে সোনারগাঁও রোড কার্বসাইডে এসে উঠবে (~$walkMins মিনিট) — গাড়ি মেইন রোডে থাকবে (গলিতে ০ প্রবেশ)"
              : "🚶 Walks ~${dist.round()}m from Hatirpool alley to Sonargaon Road curbside (~$walkMins mins) — Car stays on main road (0 goli entry)",
          walkingDistanceMeters: dist,
          walkingMinutes: walkMins,
          hasWalkConnection: true,
          peerLocation: peerLoc,
        );
      }

      if (pname.contains("nabil")) {
        final peerLoc = matchedCandidate != null
            ? LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng)
            : const LatLng(23.7565, 90.3725);
        final dist = haversineMeters(stop.lat, stop.lng, peerLoc.latitude, peerLoc.longitude);
        final walkMins = math.max(1, (dist / 75.0).round());
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "লালমাটিয়া ব্লক ডি রেসিডেন্সিয়াল এরিয়া" : "Lalmatia Block D Residential, Mohammadpur",
          walkingGuide: isBn
              ? "🚶 লালমাটিয়া থেকে ${dist.round()} মি. হেঁটে মিরপুর রোড আড়ং কার্বসাইডে এসে উঠবে (~$walkMins মিনিট) — গাড়ি মেইন রোডে থাকবে (গলিতে ০ প্রবেশ)"
              : "🚶 Walks ~${dist.round()}m from Lalmatia to Mirpur Road Aarong curbside (~$walkMins mins) — Car stays on main road (0 goli entry)",
          walkingDistanceMeters: dist,
          walkingMinutes: walkMins,
          hasWalkConnection: true,
          peerLocation: peerLoc,
        );
      }

      if (pname.contains("anika")) {
        final peerLoc = matchedCandidate != null
            ? LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng)
            : const LatLng(23.7540, 90.4080);
        final dist = haversineMeters(stop.lat, stop.lng, peerLoc.latitude, peerLoc.longitude);
        final walkMins = math.max(1, (dist / 75.0).round());
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "মগবাজার নয়াটোলা রেসিডেন্সিয়াল এরিয়া" : "Moghbazar Nayatola Residential Area",
          walkingGuide: isBn
              ? "🚶 নয়াটোলা গলি থেকে ${dist.round()} মি. হেঁটে তাজউদ্দীন আহমদ সরণি কার্বসাইডে এসে উঠবে (~$walkMins মিনিট) — গাড়ি মেইন রোডে থাকবে (গলিতে ০ প্রবেশ)"
              : "🚶 Walks ~${dist.round()}m from Nayatola alley to Tajuddin Ahmad Sarani curbside (~$walkMins mins) — Car stays on main road (0 goli entry)",
          walkingDistanceMeters: dist,
          walkingMinutes: walkMins,
          hasWalkConnection: true,
          peerLocation: peerLoc,
        );
      }

      // Generic pickup candidate
      final homeArea = matchedCandidate?.pickupAddress ?? stop.address;
      double dist = 0.0;
      LatLng? peerLoc;
      if (matchedCandidate != null) {
        dist = haversineMeters(matchedCandidate.pickupLat, matchedCandidate.pickupLng, stop.lat, stop.lng);
        peerLoc = LatLng(matchedCandidate.pickupLat, matchedCandidate.pickupLng);
      }
      final hasWalk = dist > 40.0;
      final walkMins = math.max(1, (dist / 75.0).round());

      return StopLocationDetails(
        exactLandmark: landmark,
        passengerHomeArea: homeArea,
        walkingGuide: hasWalk
            ? (isBn
                ? "🚶 মূল এলাকা থেকে ${dist.round()} মি. হেঁটে রোডের স্পটে এসে উঠবে (~$walkMins মিনিট)"
                : "🚶 Walks ~${dist.round()}m to curbside stop (~$walkMins mins)")
            : (isBn ? "কার্বসাইড পিকআপ স্টপ (গলিতে ০ প্রবেশ)" : "Curbside pickup stop (0 goli entry)"),
        walkingDistanceMeters: dist,
        walkingMinutes: walkMins,
        hasWalkConnection: hasWalk,
        peerLocation: peerLoc,
      );
    }

    // 4. DROPOFF
    if (stop.type == "DROPOFF") {
      if (pname.contains("nusrat")) {
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "মহাখালী বাস টার্মিনাল / ট্রানজিট হাব" : "Mohakhali Transit Hub",
          walkingGuide: isBn ? "ট্রানজিট হাব মোড়ে ড্রপঅফ" : "Dropoff at transit hub on route",
        );
      }

      if (pname.contains("tanvir") || pname.contains("mehjabin") || pname.contains("rafid")) {
        return StopLocationDetails(
          exactLandmark: landmark,
          passengerHomeArea: isBn ? "বনানী ১১ হাব" : "Banani 11 Hub",
          walkingGuide: isBn ? "আপনার সাথে শেষ গন্তব্যে একসাথে নামবে" : "Alights together with you at final destination",
        );
      }

      if (pname.contains("sadia")) {
        return StopLocationDetails(
          exactLandmark: isBn ? "৮৩ রোড ২৬, ঢাকা ১২১৩ (83 Rd 26)" : "83 Rd 26, Dhaka 1213",
          passengerHomeArea: isBn ? "বনানী স্টার কাবাব" : "Banani Star Kabab",
          walkingGuide: isBn ? "মেইন রোডে কার্বসাইডে ড্রপঅফ" : "Curbside dropoff on route",
        );
      }

      final homeArea = matchedCandidate?.dropoffAddress ?? stop.address;
      return StopLocationDetails(
        exactLandmark: landmark,
        passengerHomeArea: homeArea,
        walkingGuide: isBn ? "মেইন রোড কার্বসাইডে ড্রপঅফ" : "Curbside dropoff on route",
      );
    }

    return StopLocationDetails(
      exactLandmark: landmark,
      passengerHomeArea: stop.address,
      walkingGuide: "",
    );
  }
}
