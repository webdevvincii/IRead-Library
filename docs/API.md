# 📖 API Documentation

This document describes the database functions, Edge Functions, and common operations for the Library Management System.

---

## 🗄️ Database Functions

### Helper Functions

#### `is_staff()` → `BOOLEAN`
Checks if current authenticated user has staff role.

```sql
SELECT is_staff(); -- Returns TRUE/FALSE
```

#### `is_member()` → `BOOLEAN`
Checks if current authenticated user has member role.

#### `can_member_borrow(member_id UUID)` → `BOOLEAN`
Checks if member is eligible to borrow books.

**Checks:**
- Member status is 'active'
- No active penalty
- No unpaid fines

```sql
SELECT can_member_borrow('user-uuid'); -- TRUE if eligible
```

#### `get_current_borrow_count(member_id UUID)` → `INTEGER`
Returns number of active borrows for a member.

#### `get_borrow_limit(member_id UUID)` → `INTEGER`
Returns borrow limit (5 for normal, 2 for penalized).

---

### Number Generators

All generate unique formatted numbers:

- `generate_member_id()` → `MEM-00001`
- `generate_staff_id()` → `STAFF-00001`
- `generate_request_number()` → `REQ-YYYYMMDD-XXXX`
- `generate_borrow_number()` → `BRW-YYYYMMDD-XXXX`
- `generate_reservation_number()` → `RES-YYYYMMDD-XXXX`
- `generate_fine_number()` → `FINE-YYYYMMDD-XXXX`
- `generate_payment_number()` → `PAY-YYYYMMDD-XXXX`

---

### Business Logic Functions

#### `apply_penalty_if_needed(member_id UUID)`
Checks violation count and applies penalty if threshold (3) reached.

```sql
SELECT apply_penalty_if_needed('member-uuid');
```

#### `promote_next_reservation(book_id UUID)`
Promotes next member in reservation queue when book becomes available.

```sql
SELECT promote_next_reservation('book-uuid');
```

#### `check_overdue_records()`
Updates status of overdue borrow records.

```sql
SELECT check_overdue_records();
```

#### `send_due_date_reminders()`
Creates notifications for books due tomorrow.

```sql
SELECT send_due_date_reminders();
```

#### `send_overdue_notifications()`
Creates notifications for overdue books.

```sql
SELECT send_overdue_notifications();
```

#### `expire_old_reservations()`
Expires reservations past expiry time and reorders queue.

```sql
SELECT expire_old_reservations();
```

---

### Report Functions

#### `get_overdue_books_report()`
Returns list of overdue books with member details.

**Returns:**
```
borrow_number | member_name | member_id | book_title | due_date | days_overdue | estimated_fine
```

```sql
SELECT * FROM get_overdue_books_report();
```

#### `get_most_borrowed_books(limit INTEGER)`
Returns most frequently borrowed books.

**Returns:**
```
book_id | title | author | borrow_count
```

```sql
SELECT * FROM get_most_borrowed_books(10);
```

#### `get_member_statistics()`
Returns member statistics.

**Returns:**
```
total_members | active_members | penalized_members | inactive_members
```

```sql
SELECT * FROM get_member_statistics();
```

---

## 🌐 Edge Functions

### 1. daily-reminder

**URL:** `https://your-project.supabase.co/functions/v1/daily-reminder`

**Method:** POST

**Purpose:** Daily maintenance tasks
- Check and update overdue records
- Send due date reminders
- Send overdue notifications
- Expire old reservations

**Request:**
```bash
curl -X POST https://your-project.supabase.co/functions/v1/daily-reminder \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

**Response:**
```json
{
  "success": true,
  "timestamp": "2025-11-25T10:00:00.000Z",
  "results": {
    "overdue_checked": true,
    "due_reminders_sent": 5,
    "overdue_notifications_sent": 2,
    "errors": []
  }
}
```

**Schedule:** Daily at 9:00 AM via cron

---

### 2. reservation-queue

**URL:** `https://your-project.supabase.co/functions/v1/reservation-queue`

