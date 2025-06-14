import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Location {
  lat: number
  lng: number
}

serve(async (req) => {
  try {
    const { source, destination, seats = 1 } = await req.json()
    
    if (!source || !destination) {
      return new Response(
        JSON.stringify({ error: 'Missing source or destination' }),
        { status: 400 }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Calculate distance using PostGIS
    const { data: distance, error: distanceError } = await supabaseClient
      .rpc('calculate_distance', {
        source_lat: source.lat,
        source_lng: source.lng,
        dest_lat: destination.lat,
        dest_lng: destination.lng
      })

    if (distanceError) throw distanceError

    // Base fare calculation
    const baseFare = 2.0 // Base fare in currency units
    const perKmRate = 0.5 // Rate per kilometer
    const distanceKm = distance / 1000 // Convert meters to kilometers
    
    // Calculate total fare
    const totalFare = (baseFare + (distanceKm * perKmRate)) * seats

    // Apply surge pricing if needed (example: rush hour)
    const hour = new Date().getHours()
    const isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18)
    const surgeMultiplier = isRushHour ? 1.5 : 1.0

    const finalFare = totalFare * surgeMultiplier

    return new Response(
      JSON.stringify({
        base_fare: baseFare,
        distance_km: distanceKm,
        per_km_rate: perKmRate,
        seats: seats,
        surge_multiplier: surgeMultiplier,
        total_fare: finalFare
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
}) 