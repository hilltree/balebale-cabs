# Cab Pooling App Backend

This is the backend implementation for a cab pooling application similar to BlaBlaCar, built using Supabase and PostgreSQL.

## Features

- User authentication and profile management
- Ride creation and management
- Booking system with real-time updates
- In-app chat system
- Rating and review system
- Dynamic fare calculation
- Location-based ride matching

## Prerequisites

- Supabase account
- PostgreSQL with PostGIS extension
- Node.js and npm (for local development)

## Setup

1. Create a new Supabase project
2. Enable the PostGIS extension in your Supabase database
3. Run the schema.sql file to create the database structure
4. Run the functions.sql file to create the necessary database functions
5. Run the test_data.sql file to populate the database with sample data
6. Deploy the Edge Functions to your Supabase project

## Database Schema

### Tables

- users: User profiles and authentication
- rides: Available rides with source, destination, and pricing
- bookings: Ride bookings with status tracking
- chat_messages: In-app messaging system
- ratings: User ratings and reviews

### Row Level Security (RLS)

The database implements RLS policies to ensure data security:
- Users can only view and modify their own profiles
- Drivers can manage their own rides
- Users can only view and modify their own bookings
- Chat messages are only visible to ride participants

## Edge Functions

### match-rides

Finds nearby rides based on user location and preferences.

```typescript
// Request
{
  lat: number,
  lng: number,
  maxDistance?: number, // in kilometers, defaults to 10
  date: string // ISO date string
}

// Response
{
  rides: Array<{
    id: string,
    driver_id: string,
    source: string,
    destination: string,
    date: string,
    seats_available: number,
    price_per_seat: number,
    distance_meters: number
  }>
}
```

### confirm-booking

Confirms a booking and updates seat availability.

```typescript
// Request
{
  booking_id: string
}

// Response
{
  message: string
}
```

### calculate-fare

Calculates the fare based on distance and other factors.

```typescript
// Request
{
  source: {
    lat: number,
    lng: number
  },
  destination: {
    lat: number,
    lng: number
  },
  seats?: number // defaults to 1
}

// Response
{
  base_fare: number,
  distance_km: number,
  per_km_rate: number,
  seats: number,
  surge_multiplier: number,
  total_fare: number
}
```

## Flutter Integration

To integrate with Flutter, use the Supabase Flutter SDK:

```dart
final supabase = SupabaseClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_ANON_KEY'
);

// Example: Find nearby rides
final response = await supabase.functions.invoke('match-rides', body: {
  'lat': 40.7128,
  'lng': -74.0060,
  'date': DateTime.now().toIso8601String()
});

// Example: Subscribe to real-time updates
final subscription = supabase
  .from('bookings')
  .on(SupabaseEventTypes.all, (payload, [ref]) {
    // Handle real-time updates
  })
  .subscribe();
```

## Security

- All database operations are protected by Row Level Security (RLS)
- Edge Functions require authentication
- Real-time subscriptions are filtered based on user permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License 