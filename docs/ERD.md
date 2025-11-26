# 📊 Entity Relationship Diagram (ERD)

## Database Schema Overview

```mermaid
erDiagram
    profiles ||--o{ borrow_requests : creates
    profiles ||--o{ borrow_records : borrows
    profiles ||--o{ reservations : reserves
    profiles ||--o{ fines : incurs
    profiles ||--o{ payments : makes
    profiles ||--o{ violation_history : has
    profiles ||--o{ notifications : receives
    profiles ||--o{ audit_logs : performs
    
    books ||--o{ book_copies : has
    books ||--o{ borrow_requests : requested
    books ||--o{ borrow_records : borrowed
    books ||--o{ reservations : reserved
    
    borrow_requests ||--o| borrow_records : becomes
    borrow_records ||--o{ fines : generates
    borrow_records ||--o{ violation_history : creates
    
    fines ||--o{ payments : paid_by
    
    profiles {
        uuid id PK
        user_role role
        string email UK
        string full_name
        string phone
        text address
        string member_id UK
        member_status member_status
        int total_violations
        boolean is_penalized
        timestamp penalty_until
        string staff_id UK
        string department
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    books {
        uuid id PK
        string isbn UK
        string title
        string author
        string category
        string shelf_no
        text description
        string cover_url
        string publisher
        int publication_year
        int total_copies
        int available_copies
        book_status status
        uuid created_by FK
        uuid updated_by FK
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    book_copies {
        uuid id PK
        uuid book_id FK
        int copy_number
        string barcode UK
        book_status status
        string condition
        text notes
        timestamp created_at
        timestamp updated_at
    }
    
    borrow_requests {
        uuid id PK
        string request_number UK
        uuid member_id FK
        uuid book_id FK
        date requested_start_date
        int requested_duration
        borrow_request_status status
        uuid processed_by FK
        timestamp processed_at
        text rejection_reason
        timestamp created_at
        timestamp updated_at
    }
    
    borrow_records {
        uuid id PK
        string borrow_number UK
        uuid request_id FK
        uuid member_id FK
        uuid book_id FK
        uuid book_copy_id FK
        date borrow_date
        date due_date
        date return_date
        borrow_record_status status
        uuid issued_by FK
        uuid returned_to FK
        int days_overdue
        decimal fine_amount
        boolean fine_paid
        text issue_notes
        text return_notes
        timestamp created_at
        timestamp updated_at
    }
    
    reservations {
        uuid id PK
        string reservation_number UK
        uuid member_id FK
        uuid book_id FK
        reservation_status status
        int queue_position
        timestamp reserved_at
        timestamp expires_at
        timestamp fulfilled_at
        timestamp cancelled_at
        text cancellation_reason
        timestamp created_at
        timestamp updated_at
    }
    
    fines {
        uuid id PK
        string fine_number UK
        uuid member_id FK
        uuid borrow_record_id FK
        decimal amount
        text reason
        int days_overdue
        decimal paid_amount
        decimal balance GENERATED
        boolean is_paid
        timestamp paid_at
        uuid issued_by FK
        timestamp created_at
        timestamp updated_at
    }
    
    payments {
        uuid id PK
        string payment_number UK
        uuid member_id FK
        uuid fine_id FK
        decimal amount
        string payment_method
        string reference_number
        payment_status status
        uuid received_by FK
        string receipt_url
        text notes
        timestamp payment_date
        timestamp created_at
        timestamp updated_at
    }
    
    violation_history {
        uuid id PK
        uuid member_id FK
        uuid borrow_record_id FK
        string violation_type
        text description
        string severity
        int days_overdue
        boolean is_resolved
        timestamp resolved_at
        text resolution_notes
        uuid recorded_by FK
        uuid resolved_by FK
        timestamp violation_date
        timestamp created_at
        timestamp updated_at
    }
    
    notifications {
        uuid id PK
        uuid user_id FK
        string type
        string title
        text message
        uuid borrow_record_id FK
        uuid reservation_id FK
        uuid fine_id FK
        boolean is_read
        timestamp read_at
        timestamp sent_at
        boolean email_sent
        timestamp created_at
    }
    
    audit_logs {
        uuid id PK
        uuid user_id FK
        string user_email
        user_role user_role
        string action
        string table_name
        uuid record_id
        jsonb old_values
        jsonb new_values
        inet ip_address
        text user_agent
        text description
        timestamp created_at
    }
    
    system_settings {
        string key PK
        text value
        text description
        string data_type
        uuid updated_by FK
        timestamp created_at
        timestamp updated_at
    }
```

---

## ENUMS

### user_role
- `staff` - Staff member (full access)
- `member` - Library member (limited access)

### book_status
- `available` - Book can be borrowed
- `borrowed` - All copies currently borrowed
- `reserved` - Reserved by members
- `lost` - Book reported lost
- `under_repair` - Book being repaired