**Method:** POST

**Purpose:** Process reservation queue
- Promote next in queue when book available
- Expire reservations past deadline
- Reorder queue positions

**Request:**
```bash
curl -X POST https://your-project.supabase.co/functions/v1/reservation-queue \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

**Response:**
```json
{
  "success": true,
  "timestamp": "2025-11-25T10:30:00.000Z",
  "results": {
    "processed": 3,
    "promoted": 2,
    "expired": 1,
    "errors": []
  }
}
```

**Schedule:** Every 30 minutes via cron

---

## 📡 Frontend API Usage

### Authentication

#### Staff Login
```javascript
const { data, error } = await supabaseClient.auth.signInWithPassword({
  email: 'staff@library.com',
  password: 'password'
});

// Verify role
const { data: profile } = await supabaseClient
  .from('profiles')
  .select('role')
  .eq('id', data.user.id)
  .single();

if (profile.role !== 'staff') {
  await supabaseClient.auth.signOut();
}
```

#### Member Signup
```javascript
const { data, error } = await supabaseClient.auth.signUp({
  email: 'member@email.com',
  password: 'password',
  options: {
    data: { role: 'member', full_name: 'John Doe' }
  }
});

// Create profile
await supabaseClient.from('profiles').insert({
  id: data.user.id,
  role: 'member',
  email: 'member@email.com',
  full_name: 'John Doe'
});
```

---

### Book Operations

#### List Books
```javascript
const { data: books, error } = await supabaseClient
  .from('books')
  .select('*')
  .is('deleted_at', null)
  .order('title');
```

#### Search Books
```javascript
const { data: books, error } = await supabaseClient
  .from('books')
  .select('*')
  .or(`title.ilike.%${searchTerm}%,author.ilike.%${searchTerm}%`)
  .is('deleted_at', null);
```

#### Add Book (Staff Only)
```javascript
const { data, error } = await supabaseClient
  .from('books')
  .insert({
    isbn: '978-0-123456-78-9',
    title: 'Book Title',
    author: 'Author Name',
    category: 'Fiction',
    total_copies: 3,
    available_copies: 3
  });
```

---

### Borrow Operations

#### Create Borrow Request (Member)
```javascript
const { data, error } = await supabaseClient
  .from('borrow_requests')
  .insert({
    member_id: userId,
    book_id: bookId,
    requested_start_date: '2025-11-26',
    requested_duration: 3
  });
```

#### Approve Borrow Request (Staff)
```javascript
// 1. Update request status
await supabaseClient
  .from('borrow_requests')
  .update({
    status: 'approved',
    processed_by: staffId,
    processed_at: new Date().toISOString()
  })
  .eq('id', requestId);

// 2. Create borrow record
const dueDate = new Date(startDate);
dueDate.setDate(dueDate.getDate() + duration);

await supabaseClient
  .from('borrow_records')
  .insert({
    request_id: requestId,
    member_id: memberId,
    book_id: bookId,
    borrow_date: startDate,
    due_date: dueDate.toISOString().split('T')[0],
    issued_by: staffId
  });
```

#### Process Return (Staff)
```javascript
await supabaseClient
  .from('borrow_records')
  .update({
    return_date: new Date().toISOString().split('T')[0],
    returned_to: staffId,
    return_notes: 'Book in good condition'
  })
  .eq('id', borrowId);

// Fine is auto-calculated by trigger if overdue
```

---

### Reservation Operations

#### Create Reservation (Member)
```javascript
const { data, error } = await supabaseClient
  .from('reservations')
  .insert({
    member_id: userId,
    book_id: bookId
  });
// Queue position is auto-assigned
```

#### Cancel Reservation (Member)
```javascript
await supabaseClient
  .from('reservations')
  .update({
    status: 'cancelled',
    cancelled_at: new Date().toISOString(),
    cancellation_reason: 'No longer needed'
  })
  .eq('id', reservationId)
  .eq('member_id', userId);
