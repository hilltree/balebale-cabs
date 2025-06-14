class Booking {
  final String id;
  final String rideId;
  final String riderId;
  final String driverId;
  final int seatsBooked;
  final String status;
  final DateTime timestamp;

  const Booking({
    required this.id,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.seatsBooked,
    required this.status,
    required this.timestamp,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      riderId: json['rider_id'] as String,
      driverId: json['driver_id'] as String,
      seatsBooked: json['seats_booked'] as int,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'rider_id': riderId,
      'driver_id': driverId,
      'seats_booked': seatsBooked,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? rideId,
    String? riderId,
    String? driverId,
    int? seatsBooked,
    String? status,
    DateTime? timestamp,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static Booking empty() {
    return Booking(
      id: '',
      rideId: '',
      riderId: '',
      driverId: '',
      seatsBooked: 0,
      status: 'pending',
      timestamp: DateTime.now(),
    );
  }
}
