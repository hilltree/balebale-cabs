import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balebale_cabs/features/bookings/domain/entities/booking.dart';
import 'package:balebale_cabs/features/rides/domain/entities/ride.dart';

final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<Booking>>((ref) {
  return BookingsNotifier();
});

class BookingsNotifier extends StateNotifier<List<Booking>> {
  BookingsNotifier() : super([]);

  Future<void> loadUserBookings() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('bookings')
          .select()
          .or('rider_id.eq.$userId,driver_id.eq.$userId')
          .order('timestamp', ascending: false);

      state = data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('Error loading bookings: $e');
    }
  }

  Future<void> createBooking(Ride ride, int seats) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final booking = Booking(
        id: '',  // Will be set by the database
        rideId: ride.id,
        riderId: userId,
        driverId: ride.driverId,
        seatsBooked: seats,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      final data = await Supabase.instance.client
          .from('bookings')
          .insert(booking.toJson())
          .select()
          .single();

      state = [...state, Booking.fromJson(data)];
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId)
          .or('rider_id.eq.$userId,driver_id.eq.$userId');

      state = state.map((booking) {
        if (booking.id == bookingId) {
          return booking.copyWith(status: newStatus);
        }
        return booking;
      }).toList();
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }
}
