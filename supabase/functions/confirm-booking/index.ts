import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { booking_id } = await req.json()
    
    if (!booking_id) {
      return new Response(
        JSON.stringify({ error: 'Missing booking_id' }),
        { status: 400 }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Start a transaction to ensure data consistency
    const { data: booking, error: bookingError } = await supabaseClient
      .from('bookings')
      .select('*, rides(*)')
      .eq('id', booking_id)
      .single()

    if (bookingError) throw bookingError

    // Check if the booking is pending
    if (booking.status !== 'pending') {
      return new Response(
        JSON.stringify({ error: 'Booking is not in pending status' }),
        { status: 400 }
      )
    }

    // Check if there are enough seats available
    if (booking.rides.seats_available < booking.seats_booked) {
      return new Response(
        JSON.stringify({ error: 'Not enough seats available' }),
        { status: 400 }
      )
    }

    // Update booking status and reduce available seats
    const { error: updateError } = await supabaseClient.rpc('confirm_booking', {
      p_booking_id: booking_id,
      p_seats_booked: booking.seats_booked
    })

    if (updateError) throw updateError

    return new Response(
      JSON.stringify({ message: 'Booking confirmed successfully' }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
}) 