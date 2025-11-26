# 📚 Library Management System

A complete, production-ready Library Management System built with **Supabase** (PostgreSQL + Auth + Edge Functions) backend and **HTML/Tailwind CSS/Vanilla JavaScript** frontend.

## 🎯 Overview

This system provides comprehensive library management capabilities with:
- **Two separate portals**: Staff and Member with role-based access control
- **Complete borrow workflow**: Request → Approval → Borrowing → Return → Fines
- **Reservation system**: Queue management with automatic promotion
- **Fine calculation**: Automatic ₱100/day late fee
- **Violation tracking**: 3-strike penalty system (30-day borrowing limit reduction)
- **Real-time notifications**: Due date reminders, overdue alerts, reservation ready
- **Audit logging**: Complete activity trail for compliance

---

## 🏗️ Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│   Frontend      │────────▶│   Supabase       │────────▶│   PostgreSQL    │
│  HTML/Tailwind  │◀────────│   (Auth + API)   │◀────────│   Database      │
│   JavaScript    │         │                  │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
                                     │
                                     ▼
                            ┌──────────────────┐
                            │  Edge Functions  │
                            │  (Deno Runtime)  │
                            └──────────────────┘
```

---

## 📁 Project Structure

```
LSM - ADS/
├── backend/
│   ├── migrations/
│   │   ├── 001_schema.sql            # Database schema with 12 tables
│   │   ├── 002_rls_policies.sql      # Row-level security policies
│   │   └── 003_functions_triggers.sql # Business logic & automation
│   └── seeds/
│       └── 001_initial_data.sql      # Sample data (21 books, 7 categories)
│
├── supabase/
│   └── functions/
│       ├── daily-reminder/           # Send due date reminders
│       │   └── index.ts
│       └── reservation-queue/        # Process reservation queue
│           └── index.ts
│
├── frontend/
│   ├── staff/                        # Staff Portal
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   ├── books.html
│   │   ├── borrow-requests.html
│   │   ├── returns.html
│   │   ├── members.html
│   │   ├── fines.html
│   │   ├── reports.html
│   │   └── js/
│   │       ├── staff-auth.js
│   │       ├── staff-common.js
│   │       └── staff-dashboard.js
│   │
│   ├── member/                       # Member Portal
│   │   ├── signup.html
│   │   ├── login.html
│   │   ├── dashboard.html
│   │   ├── catalog.html
│   │   ├── my-borrows.html
│   │   ├── reservations.html
│   │   ├── fines.html
│   │   └── js/
│   │       ├── member-auth.js
│   │       ├── member-common.js
│   │       └── member-dashboard.js
│   │
│   └── assets/
│       ├── css/
│       │   └── styles.css
│       └── js/
│           └── config.js             # Supabase configuration
│
├── scripts/
│   ├── setup.sh                      # Deployment setup script
│   └── backup.sh                     # Database backup script
│
└── docs/
    ├── README.md                     # This file
    ├── API.md                        # API documentation
    ├── ERD.md                        # Database schema diagram
    └── PRESENTATION.md               # Project presentation outline
