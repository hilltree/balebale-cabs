-- Function to find nearby rides
CREATE OR REPLACE FUNCTION find_nearby_rides(
  user_lat double precision,
  user_lng double precision,
  max_distance double precision,
  ride_date timestamp with time zone
)
RETURNS TABLE (
  id uuid,
  driver_id uuid,
  source text,
  destination text,
  date timestamp with time zone,
  seats_available integer,
  price_per_seat float,
  distance_meters double precision
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.driver_id,
    r.source,
    r.destination,
    r.date,
    r.seats_available,
    r.price_per_seat,
    ST_Distance(
      r.source_coords::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance_meters
  FROM rides r
  WHERE 
    r.date >= ride_date
    AND r.seats_available > 0
    AND ST_DWithin(
      r.source_coords::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      max_distance
    )
  ORDER BY 
    r.date ASC,
    distance_meters ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to confirm booking and update seats
CREATE OR REPLACE FUNCTION confirm_booking(
  p_booking_id uuid,
  p_seats_booked integer
)
RETURNS void AS $$
DECLARE
  v_ride_id uuid;
BEGIN
  -- Get the ride_id for the booking
  SELECT ride_id INTO v_ride_id
  FROM bookings
  WHERE id = p_booking_id;

  -- Update booking status
  UPDATE bookings
  SET status = 'confirmed'
  WHERE id = p_booking_id;

  -- Update available seats
  UPDATE rides
  SET seats_available = seats_available - p_seats_booked
  WHERE id = v_ride_id;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate distance between two points
CREATE OR REPLACE FUNCTION calculate_distance(
  source_lat double precision,
  source_lng double precision,
  dest_lat double precision,
  dest_lng double precision
)
RETURNS double precision AS $$
BEGIN
  RETURN ST_Distance(
    ST_SetSRID(ST_MakePoint(source_lng, source_lat), 4326)::geography,
    ST_SetSRID(ST_MakePoint(dest_lng, dest_lat), 4326)::geography
  );
END;
$$ LANGUAGE plpgsql; 