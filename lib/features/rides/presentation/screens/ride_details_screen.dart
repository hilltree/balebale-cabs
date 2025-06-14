import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:balebale_cabs/features/rides/domain/entities/ride.dart';
import 'package:balebale_cabs/features/rides/presentation/providers/rides_provider.dart';

class RideDetailsScreen extends ConsumerStatefulWidget {
  final String rideId;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
  });

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  final MapController _mapController = MapController();
  int _selectedSeats = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rides = ref.watch(nearbyRidesProvider);
    final ride = rides.when(
      data: (rides) => rides.firstWhere((r) => r.id == widget.rideId, orElse: () => Ride.empty()),
      loading: () => Ride.empty(),
      error: (error, stack) => Ride.empty(),
    );

    if (ride.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => context.push('/chat/${widget.rideId}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    ride.sourceCoords.latitude,
                    ride.sourceCoords.longitude,
                  ),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.balebale.cabs',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          ride.sourceCoords.latitude,
                          ride.sourceCoords.longitude,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      Marker(
                        point: LatLng(
                          ride.destinationCoords.latitude,
                          ride.destinationCoords.longitude,
                        ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(ride.driver.avatarUrl ?? ''),
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driver.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ride.driver.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildRouteInfo(theme, ride),
                  const SizedBox(height: 24),
                  _buildRideDetails(theme, ride),
                  if (ride.notes != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(ride.notes!),
                  ],
                  const SizedBox(height: 24),
                  if (ride.availableSeats > 0) ...[
                    Text(
                      'Book Seats',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _selectedSeats > 1
                              ? () => setState(() => _selectedSeats--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_selectedSeats',
                          style: theme.textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: _selectedSeats < ride.availableSeats
                              ? () => setState(() => _selectedSeats++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          '\$${(ride.pricePerSeat * _selectedSeats).toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(nearbyRidesProvider.notifier).bookRide(
                              ride.id,
                              _selectedSeats,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking request sent!'),
                          ),
                        );
                      },
                      child: const Text('Book Now'),
                    ),
                  ] else
                    const Card(
                      color: Colors.red,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No seats available',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(ThemeData theme, Ride ride) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        ride.source,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        ride.destination,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideDetails(ThemeData theme, Ride ride) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride Details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  theme,
                  Icons.calendar_today,
                  'Date',
                  ride.departureTime.toString().split(' ')[0],
                ),
                _buildDetailItem(
                  theme,
                  Icons.access_time,
                  'Time',
                  ride.departureTime.toString().split(' ')[1].substring(0, 5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  theme,
                  Icons.event_seat,
                  'Available Seats',
                  ride.availableSeats.toString(),
                ),
                _buildDetailItem(
                  theme,
                  Icons.attach_money,
                  'Price per Seat',
                  '\$${ride.pricePerSeat.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}