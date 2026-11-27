import 'chat_message.dart';

class Participant {
  final int userId;
  final String fullName;
  final String? university;
  final String? studentId;
  final String role; // "PROVIDER" | "SEEKER"
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool active;

  Participant({
    required this.userId,
    required this.fullName,
    this.university,
    this.studentId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    required this.active,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] is int
          ? json['userId']
          : int.parse(json['userId'].toString()),
      fullName: json['fullName'] as String? ?? 'Student',
      university: json['university'] as String?,
      studentId: json['studentId'] as String?,
      role: json['role'] as String? ?? 'SEEKER',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'].toString())
          : DateTime.now(),
      leftAt: json['leftAt'] != null
          ? DateTime.parse(json['leftAt'].toString())
          : null,
      active: json['active'] as bool? ?? true,
    );
  }
}

class RideContext {
  final int rideId;
  final String originAddress;
  final String destinationAddress;
  final int totalSeats;
  final int availableSeats;
  final int occupiedSeats;
  final String rideStatus;
  final String vehicleType; // "BIKE" | "CNG" | "CAR"
  final double estimatedTotalFare;

  RideContext({
    required this.rideId,
    required this.originAddress,
    required this.destinationAddress,
    required this.totalSeats,
    required this.availableSeats,
    required this.occupiedSeats,
    required this.rideStatus,
    required this.vehicleType,
    required this.estimatedTotalFare,
  });

  factory RideContext.fromJson(Map<String, dynamic> json) {
    return RideContext(
      rideId: json['rideId'] is int
          ? json['rideId']
          : int.parse(json['rideId'].toString()),
      originAddress: json['originAddress'] as String? ?? '',
      destinationAddress: json['destinationAddress'] as String? ?? '',
      totalSeats: json['totalSeats'] as int? ?? 4,
      availableSeats: json['availableSeats'] as int? ?? 0,
      occupiedSeats: json['occupiedSeats'] as int? ?? 1,
      rideStatus: json['rideStatus'] as String? ?? 'REQUESTED',
      vehicleType: json['vehicleType'] as String? ?? 'CAR',
      estimatedTotalFare: json['estimatedTotalFare'] != null
          ? (json['estimatedTotalFare'] as num).toDouble()
          : 0.0,
    );
  }
}

class ConversationSummary {
  final int id;
  final int rideId;
  final String type; // "DIRECT" | "GROUP"
  final String status; // "ACTIVE" | "ARCHIVED"
  final DateTime lastMessageAt;
  final int unreadCount;
  final ChatMessage? lastMessage;
  final RideContext? rideContext;
  final List<Participant> participants;

  ConversationSummary({
    required this.id,
    required this.rideId,
    required this.type,
    required this.status,
    required this.lastMessageAt,
    required this.unreadCount,
    this.lastMessage,
    this.rideContext,
    required this.participants,
  });

  bool get isGroup =>
      type == 'GROUP' || participants.where((p) => p.active).length >= 3;

  String getTitle(int currentUserId) {
    if (isGroup) {
      if (rideContext != null && rideContext!.originAddress.isNotEmpty) {
        final originShort = rideContext!.originAddress.split(',').first.trim();
        final destShort =
            rideContext!.destinationAddress.split(',').first.trim();
        return '$originShort → $destShort (${rideContext!.vehicleType})';
      }
      return 'Campus Ride Group #$rideId';
    } else {
      final other = participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => participants.isNotEmpty
            ? participants.first
            : Participant(
                userId: 0,
                fullName: 'Campus Peer',
                role: 'SEEKER',
                joinedAt: DateTime.now(),
                active: true,
              ),
      );
      return other.fullName;
    }
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()),
      rideId: json['rideId'] is int
          ? json['rideId']
          : int.parse(json['rideId'].toString()),
      type: json['type'] as String? ?? 'DIRECT',
      status: json['status'] as String? ?? 'ACTIVE',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'].toString())
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      rideContext: json['rideContext'] != null
          ? RideContext.fromJson(json['rideContext'])
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => Participant.fromJson(p))
              .toList()
          : [],
    );
  }
}
