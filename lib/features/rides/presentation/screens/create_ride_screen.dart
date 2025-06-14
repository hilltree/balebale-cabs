import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:balebale_cabs/features/rides/domain/entities/ride.dart';
import 'package:balebale_cabs/features/rides/presentation/providers/rides_provider.dart';
import 'package:balebale_cabs/features/users/presentation/providers/user_provider.dart';
import 'package:balebale_cabs/features/users/presentation/providers/role_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});
}

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

// Add a mixin to handle role checking
mixin RoleAwareState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  @override
  void initState() {
    super.initState();
    // Set role to driver when creating a ride
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roleProvider.notifier).setRole(RoleContext.driver);
    });
  }
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> with RoleAwareState {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _mapController = MapController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LatLng? _sourceCoords;
  LatLng? _destCoords;
  bool _isLoading = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceCoords == null || _destCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select source and destination on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
      setState(() => _isLoading = true);
    
    try {

      final currentUser = ref.read(userProvider);
      if (currentUser == null) {
        // Try to reload user data from session
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          await ref.read(userProvider.notifier).loadUserData(session.user.id);
          final reloadedUser = ref.read(userProvider);
          if (reloadedUser == null) {
            throw Exception('Failed to load user profile');
          }
        } else {
          throw Exception('User not logged in');
        }
      }      final ride = Ride(
        id: '', // Will be set by the database
        source: _sourceController.text,
        destination: _destinationController.text,
        sourceCoords: _sourceCoords!,
        destinationCoords: _destCoords!,
        departureTime: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        availableSeats: int.parse(_seatsController.text),
        fare: double.parse(_priceController.text),
        driverId: currentUser!.id,  // We know it's not null at this point
        driverProfile: {
          'id': currentUser.id,
          'name': currentUser.name,
          'email': currentUser.email,
          'phone': currentUser.phone,
          'avatar_url': currentUser.avatarUrl,
          'rating': currentUser.rating
        },
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: null // This will be excluded from toJson
      );

      await ref.read(nearbyRidesProvider.notifier).createRide(ride);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ride: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,                options: MapOptions(
                  initialCenter: const LatLng(40.7128, -74.0060), // New York
                  initialZoom: 13,
                  onTap: (tapPosition, point) {
                    setState(() {
                      if (_sourceCoords == null) {
                        _sourceCoords = point;
                      } else {
                        _destCoords ??= point;
                      }
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.balebale.cabs',
                  ),
                  MarkerLayer(
                    markers: [                      if (_sourceCoords != null)
                        Marker(
                          point: _sourceCoords!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      if (_destCoords != null)
                        Marker(
                          point: _destCoords!,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter source location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on, color: Colors.green),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter destination location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _seatsController,
                    decoration: const InputDecoration(
                      labelText: 'Available Seats',
                      prefixIcon: Icon(Icons.event_seat),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of seats';
                      }
                      final seats = int.tryParse(value);
                      if (seats == null || seats <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Seat',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createRide,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create Ride'),
            ),
          ],
        ),
      ),
    );
  }
}