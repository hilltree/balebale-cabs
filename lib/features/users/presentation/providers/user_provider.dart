import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:balebale_cabs/features/users/domain/entities/user.dart';

final currentUserProvider = StateProvider<User?>((ref) => null);

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) => UserNotifier());

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null) {
    // Initialize user state from Supabase session
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await loadUserData(session.user.id);
    }
  }

  Future<void> loadUserData(String userId) async {
    try {
      final userData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
        state = User.fromJson(userData);
    } catch (e) {
      print('Error loading user data: $e');
      try {
        // Create profile if it doesn't exist
        final newUser = User(
          id: userId,
          name: 'New User',
          email: Supabase.instance.client.auth.currentUser?.email ?? '',
        );
        await Supabase.instance.client
            .from('profiles')
            .insert(newUser.toJson());
        state = newUser;
      } catch (e) {
        print('Error creating user profile: $e');
      }
    }
  }

  Future<void> loginUser(AuthResponse response) async {
    if (response.user != null) {
      await loadUserData(response.user!.id);
    }
  }

  void logout() {
    state = null;
  }  Future<void> updateUser(User user) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(user.toJson())
          .eq('id', user.id);
      state = user;
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}
