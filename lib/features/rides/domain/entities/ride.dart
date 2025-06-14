import 'package:balebale_cabs/features/users/domain/entities/user.dart';
import 'package:latlong2/latlong.dart';

class Ride {
  final String id;
  final String source;
  final String destination;
  final LatLng sourceCoords;
  final LatLng destinationCoords;
  final DateTime departureTime;
  final double fare;
  final int availableSeats;
  final String driverId;
  final Map<String, dynamic> driverProfile;
  final String? status;
  final String? notes;

  const Ride({
    required this.id,
    required this.source,
    required this.destination,
    required this.sourceCoords,
    required this.destinationCoords,
    required this.departureTime,
    required this.fare,
    required this.availableSeats,
    required this.driverId,
    required this.driverProfile,
    this.status = 'active',
    this.notes,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      source: json['source'] as String,
      destination: json['destination'] as String,
      sourceCoords: LatLng(
        json['source_lat'] as double,
        json['source_lng'] as double,
      ),
      destinationCoords: LatLng(
        json['destination_lat'] as double,
        json['destination_lng'] as double,
      ),
      departureTime: DateTime.parse(json['departure_time'] as String),
      fare: (json['fare'] as num).toDouble(),
      availableSeats: json['available_seats'] as int,
      driverId: json['driver_id'] as String,
      driverProfile: json['profiles'] as Map<String, dynamic>,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'destination': destination,
      'source_lat': sourceCoords.latitude,
      'source_lng': sourceCoords.longitude,
      'destination_lat': destinationCoords.latitude,
      'destination_lng': destinationCoords.longitude,
      'departure_time': departureTime.toIso8601String(),
      'fare': fare,
      'available_seats': availableSeats,
      'driver_id': driverId,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'source': source,
      'destination': destination,
      'source_lat': sourceCoords.latitude,
      'source_lng': sourceCoords.longitude,
      'destination_lat': destinationCoords.latitude,
      'destination_lng': destinationCoords.longitude,
      'departure_time': departureTime.toIso8601String(),
      'fare': fare,
      'available_seats': availableSeats,
      'driver_id': driverId,
      'notes': notes,
    };
  }

  // Add getters
  DateTime get departureDate => departureTime;
  int get seatsAvailable => availableSeats;
  double get pricePerSeat => fare;
  String get driverName => driverProfile['name'] as String;
  String? get driverPhone => driverProfile['phone'] as String?;
  User get driver => User(
        id: driverId,
        name: driverProfile['name'] as String,
        email: driverProfile['email'] as String,
        phone: driverProfile['phone'] as String?,
        avatarUrl: driverProfile['avatar_url'] as String?,
        rating: (driverProfile['rating'] as num?)?.toDouble() ?? 5.0,
      );
  static Ride empty() {
    return Ride(
      id: '',
      source: '',
      destination: '',
      sourceCoords: LatLng(0.0, 0.0),
      destinationCoords: LatLng(0.0, 0.0),
      departureTime: DateTime.now(),
      fare: 0.0,
      availableSeats: 0,
      driverId: '',
      driverProfile: {},
      status: 'active',
      notes: null,
    );
  }

  bool get isEmpty => id.isEmpty;
}