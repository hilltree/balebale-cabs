import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Location {
  lat: number
  lng: number
}

serve(async (req) => {
  try {
    const { lat, lng, maxDistance = 10, date } = await req.json()
    
    if (!lat || !lng || !date) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { status: 400 }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Convert maxDistance from kilometers to meters
    const maxDistanceMeters = maxDistance * 1000

    // Query for nearby rides
    const { data: rides, error } = await supabaseClient
      .rpc('find_nearby_rides', {
        user_lat: lat,
        user_lng: lng,
        max_distance: maxDistanceMeters,
        ride_date: date
      })

    if (error) throw error

    return new Response(
      JSON.stringify({ rides }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
}) 