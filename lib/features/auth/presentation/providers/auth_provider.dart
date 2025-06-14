import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balebale_cabs/features/users/domain/entities/user.dart' as UserEntity;
import 'package:balebale_cabs/features/users/presentation/providers/user_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final authProvider = Provider<AuthProvider>((ref) {
  return AuthProvider(ref);
});

class AuthProvider {
  final Ref _ref;

  AuthProvider(this._ref) {
    // Listen to auth state changes
    _ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) async {
        if (authState.event == AuthChangeEvent.signedIn && authState.session != null) {
          await _ref.read(userProvider.notifier).loadUserData(authState.session!.user.id);
        } else if (authState.event == AuthChangeEvent.signedOut) {
          // User signed out, clear their profile
          _ref.read(userProvider.notifier).logout();
        }
      });
    });

    // Initialize with current session if exists
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _loadUserProfile(session.user.id);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final userData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final user = UserEntity.User.fromJson(userData);
      _ref.read(userProvider.notifier).updateUser(user);
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
