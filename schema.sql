-- Note: Extensions are created in setup.sql

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    rating DECIMAL(3,2) DEFAULT 5.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamps
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can create their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Anyone can view basic profile info of other users"
    ON profiles FOR SELECT
    USING (true);

-- Create rides table
CREATE TABLE IF NOT EXISTS rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES profiles(id),
    source TEXT NOT NULL,
    destination TEXT NOT NULL,
    source_lat DOUBLE PRECISION NOT NULL,
    source_lng DOUBLE PRECISION NOT NULL,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lng DOUBLE PRECISION NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    available_seats INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for rides
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;

-- Create policies for rides
CREATE POLICY "Anyone can view rides"
    ON rides FOR SELECT
    USING (true);

CREATE POLICY "Users can create their own rides"
    ON rides FOR INSERT
    WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Users can update their own rides"
    ON rides FOR UPDATE
    USING (auth.uid() = driver_id);

CREATE POLICY "Users can delete their own rides"
    ON rides FOR DELETE
    USING (auth.uid() = driver_id);

-- Create trigger for updating timestamps on rides
DROP TRIGGER IF EXISTS update_rides_updated_at ON rides;
CREATE TRIGGER update_rides_updated_at
    BEFORE UPDATE ON rides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    passenger_id UUID NOT NULL REFERENCES profiles(id),
    seats INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(ride_id, passenger_id)
);

-- Enable RLS for bookings
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policies for bookings
CREATE POLICY "Users can view their bookings"
    ON bookings FOR SELECT
    USING (
        auth.uid() = passenger_id OR 
        auth.uid() IN (
            SELECT driver_id FROM rides WHERE id = ride_id
        )
    );

CREATE POLICY "Users can create their own bookings"
    ON bookings FOR INSERT
    WITH CHECK (auth.uid() = passenger_id);

CREATE POLICY "Users can update their own bookings"
    ON bookings FOR UPDATE
    USING (
        auth.uid() = passenger_id OR 
        auth.uid() IN (
            SELECT driver_id FROM rides WHERE id = ride_id
        )
    );

-- Create trigger for updating timestamps on bookings
DROP TRIGGER IF EXISTS update_bookings_updated_at ON bookings;
CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to check available seats
CREATE OR REPLACE FUNCTION check_available_seats()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COALESCE(SUM(seats), 0) + NEW.seats
        FROM bookings
        WHERE ride_id = NEW.ride_id
        AND status = 'confirmed'
    ) > (
        SELECT available_seats
        FROM rides
        WHERE id = NEW.ride_id
    ) THEN
        RAISE EXCEPTION 'Not enough seats available';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check available seats before booking
DROP TRIGGER IF EXISTS check_seats_before_booking ON bookings;
CREATE TRIGGER check_seats_before_booking
    BEFORE INSERT OR UPDATE ON bookings
    FOR EACH ROW
    WHEN (NEW.status = 'confirmed')
    EXECUTE FUNCTION check_available_seats();

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    sender_id UUID NOT NULL REFERENCES profiles(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for chat_messages
CREATE POLICY "Users can view messages for their rides"
    ON chat_messages FOR SELECT
    USING (
        auth.uid() IN (
            SELECT passenger_id 
            FROM bookings 
            WHERE ride_id = chat_messages.ride_id
        ) OR 
        auth.uid() IN (
            SELECT driver_id 
            FROM rides 
            WHERE id = chat_messages.ride_id
        )
    );

CREATE POLICY "Users can send messages for their rides"
    ON chat_messages FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT passenger_id 
            FROM bookings 
            WHERE ride_id = chat_messages.ride_id
        ) OR 
        auth.uid() IN (
            SELECT driver_id 
            FROM rides 
            WHERE id = chat_messages.ride_id
        )
    );

-- Create ratings table
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES rides(id),
    from_user UUID NOT NULL REFERENCES profiles(id),
    to_user UUID NOT NULL REFERENCES profiles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(ride_id, from_user, to_user)
);

-- Enable RLS for ratings
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Create policies for ratings
CREATE POLICY "Anyone can view ratings"
    ON ratings FOR SELECT
    USING (true);

CREATE POLICY "Users can create ratings for their rides"
    ON ratings FOR INSERT
    WITH CHECK (
        auth.uid() = from_user AND (
            auth.uid() IN (
                SELECT passenger_id 
                FROM bookings 
                WHERE ride_id = ratings.ride_id
            ) OR 
            auth.uid() IN (
                SELECT driver_id 
                FROM rides 
                WHERE id = ratings.ride_id
            )
        )
    );

-- Create trigger for updating timestamps on ratings
DROP TRIGGER IF EXISTS update_ratings_updated_at ON ratings;
CREATE TRIGGER update_ratings_updated_at
    BEFORE UPDATE ON ratings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable realtime for chat_messages and bookings
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;

-- Note: Test data is managed in test_data.sql