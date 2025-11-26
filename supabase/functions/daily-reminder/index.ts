// Supabase Edge Function: daily-reminder
// Send daily reminders for due books and overdue notices

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
    // Create Supabase client with service role key for admin operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const results = {
      overdue_checked: false,
      due_reminders_sent: 0,
      overdue_notifications_sent: 0,
      errors: []
    }

    // 1. Check and update overdue records
    try {
      const { error: overdueError } = await supabaseClient.rpc('check_overdue_records')
      if (overdueError) {
        results.errors.push(`Overdue check error: ${overdueError.message}`)
      } else {
        results.overdue_checked = true
      }
    } catch (err) {
      results.errors.push(`Overdue check exception: ${err.message}`)
    }

    // 2. Send due date reminders (books due tomorrow)
    try {
      const { data: dueReminders, error: dueError } = await supabaseClient.rpc('send_due_date_reminders')
      if (dueError) {
        results.errors.push(`Due reminders error: ${dueError.message}`)
      } else {
        results.due_reminders_sent = dueReminders?.length || 0
      }
    } catch (err) {
      results.errors.push(`Due reminders exception: ${err.message}`)
    }

    // 3. Send overdue notifications
    try {
      const { error: overdueNotifError } = await supabaseClient.rpc('send_overdue_notifications')
      if (overdueNotifError) {
        results.errors.push(`Overdue notifications error: ${overdueNotifError.message}`)
      } else {
        // Count today's overdue notifications
        const { data: notifCount } = await supabaseClient
          .from('notifications')
          .select('id', { count: 'exact', head: true })
          .eq('type', 'overdue')
          .gte('created_at', new Date().toISOString().split('T')[0])
        
        results.overdue_notifications_sent = notifCount || 0
      }
    } catch (err) {
      results.errors.push(`Overdue notifications exception: ${err.message}`)
    }

    // 4. Expire old reservations
    try {
      const { error: expireError } = await supabaseClient.rpc('expire_old_reservations')
      if (expireError) {
        results.errors.push(`Expire reservations error: ${expireError.message}`)
      }
    } catch (err) {
      results.errors.push(`Expire reservations exception: ${err.message}`)
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
