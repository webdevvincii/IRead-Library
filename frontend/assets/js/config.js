// Supabase Configuration
const SUPABASE_URL = 'https://qwayycrlpmbjyoimqgxz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3YXl5Y3JscG1ianlvaW1xZ3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2Mjg4MDIsImV4cCI6MjA3OTIwNDgwMn0.S9Wkmm-QKAz6hoN07WiISrSJrcU48buPQV0Oq3GmTV0';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Export for use in other modules
window.supabaseClient = supabase;
window.SUPABASE_URL = SUPABASE_URL;
