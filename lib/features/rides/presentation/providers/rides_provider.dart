import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balebale_cabs/features/rides/domain/entities/ride.dart';

final nearbyRidesProvider = AsyncNotifierProvider<RidesNotifier, List<Ride>>(RidesNotifier.new);

class RidesNotifier extends AsyncNotifier<List<Ride>> {
  @override
  Future<List<Ride>> build() async {
    return [];
  }

  Future<void> loadRides() async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('rides')
          .select('''
            *,
            profiles!inner (
              id,
              name,
              email,
              phone,
              avatar_url,
              rating
            )
          ''')
          .gte('departure_time', DateTime.now().toIso8601String())
          .order('departure_time');

      final rides = response.map((json) => Ride.fromJson(json)).toList();
      state = AsyncValue.data(rides);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRide(Ride ride) async {
    try {
      final response = await Supabase.instance.client
          .from('rides')
          .insert(ride.toJsonForCreate())
          .select('''
            *,
            profiles!inner (
              id,
              name,
              email,
              phone,
              avatar_url,
              rating
            )
          ''')
          .single();

      final newRide = Ride.fromJson(response);
      state.whenData((rides) {
        state = AsyncValue.data([newRide, ...rides]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> bookRide(String rideId, int seats) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'confirm-booking',
        body: {
          'ride_id': rideId,
          'seats': seats,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to book ride');
      }

      // Refresh the rides list
      await loadRides();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}