```

---

## 🚀 Quick Start

### Prerequisites

- **Supabase Account**: Sign up at [supabase.com](https://supabase.com)
- **Node.js** (v18+) for running Edge Functions locally (optional)
- **Web Browser** (Chrome, Firefox, Edge, Safari)

### 1. Setup Supabase Project

1. **Create a new Supabase project**
   - Go to [app.supabase.com](https://app.supabase.com)
   - Click "New Project"
   - Set project name, database password, and region

2. **Run Database Migrations**
   - Go to SQL Editor in Supabase Dashboard
   - Execute in order:
     ```sql
     -- Step 1: Copy and run backend/migrations/001_schema.sql
     -- Step 2: Copy and run backend/migrations/002_rls_policies.sql
     -- Step 3: Copy and run backend/migrations/003_functions_triggers.sql
     -- Step 4: Copy and run backend/seeds/001_initial_data.sql
     ```

3. **Get API Credentials**
   - Go to Project Settings → API
   - Copy:
     - `Project URL` (e.g., https://xxxxx.supabase.co)
     - `anon public` key

### 2. Configure Frontend

1. **Update Supabase Configuration**
   - Open `frontend/assets/js/config.js`
   - Replace placeholders:
     ```javascript
     const SUPABASE_URL = 'https://your-project.supabase.co';
     const SUPABASE_ANON_KEY = 'your-anon-key-here';
     ```

### 3. Create Initial Staff Account

Since staff accounts are not publicly created, you need to create the first one manually:

1. **Go to Supabase Dashboard → Authentication → Users**
2. **Click "Add User"**
   - Email: `admin@library.com`
   - Password: Choose a secure password
   - Auto-confirm: **Yes**

3. **Create Staff Profile**
   - Go to SQL Editor
   - Run:
     ```sql
     INSERT INTO profiles (id, role, email, full_name, department)
     VALUES (
         '<user-id-from-auth-users>',
         'staff',
         'admin@library.com',
         'Library Administrator',
         'Administration'
     );
     ```

### 4. Deploy Frontend

**Option A: Local Development**
```bash
cd frontend
python -m http.server 8000
# or
npx serve
```

**Option B: Deploy to Netlify/Vercel**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd frontend
netlify deploy --prod
```

**Option C: Deploy to GitHub Pages**
```bash
# Push frontend folder to gh-pages branch
git subtree push --prefix frontend origin gh-pages
```

### 5. Deploy Edge Functions (Optional)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref <your-project-ref>

# Deploy functions
supabase functions deploy daily-reminder
supabase functions deploy reservation-queue
```

### 6. Setup Cron Jobs (Optional)

In Supabase Dashboard → Database → Cron Jobs:

```sql
-- Daily reminder at 9:00 AM
SELECT cron.schedule(
    'daily-reminder',
    '0 9 * * *',
    $$
    SELECT net.http_post(
        url := 'https://your-project.supabase.co/functions/v1/daily-reminder',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
    );
    $$
);

