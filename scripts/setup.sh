#!/bin/bash

# =====================================================
# Library Management System - Setup Script
# =====================================================

echo "📚 Library Management System - Setup Script"
echo "==========================================="
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed"
    echo "Install it with: npm install -g supabase"
    exit 1
fi

echo "✅ Supabase CLI found"
echo ""

# Get Supabase project details
echo ""
# Pre-filled Supabase credentials
SUPABASE_URL="https://qwayycrlpmbjyoimqgxz.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3YXl5Y3JscG1ianlvaW1xZ3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2Mjg4MDIsImV4cCI6MjA3OTIwNDgwMn0.S9Wkmm-QKAz6hoN07WiISrSJrcU48buPQV0Oq3GmTV0"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3YXl5Y3JscG1ianlvaW1xZ3h6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzYyODgwMiwiZXhwIjoyMDc5MjA0ODAyfQ.gmEHjJ1PLXXt51fXMXQ3P34xn_e5reSwDSIvosu1jUk"

echo ""
echo "🔧 Configuring frontend..."

# Update config.js with Supabase credentials
CONFIG_FILE="frontend/assets/js/config.js"

if [ -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
// Supabase Configuration
const SUPABASE_URL = '$SUPABASE_URL';
const SUPABASE_ANON_KEY = '$SUPABASE_ANON_KEY';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Export for use in other modules
window.supabaseClient = supabase;
window.SUPABASE_URL = SUPABASE_URL;
EOF
    echo "✅ Frontend configuration updated"
else
    echo "⚠️  Config file not found: $CONFIG_FILE"
fi

echo ""
echo "📦 Running database migrations..."
echo ""

# Check if psql is available
if command -v psql &> /dev/null; then
    read -p "Enter your database connection string: " DB_CONNECTION
    
    echo "Running schema migration..."
    psql "$DB_CONNECTION" -f backend/migrations/001_schema.sql
    
    echo "Running RLS policies..."
    psql "$DB_CONNECTION" -f backend/migrations/002_rls_policies.sql
    
    echo "Running functions and triggers..."
    psql "$DB_CONNECTION" -f backend/migrations/003_functions_triggers.sql
    
    echo "Loading seed data..."
    psql "$DB_CONNECTION" -f backend/seeds/001_initial_data.sql
    
    echo "✅ Database migrations completed"
else
    echo "⚠️  psql not found. Please run migrations manually via Supabase Dashboard:"
    echo "1. Go to SQL Editor"
    echo "2. Run backend/migrations/001_schema.sql"
    echo "3. Run backend/migrations/002_rls_policies.sql"
    echo "4. Run backend/migrations/003_functions_triggers.sql"
    echo "5. Run backend/seeds/001_initial_data.sql"
fi

echo ""
echo "🚀 Deploying Edge Functions..."
echo ""

# Deploy Edge Functions
supabase functions deploy daily-reminder --project-ref "$SUPABASE_URL"
supabase functions deploy reservation-queue --project-ref "$SUPABASE_URL"

echo ""
echo "✅ Setup completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Create your first staff account:"
echo "   - Go to Supabase Dashboard → Authentication → Users"
echo "   - Add user with email and password"
echo "   - Go to SQL Editor and run:"
echo "     INSERT INTO profiles (id, role, email, full_name, department)"
echo "     VALUES ('<user-id>', 'staff', 'admin@library.com', 'Admin', 'Administration');"
echo ""
echo "2. Start the frontend:"
echo "   cd frontend"
echo "   python -m http.server 8000"
echo "   # or"
echo "   npx serve"
echo ""
echo "3. Access the application:"
echo "   Staff Portal: http://localhost:8000/staff/login.html"
echo "   Member Portal: http://localhost:8000/member/login.html"
echo ""
echo "4. Setup cron jobs (optional):"
echo "   - Go to Supabase Dashboard → Database → Cron"
echo "   - Add daily-reminder (daily at 9:00 AM)"
echo "   - Add reservation-queue (every 30 minutes)"
echo ""
echo "📖 Full documentation: README.md"
echo ""
echo "🎉 Happy Library Managing!"