```

---

### Fine & Payment Operations

#### Get Member Fines
```javascript
const { data: fines, error } = await supabaseClient
  .from('fines')
  .select(`
    *,
    borrow_record:borrow_record_id(
      book:book_id(title)
    )
  `)
  .eq('member_id', userId)
  .eq('is_paid', false);
```

#### Record Payment (Staff)
```javascript
await supabaseClient
  .from('payments')
  .insert({
    member_id: memberId,
    fine_id: fineId,
    amount: paymentAmount,
    payment_method: 'cash',
    received_by: staffId
  });
// Fine paid_amount is auto-updated by trigger
```

---

### Notification Operations

#### Get Unread Notifications
```javascript
const { data: notifications, error } = await supabaseClient
  .from('notifications')
  .select('*')
  .eq('user_id', userId)
  .eq('is_read', false)
  .order('created_at', { ascending: false });
```

#### Mark Notification as Read
```javascript
await supabaseClient
  .from('notifications')
  .update({
    is_read: true,
    read_at: new Date().toISOString()
  })
  .eq('id', notificationId)
  .eq('user_id', userId);
```

---

## 🔐 Row Level Security (RLS)

All tables have RLS enabled. Access is determined by user role:

### Staff Access
- **SELECT**: All records
- **INSERT**: All tables
- **UPDATE**: All records
- **DELETE**: Soft delete (update deleted_at)

### Member Access
- **SELECT**: Own records only (member_id = auth.uid())
- **INSERT**: Limited (borrow_requests, reservations)
- **UPDATE**: Own records only (limited fields)
- **DELETE**: Not allowed

### Anonymous Access
- **SELECT**: system_settings (library info only)
- All other operations: Denied

---

## 📊 Common Queries

### Check if member can borrow
```sql
SELECT 
  can_member_borrow(auth.uid()) as can_borrow,
  get_current_borrow_count(auth.uid()) as current_borrows,
  get_borrow_limit(auth.uid()) as borrow_limit;
```

### Get member's borrowing status
```sql
SELECT 
  p.member_id,
  p.full_name,
  p.member_status,
  p.is_penalized,
  COUNT(br.id) FILTER (WHERE br.status = 'active') as active_borrows,
  SUM(f.balance) FILTER (WHERE f.is_paid = FALSE) as unpaid_fines,
  p.total_violations
FROM profiles p
LEFT JOIN borrow_records br ON br.member_id = p.id
LEFT JOIN fines f ON f.member_id = p.id
WHERE p.id = auth.uid()
GROUP BY p.id;
```

### Get book availability
```sql
SELECT 
  b.id,
  b.title,
  b.total_copies,
  b.available_copies,
  b.status,
  COUNT(r.id) FILTER (WHERE r.status = 'active') as active_reservations
FROM books b
LEFT JOIN reservations r ON r.book_id = b.id
WHERE b.id = 'book-uuid'
GROUP BY b.id;
```

---

## 🔧 Error Handling

### Common Errors

**Authentication Required**
```json
{
  "code": "PGRST301",
  "message": "JWT expired"
}
```
**Solution:** Refresh session or re-login

**Permission Denied**
```json
{
  "code": "42501",
  "message": "new row violates row-level security policy"
}
```
**Solution:** Check user role and permissions

**Constraint Violation**
```json
{
  "code": "23505",
  "message": "duplicate key value violates unique constraint"
}
```
**Solution:** Check for duplicate records (ISBN, email, etc.)

**Check Constraint Failed**
```json
{
  "code": "23514",
  "message": "Borrow limit reached"
}
```
**Solution:** Verify business rules (borrow limits, eligibility, etc.)

---

## 📞 Support

For additional API questions:
- Check Supabase Dashboard → API Docs
- Review database schema in `backend/migrations/`
- Check function definitions in `003_functions_triggers.sql`