-- Reservation queue every 30 minutes
SELECT cron.schedule(
    'reservation-queue',
    '*/30 * * * *',
    $$
    SELECT net.http_post(
        url := 'https://your-project.supabase.co/functions/v1/reservation-queue',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
    );
    $$
);
```

---

## 👥 User Roles & Access

### 🔐 Staff Portal (`/staff/login.html`)

**Capabilities:**
- ✅ Full CRUD on books
- ✅ Approve/reject borrow requests
- ✅ Process returns & calculate fines
- ✅ Manage fines & payments
- ✅ Activate/deactivate members
- ✅ View all reports & analytics
- ✅ Manage reservations

**Default Credentials:**
```
Email: admin@library.com
Password: (set during creation)
```

### 👤 Member Portal (`/member/login.html`)

**Capabilities:**
- ✅ Browse & search book catalog
- ✅ Submit borrow requests (1-5 days)
- ✅ Reserve borrowed books (queue system)
- ✅ View borrow history
- ✅ Pay fines (recorded by staff)
- ✅ Receive notifications

**Registration:**
- Self-signup via `/member/signup.html`
- Automatic Member ID generation (MEM-00001, MEM-00002, ...)
- Staff must activate account

---

## 📊 Key Features

### 1. Borrow System
- **Request Flow**: Member requests → Staff approves → Auto-deduct copy → Due date set
- **Duration**: 1-5 days (member selects start date + duration)
- **Limits**:
  - Normal members: 5 books
  - Penalized members: 2 books
- **Auto-calculations**: Due date, overdue days, fines

### 2. Fine System
- **Rate**: ₱100 per day overdue
- **Auto-generation**: On book return (if late)
- **Payment tracking**: Multiple partial payments supported
- **Blocking**: Cannot borrow with unpaid fines

### 3. Violation & Penalty System
- **Tracking**: Every overdue book = 1 violation
- **Threshold**: 3 violations → 30-day penalty
- **Penalty effect**: Borrow limit reduced from 5 to 2
- **Auto-expire**: After 30 days

### 4. Reservation System
- **Queue-based**: First come, first served
- **Auto-promotion**: Next in queue notified when book available
- **Expiry**: 48 hours to borrow after notification
- **No duplicates**: One active reservation per book per member

### 5. Notifications
- **Due tomorrow**: Sent 1 day before due date
- **Overdue alerts**: Daily for overdue books
- **Reservation ready**: When book becomes available
- **Fine issued**: When fine is created
- **Payment received**: Confirmation of payment

---

## 🗄️ Database Schema

### Core Tables (12)

1. **profiles** - User accounts (staff + members)
2. **books** - Book catalog
3. **book_copies** - Individual physical copies
4. **borrow_requests** - Pending borrow requests
5. **borrow_records** - Active & historical borrows
6. **reservations** - Book reservations
7. **fines** - Issued fines
8. **payments** - Fine payments
9. **violation_history** - Member violations
10. **notifications** - User notifications
11. **audit_logs** - Activity audit trail
12. **system_settings** - Configuration

See [ERD.md](docs/ERD.md) for complete schema diagram.

---

## 🔧 Configuration

### System Settings (editable by staff)

```sql
SELECT * FROM system_settings;
```

| Key | Default | Description |
|-----|---------|-------------|
| `fine_per_day` | 100 | Fine amount per day (PHP) |
| `max_borrow_limit_normal` | 5 | Books normal members can borrow |
| `max_borrow_limit_penalized` | 2 | Books penalized members can borrow |
| `max_borrow_duration` | 5 | Maximum borrow days |
| `violation_threshold` | 3 | Violations before penalty |
| `penalty_duration_days` | 30 | Penalty duration |
| `reservation_expiry_hours` | 48 | Hours to borrow after notification |

---

## 🧪 Testing

### Test Accounts

**Staff:**
```
Email: admin@library.com
Password: (your password)
```

**Members:**
Create via signup page or SQL:
```sql
-- Create member via auth first, then:
INSERT INTO profiles (id, role, email, full_name)
VALUES ('<auth-user-id>', 'member', 'test@member.com', 'Test Member');
```

### Test Scenarios

1. **Borrow Flow**
   - Member: Request book → Select start date + duration
   - Staff: Approve request → Book auto-issued
   - Staff: Process return → Fine auto-calculated (if late)

2. **Reservation Flow**
   - Member: Reserve borrowed book
   - Staff: Return book → Next in queue notified
   - Member: Borrow within 48 hours

3. **Penalty Flow**
   - Return 3+ books late → Auto-penalty applied
   - Borrow limit reduced to 2
   - After 30 days → Auto-removed

---

## 🔒 Security

- **RLS (Row Level Security)**: Enabled on all tables
- **Staff-only operations**: Create books, approve requests, process returns
- **Member self-access**: Only view/modify own data
- **No service role key in frontend**: Only anon key used
- **Separate login portals**: Role-based authentication
- **Audit logging**: All operations tracked
- **Soft deletes**: Data retained for compliance

---

## 📈 Reports & Analytics

Staff can access:
- 📊 Overdue books report
- 📚 Most borrowed books
- 👥 Active/inactive members
- 💰 Fine summary
- 📖 Borrow logs

---

## 🛠️ Maintenance

### Backup Database
```bash
bash scripts/backup.sh
```

### Manual Data Cleanup
```sql
-- Remove old notifications (90+ days)
DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '90 days';

-- Remove resolved violations (180+ days)
DELETE FROM violation_history 
WHERE is_resolved = TRUE AND resolved_at < NOW() - INTERVAL '180 days';
```

---

## 📞 Support

For issues or questions:
1. Check [API.md](docs/API.md) for API documentation
2. Review [ERD.md](docs/ERD.md) for database schema
3. Check Supabase Dashboard → Logs for errors

---

## 📝 License

This project is provided for educational purposes.

---

## 🙏 Credits

Built with:
- [Supabase](https://supabase.com) - Backend infrastructure
- [Tailwind CSS](https://tailwindcss.com) - UI framework
- [PostgreSQL](https://www.postgresql.org) - Database

---

**🎉 Happy Library Managing!**
