import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:balebale_cabs/features/auth/presentation/screens/login_screen.dart';
import 'package:balebale_cabs/features/auth/presentation/screens/register_screen.dart';
import 'package:balebale_cabs/features/home/presentation/screens/home_screen.dart';
import 'package:balebale_cabs/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:balebale_cabs/features/rides/presentation/screens/create_ride_screen.dart';
import 'package:balebale_cabs/features/chat/presentation/screens/chat_screen.dart';
import 'package:balebale_cabs/features/users/presentation/screens/profile_screen.dart';
import 'package:balebale_cabs/features/rides/domain/entities/ride.dart' as RideEntity;
import 'package:balebale_cabs/features/users/domain/entities/user.dart' as UserEntity;
import 'package:balebale_cabs/features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Check if not logged in and not on auth pages
      final authenticated = authState.value?.session != null;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!authenticated && !onAuthPage) {
        return '/login';
      } else if (authenticated && onAuthPage) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/ride/:id',
        builder: (context, state) => RideDetailsScreen(
          rideId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/create-ride',
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: '/chat/:rideId',
        builder: (context, state) => ChatScreen(
          ride: state.extra as RideEntity.Ride,
          otherUser: state.extra as UserEntity.User,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});