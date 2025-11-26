// Supabase Edge Function: reservation-queue
// Process reservation queue and notify members when books become available

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const results = {
      processed: 0,
      promoted: 0,
      expired: 0,
      errors: []
    }

    // 1. Get books that have available copies and active reservations
    const { data: availableBooks, error: booksError } = await supabaseClient
      .from('books')
      .select(`
        id,
        title,
        available_copies,
        reservations!inner(
          id,
          reservation_number,
          member_id,
          status,
          queue_position,
          expires_at
        )
      `)
      .gt('available_copies', 0)
      .eq('reservations.status', 'active')
      .is('reservations.expires_at', null)
      .order('reservations.queue_position', { ascending: true })

    if (booksError) {
      results.errors.push(`Books query error: ${booksError.message}`)
    } else if (availableBooks && availableBooks.length > 0) {
      // 2. Process each book's reservation queue
      for (const book of availableBooks) {
        try {
          results.processed++

          // Get reservation expiry hours from settings
          const { data: setting } = await supabaseClient
            .from('system_settings')
            .select('value')
            .eq('key', 'reservation_expiry_hours')
            .single()

          const expiryHours = parseInt(setting?.value || '48')
          const expiresAt = new Date()
          expiresAt.setHours(expiresAt.getHours() + expiryHours)

          // Get the first reservation in queue (lowest queue_position)
          const reservation = book.reservations[0]

          // Update reservation with expiry time
          const { error: updateError } = await supabaseClient
            .from('reservations')
            .update({ expires_at: expiresAt.toISOString() })
            .eq('id', reservation.id)

          if (updateError) {
            results.errors.push(`Update reservation error: ${updateError.message}`)
            continue
          }

          // Create notification for member
          const { data: bookData } = await supabaseClient
            .from('books')
            .select('title')
            .eq('id', book.id)
            .single()

          const { error: notifError } = await supabaseClient
            .from('notifications')
            .insert({
              user_id: reservation.member_id,
              type: 'reservation_ready',
              title: 'Your Reserved Book is Available!',
              message: `Your reserved book "${bookData?.title || 'Book'}" is now available. Please borrow within ${expiryHours} hours or your reservation will expire.`,
              reservation_id: reservation.id
            })

          if (notifError) {
            results.errors.push(`Notification error: ${notifError.message}`)
          } else {
            results.promoted++
          }

        } catch (err) {
          results.errors.push(`Processing error: ${err.message}`)
        }
      }
    }

    // 3. Expire old reservations that have passed expiry time
    try {
      const now = new Date().toISOString()
      
      const { data: expiredReservations, error: expireError } = await supabaseClient
        .from('reservations')
        .update({
          status: 'expired',
          cancellation_reason: 'Reservation expired - time limit exceeded'
        })
        .eq('status', 'active')
        .not('expires_at', 'is', null)
        .lt('expires_at', now)
        .select('id, member_id, book_id')

      if (expireError) {
        results.errors.push(`Expire error: ${expireError.message}`)
      } else if (expiredReservations && expiredReservations.length > 0) {
        results.expired = expiredReservations.length

        // Notify members about expired reservations
        for (const reservation of expiredReservations) {
          await supabaseClient
            .from('notifications')
            .insert({
              user_id: reservation.member_id,
              type: 'reservation_expired',
              title: 'Reservation Expired',
              message: 'Your reservation has expired. You can create a new reservation if the book is still available.',
              reservation_id: reservation.id
            })

          // Promote next in queue for this book
          await supabaseClient.rpc('promote_next_reservation', { p_book_id: reservation.book_id })
        }
      }
    } catch (err) {
      results.errors.push(`Expiry exception: ${err.message}`)
    }

    // 4. Reorder queue positions for consistency
    try {
      const { error: reorderError } = await supabaseClient.rpc('expire_old_reservations')
      if (reorderError) {
        results.errors.push(`Reorder error: ${reorderError.message}`)
      }
    } catch (err) {
      results.errors.push(`Reorder exception: ${err.message}`)
    }

    // Return results
    return new Response(
      JSON.stringify({
        success: results.errors.length === 0,
        timestamp: new Date().toISOString(),
        results
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
