import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:balebale_cabs/features/rides/presentation/providers/rides_provider.dart';
import 'package:balebale_cabs/features/rides/presentation/widgets/ride_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:balebale_cabs/features/users/presentation/providers/user_provider.dart';
import 'package:balebale_cabs/features/users/presentation/providers/role_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  bool _showMap = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load nearby rides when the screen initializes
    Future.microtask(() => ref.read(nearbyRidesProvider.notifier).loadRides());
  }

  Future<void> _handleLogin() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in as ${response.user!.email}')),
        );
        context.go('/'); // Navigate to the home page after login
      }
    } catch (error) {
      setState(() => _errorMessage = 'Login failed: $error');
    }
  }
  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(nearbyRidesProvider);
    final currentUser = ref.watch(userProvider);
    final currentRole = ref.watch(roleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balebale Cabs'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          if (currentUser != null) ...[
            // Role switcher
            SegmentedButton<RoleContext>(
              segments: const [
                ButtonSegment(
                  value: RoleContext.passenger,
                  icon: Icon(Icons.person),
                  label: Text('Passenger'),
                ),
                ButtonSegment(
                  value: RoleContext.driver,
                  icon: Icon(Icons.drive_eta),
                  label: Text('Driver'),
                ),
              ],
              selected: {currentRole},
              onSelectionChanged: (Set<RoleContext> selected) {
                ref.read(roleProvider.notifier).setRole(selected.first);
              },
            ),
            if (currentRole == RoleContext.driver)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/create-ride'),
              ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ],
      ),
      body: currentUser == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Create an Account'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_showMap)
                  Expanded(
                    flex: 2,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(40.7128, -74.0060), // New York
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.balebale.cabs',
                        ),
                        MarkerLayer(
                          markers: rides.when(
                            data: (rides) => rides.map((ride) => Marker(
                              point: LatLng(
                                ride.sourceCoords.latitude,
                                ride.sourceCoords.longitude,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            )).toList(),
                            loading: () => const [],
                            error: (_, __) => const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  flex: _showMap ? 1 : 3,
                  child: rides.when(
                    data: (rides) => rides.isEmpty
                        ? const Center(
                            child: Text('No rides available'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: rides.length,
                            itemBuilder: (context, index) {
                              final ride = rides[index];
                              return RideCard(
                                ride: ride,
                                onTap: () => context.push('/ride/${ride.id}'),
                              );
                            },
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error: $error'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}