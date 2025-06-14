-- Create test auth users (this would typically be handled by Supabase Auth UI)
DO $$
DECLARE
    enc_pass TEXT;
BEGIN
    -- Create encrypted password for test users
    enc_pass := crypt('password123', gen_salt('bf'));

    -- Insert test users
    INSERT INTO auth.users (
        id, 
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_user_meta_data,
        created_at,
        updated_at,
        last_sign_in_at
    ) VALUES
        (
            '11111111-1111-1111-1111-111111111111',
            '00000000-0000-0000-0000-000000000000',
            'john@example.com',
            enc_pass,
            NOW(),
            '{"name":"John Doe","phone":"+1234567890"}',
            NOW(),
            NOW(),
            NOW()
        ),
        (
            '22222222-2222-2222-2222-222222222222',
            '00000000-0000-0000-0000-000000000000',
            'jane@example.com',
            enc_pass,
            NOW(),
            '{"name":"Jane Smith","phone":"+1234567891"}',
            NOW(),
            NOW(),
            NOW()
        ),
        (
            '33333333-3333-3333-3333-333333333333',
            '00000000-0000-0000-0000-000000000000',
            'bob@example.com',
            enc_pass,
            NOW(),
            '{"name":"Bob Johnson","phone":"+1234567892"}',
            NOW(),
            NOW(),
            NOW()
        ),
        (
            '44444444-4444-4444-4444-444444444444',
            '00000000-0000-0000-0000-000000000000',
            'alice@example.com',
            enc_pass,
            NOW(),
            '{"name":"Alice Brown","phone":"+1234567893"}',
            NOW(),
            NOW(),
            NOW()
        ),
        (
            '55555555-5555-5555-5555-555555555555',
            '00000000-0000-0000-0000-000000000000',
            'charlie@example.com',
            enc_pass,
            NOW(),
            '{"name":"Charlie Wilson","phone":"+1234567894"}',
            NOW(),
            NOW(),
            NOW()
        )
    ON CONFLICT (id) DO NOTHING;
END $$;

-- Explicitly create profiles (in case trigger fails)
INSERT INTO profiles (id, name, email, phone, avatar_url, rating) VALUES
    (
        '11111111-1111-1111-1111-111111111111',
        'John Doe',
        'john@example.com',
        '+1234567890',
        'https://example.com/avatars/john.jpg',
        4.8
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        'Jane Smith',
        'jane@example.com',
        '+1234567891',
        'https://example.com/avatars/jane.jpg',
        4.9
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        'Bob Johnson',
        'bob@example.com',
        '+1234567892',
        'https://example.com/avatars/bob.jpg',
        4.7
    ),
    (
        '44444444-4444-4444-4444-444444444444',
        'Alice Brown',
        'alice@example.com',
        '+1234567893',
        'https://example.com/avatars/alice.jpg',
        4.6
    ),
    (
        '55555555-5555-5555-5555-555555555555',
        'Charlie Wilson',
        'charlie@example.com',
        '+1234567894',
        'https://example.com/avatars/charlie.jpg',
        4.5
    )
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    avatar_url = EXCLUDED.avatar_url,
    rating = EXCLUDED.rating;

UPDATE profiles SET
    phone = '+1234567893',
    avatar_url = 'https://example.com/avatars/alice.jpg',
    rating = 4.6
WHERE id = '44444444-4444-4444-4444-444444444444';

UPDATE profiles SET
    phone = '+1234567894',
    avatar_url = 'https://example.com/avatars/charlie.jpg',
    rating = 4.5
WHERE id = '55555555-5555-5555-5555-555555555555';

-- Insert test rides
INSERT INTO rides (
    id, driver_id, source, destination,
    source_lat, source_lng, destination_lat, destination_lng,
    departure_time, fare, available_seats, notes
) VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'New York', 'Boston',
        40.7128, -74.0060, 42.3601, -71.0589,
        NOW() + interval '1 day',
        25.00, 3,
        'Comfortable sedan'
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        '22222222-2222-2222-2222-222222222222',
        'Los Angeles', 'San Francisco',
        34.0522, -118.2437, 37.7749, -122.4194,
        NOW() + interval '2 days',
        35.00, 2,
        'Luxury SUV'
    ),
    (
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        '33333333-3333-3333-3333-333333333333',
        'Chicago', 'Detroit',
        41.8781, -87.6298, 42.3314, -83.0458,
        NOW() + interval '3 days',
        20.00, 4,
        'Spacious van'
    ),
    (
        'dddddddd-dddd-dddd-dddd-dddddddddddd',
        '44444444-4444-4444-4444-444444444444',
        'Miami', 'Orlando',
        25.7617, -80.1918, 28.5383, -81.3792,
        NOW() + interval '4 days',
        30.00, 2,
        'Electric vehicle'
    ),
    (
        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        '55555555-5555-5555-5555-555555555555',
        'Seattle', 'Portland',
        47.6062, -122.3321, 45.5155, -122.6765,
        NOW() + interval '5 days',
        28.00, 3,
        'Hybrid car'
    )
ON CONFLICT (id) DO UPDATE SET
    source = EXCLUDED.source,
    destination = EXCLUDED.destination,
    departure_time = EXCLUDED.departure_time,
    fare = EXCLUDED.fare,
    available_seats = EXCLUDED.available_seats,
    notes = EXCLUDED.notes;

-- Insert test bookings (after some seats are taken)
INSERT INTO bookings (
    id, ride_id, passenger_id, seats, status
) VALUES    (
        'f1111111-1111-1111-1111-111111111111',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '22222222-2222-2222-2222-222222222222',
        1,
        'confirmed'
    ),
    (
        'f2222222-2222-2222-2222-222222222222',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        '33333333-3333-3333-3333-333333333333',
        2,
        'pending'
    ),
    (
        'f3333333-3333-3333-3333-333333333333',
        'dddddddd-dddd-dddd-dddd-dddddddddddd',
        '44444444-4444-4444-4444-444444444444',
        1,
        'confirmed'
    )
ON CONFLICT DO NOTHING;

-- Insert test chat messages (only for confirmed bookings)
INSERT INTO chat_messages (
    id, ride_id, sender_id, content
) VALUES
    (        'c1111111-1111-1111-1111-111111111111',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'Hi, I can pick you up at the agreed location.'
    ),
    (
        'c2222222-2222-2222-2222-222222222222',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '22222222-2222-2222-2222-222222222222',
        'Perfect, see you there!'
    )
ON CONFLICT (id) DO NOTHING;

-- Insert test ratings (only for completed rides with confirmed bookings)
INSERT INTO ratings (
    ride_id, from_user, to_user, rating, review
) VALUES    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '22222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111',
        5,
        'Great ride, very punctual!'
    ),    (
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        '44444444-4444-4444-4444-444444444444',
        '33333333-3333-3333-3333-333333333333',
        5,
        'Excellent service'
    )
ON CONFLICT (ride_id, from_user, to_user) DO NOTHING;

-- Wait a moment for triggers to complete
SELECT pg_sleep(1);