### borrow_request_status
- `pending` - Awaiting staff approval
- `approved` - Approved by staff
- `rejected` - Rejected by staff
- `cancelled` - Cancelled by member

### borrow_record_status
- `active` - Currently borrowed
- `returned` - Book returned
- `overdue` - Past due date

### reservation_status
- `active` - Currently in queue
- `fulfilled` - Member borrowed the book
- `cancelled` - Cancelled by member
- `expired` - Expired (not borrowed in time)

### payment_status
- `pending` - Payment pending
- `completed` - Payment completed
- `cancelled` - Payment cancelled

### member_status
- `active` - Normal borrowing privileges
- `inactive` - Account inactive (no borrowing)
- `suspended` - Suspended by staff
- `penalized` - Penalty active (reduced limits)

---

## Key Relationships

### 1. Profile → Borrow Flow
```
Member (profile)
  ↓ creates
Borrow Request
  ↓ approved by Staff
Borrow Record (book issued)
  ↓ if overdue
Fine + Violation
  ↓ if threshold reached
Penalty Applied
```

### 2. Book → Reservation Flow
```
Book (borrowed)
  ↓ member reserves
Reservation (queue position assigned)
  ↓ book returned
Next in Queue Promoted (notification sent)
  ↓ expires in 48h
Reservation Expires (if not borrowed)
```

### 3. Fine → Payment Flow
```
Fine Issued (on overdue return)
  ↓ staff records
Payment (full or partial)
  ↓ updates
Fine Balance
  ↓ when balance = 0
Fine Marked Paid
```

---

## Indexes

### Performance Indexes
- `profiles`: role, member_id, staff_id, member_status, deleted_at
- `books`: isbn, title, author, category, status, deleted_at, full-text search
- `borrow_records`: member_id, book_id, status, due_date, overdue index
- `borrow_requests`: member_id, book_id, status, request_number, created_at
- `reservations`: member_id, book_id, status, queue (book_id + position), expires_at
- `fines`: member_id, borrow_record_id, is_paid, balance
- `notifications`: user_id, is_read, type, created_at

---

## Triggers

### Auto-Generation Triggers
- `profiles`: Auto-generate member_id/staff_id on insert
- `borrow_requests`: Auto-generate request_number
- `borrow_records`: Auto-generate borrow_number
- `reservations`: Auto-generate reservation_number + queue_position
- `fines`: Auto-generate fine_number
- `payments`: Auto-generate payment_number

### Business Logic Triggers
- `books`: Update status based on available_copies
- `borrow_records` (before insert): Decrease available_copies, assign book_copy
- `borrow_records` (before update): Increase available_copies on return
- `borrow_records` (before update): Calculate fine on overdue return
- `borrow_records` (after update): Create violation, promote reservations
- `payments` (after insert): Update fine paid_amount

### Audit Triggers
- All major tables log to `audit_logs` on INSERT/UPDATE/DELETE

---

## Constraints

### Business Rules Enforced
- `books`: available_copies ≤ total_copies
- `borrow_requests`: requested_duration BETWEEN 1 AND 5
- `borrow_records`: due_date ≥ borrow_date
- `profiles`: member requires member_id, staff requires staff_id
- `profiles`: penalty requires penalty_until date
- `fines`: paid_amount ≤ amount
- `reservations`: No duplicate active reservations per member per book

### Unique Constraints
- All formatted numbers (MEM-XXXXX, REQ-YYYYMMDD-XXXX, etc.)
- Email addresses
- ISBN
- Book copy barcodes
- (book_id, copy_number) in book_copies

---

## Generated Columns

### Computed Fields
- `fines.balance`: amount - paid_amount (auto-calculated)

---

## Cascade Rules

### ON DELETE CASCADE
- `book_copies` → `books`: Delete copies when book deleted
- `borrow_requests` → `profiles`: Delete requests when member deleted
- `borrow_records` → `profiles`: Delete records when member deleted
- `reservations` → `profiles`: Delete reservations when member deleted
- `fines` → `profiles`: Delete fines when member deleted
- `payments` → `fines`: Delete payments when fine deleted

### ON DELETE SET NULL
- `audit_logs` → `profiles`: Keep audit log even if user deleted

---

## Data Volume Estimates

For a medium-sized library (10,000 members, 50,000 books):

| Table | Estimated Rows | Growth Rate |
|-------|----------------|-------------|
| profiles | 10,000 | +500/month |
| books | 50,000 | +100/month |
| book_copies | 150,000 | +300/month |
| borrow_records | 500,000 | +5,000/month |
| borrow_requests | 600,000 | +6,000/month |
| reservations | 50,000 | +1,000/month |
| fines | 100,000 | +500/month |
| payments | 120,000 | +600/month |
| notifications | 1,000,000 | +20,000/month |
| audit_logs | 2,000,000 | +30,000/month |

**Maintenance Recommendations:**
- Archive old notifications (90+ days)
- Archive old audit logs (1+ year)
- Soft delete inactive members (2+ years)
