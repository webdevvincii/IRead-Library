-- =====================================================
-- Library Management System - Schema Migration
-- Version: 001
-- Description: Core database schema with all tables
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE user_role AS ENUM ('staff', 'member');
CREATE TYPE book_status AS ENUM ('available', 'borrowed', 'reserved', 'lost', 'under_repair');
CREATE TYPE borrow_request_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE borrow_record_status AS ENUM ('active', 'returned', 'overdue');
CREATE TYPE reservation_status AS ENUM ('active', 'fulfilled', 'cancelled', 'expired');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'cancelled');
CREATE TYPE member_status AS ENUM ('active', 'inactive', 'suspended', 'penalized');

-- =====================================================
-- PROFILES TABLE
-- =====================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    
    -- Member specific fields
    member_id VARCHAR(20) UNIQUE, -- MEM-00001 format
    member_status member_status DEFAULT 'active',
    total_violations INTEGER DEFAULT 0,
    is_penalized BOOLEAN DEFAULT FALSE,
    penalty_until TIMESTAMP WITH TIME ZONE,
    
    -- Staff specific fields
    staff_id VARCHAR(20) UNIQUE, -- STAFF-00001 format
    department VARCHAR(100),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT check_member_fields CHECK (
        (role = 'member' AND member_id IS NOT NULL) OR
        (role = 'staff' AND staff_id IS NOT NULL)
    ),
    CONSTRAINT check_penalty CHECK (
        (is_penalized = TRUE AND penalty_until IS NOT NULL) OR
        (is_penalized = FALSE)
    )
);

CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_member_id ON profiles(member_id);
CREATE INDEX idx_profiles_staff_id ON profiles(staff_id);
CREATE INDEX idx_profiles_member_status ON profiles(member_status);
CREATE INDEX idx_profiles_deleted_at ON profiles(deleted_at);

-- =====================================================
-- BOOKS TABLE
-- =====================================================

CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    shelf_no VARCHAR(50),
    description TEXT,
    cover_url TEXT,
    publisher VARCHAR(255),
    publication_year INTEGER,
    total_copies INTEGER DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INTEGER DEFAULT 1 CHECK (available_copies >= 0),
    status book_status DEFAULT 'available',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES profiles(id),
    updated_by UUID REFERENCES profiles(id),
    
    -- Constraints
    CONSTRAINT check_available_copies CHECK (available_copies <= total_copies)
);

CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_category ON books(category);
CREATE INDEX idx_books_status ON books(status);
CREATE INDEX idx_books_deleted_at ON books(deleted_at);
CREATE INDEX idx_books_search ON books USING gin(to_tsvector('english', title || ' ' || author || ' ' || COALESCE(description, '')));

-- =====================================================
-- BOOK COPIES TABLE
-- =====================================================

CREATE TABLE book_copies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    copy_number INTEGER NOT NULL,
    barcode VARCHAR(50) UNIQUE,
    status book_status DEFAULT 'available',
    condition VARCHAR(50) DEFAULT 'good', -- good, fair, poor, damaged
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(book_id, copy_number)
);

CREATE INDEX idx_book_copies_book_id ON book_copies(book_id);
CREATE INDEX idx_book_copies_status ON book_copies(status);
CREATE INDEX idx_book_copies_barcode ON book_copies(barcode);

-- =====================================================
-- BORROW REQUESTS TABLE
-- =====================================================

CREATE TABLE borrow_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_number VARCHAR(30) UNIQUE NOT NULL, -- REQ-YYYYMMDD-XXXX
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    
    -- Request details
    requested_start_date DATE NOT NULL,
    requested_duration INTEGER NOT NULL CHECK (requested_duration BETWEEN 1 AND 5),
    status borrow_request_status DEFAULT 'pending',
    
    -- Staff processing
    processed_by UUID REFERENCES profiles(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_future_date CHECK (requested_start_date >= CURRENT_DATE)
);

CREATE INDEX idx_borrow_requests_member_id ON borrow_requests(member_id);
CREATE INDEX idx_borrow_requests_book_id ON borrow_requests(book_id);
CREATE INDEX idx_borrow_requests_status ON borrow_requests(status);
CREATE INDEX idx_borrow_requests_request_number ON borrow_requests(request_number);
CREATE INDEX idx_borrow_requests_created_at ON borrow_requests(created_at DESC);

-- =====================================================
-- BORROW RECORDS TABLE
-- =====================================================

CREATE TABLE borrow_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    borrow_number VARCHAR(30) UNIQUE NOT NULL, -- BRW-YYYYMMDD-XXXX
    request_id UUID REFERENCES borrow_requests(id),
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    book_copy_id UUID REFERENCES book_copies(id),
    
    -- Borrow details
    borrow_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    status borrow_record_status DEFAULT 'active',
    
    -- Staff processing
    issued_by UUID NOT NULL REFERENCES profiles(id),
    returned_to UUID REFERENCES profiles(id),
    
    -- Fine tracking
    days_overdue INTEGER DEFAULT 0,
    fine_amount DECIMAL(10, 2) DEFAULT 0.00,
    fine_paid BOOLEAN DEFAULT FALSE,
    
    -- Notes
    issue_notes TEXT,
    return_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_dates CHECK (due_date >= borrow_date),
    CONSTRAINT check_return_date CHECK (return_date IS NULL OR return_date >= borrow_date)
);

CREATE INDEX idx_borrow_records_member_id ON borrow_records(member_id);
CREATE INDEX idx_borrow_records_book_id ON borrow_records(book_id);
CREATE INDEX idx_borrow_records_status ON borrow_records(status);
CREATE INDEX idx_borrow_records_due_date ON borrow_records(due_date);
CREATE INDEX idx_borrow_records_borrow_number ON borrow_records(borrow_number);
CREATE INDEX idx_borrow_records_overdue ON borrow_records(status, due_date) WHERE status = 'active';

-- =====================================================
-- RESERVATIONS TABLE
-- =====================================================

CREATE TABLE reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_number VARCHAR(30) UNIQUE NOT NULL, -- RES-YYYYMMDD-XXXX
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    
    -- Reservation details
    status reservation_status DEFAULT 'active',
    queue_position INTEGER NOT NULL,
    reserved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- 48 hours after book becomes available
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Unique constraint: prevent duplicate active reservations for same member+book
CREATE UNIQUE INDEX idx_reservations_unique_active ON reservations(member_id, book_id) 
    WHERE status = 'active';

CREATE INDEX idx_reservations_member_id ON reservations(member_id);
CREATE INDEX idx_reservations_book_id ON reservations(book_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_queue ON reservations(book_id, queue_position) WHERE status = 'active';
CREATE INDEX idx_reservations_expires_at ON reservations(expires_at) WHERE status = 'active';

-- =====================================================
-- FINES TABLE
-- =====================================================

CREATE TABLE fines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fine_number VARCHAR(30) UNIQUE NOT NULL, -- FINE-YYYYMMDD-XXXX
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    borrow_record_id UUID REFERENCES borrow_records(id),
    
    -- Fine details
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    reason TEXT NOT NULL,
    days_overdue INTEGER DEFAULT 0,
    
    -- Payment tracking
    paid_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (paid_amount >= 0),
    balance DECIMAL(10, 2) GENERATED ALWAYS AS (amount - paid_amount) STORED,
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMP WITH TIME ZONE,
    
    -- Staff processing
    issued_by UUID NOT NULL REFERENCES profiles(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT check_paid_amount CHECK (paid_amount <= amount)
);

CREATE INDEX idx_fines_member_id ON fines(member_id);
CREATE INDEX idx_fines_borrow_record_id ON fines(borrow_record_id);
CREATE INDEX idx_fines_is_paid ON fines(is_paid);
CREATE INDEX idx_fines_fine_number ON fines(fine_number);
CREATE INDEX idx_fines_balance ON fines(balance) WHERE balance > 0;

-- =====================================================
-- PAYMENTS TABLE
-- =====================================================

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_number VARCHAR(30) UNIQUE NOT NULL, -- PAY-YYYYMMDD-XXXX
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fine_id UUID NOT NULL REFERENCES fines(id) ON DELETE CASCADE,
    
    -- Payment details
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) DEFAULT 'cash', -- cash, gcash, card, etc.
    reference_number VARCHAR(100),
    status payment_status DEFAULT 'completed',
    
    -- Staff processing
    received_by UUID NOT NULL REFERENCES profiles(id),
    
    -- Receipt details
    receipt_url TEXT,
    notes TEXT,
    
    -- Timestamps
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_member_id ON payments(member_id);
CREATE INDEX idx_payments_fine_id ON payments(fine_id);
CREATE INDEX idx_payments_payment_number ON payments(payment_number);
CREATE INDEX idx_payments_payment_date ON payments(payment_date DESC);

-- =====================================================
-- VIOLATION HISTORY TABLE
-- =====================================================

CREATE TABLE violation_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    borrow_record_id UUID REFERENCES borrow_records(id),
    
    -- Violation details
    violation_type VARCHAR(50) NOT NULL, -- overdue, damaged_book, lost_book, etc.
    description TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'minor', -- minor, major, critical
    days_overdue INTEGER,
    
    -- Resolution
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    -- Staff tracking
    recorded_by UUID NOT NULL REFERENCES profiles(id),
    resolved_by UUID REFERENCES profiles(id),
    
    -- Timestamps
    violation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_violation_history_member_id ON violation_history(member_id);
CREATE INDEX idx_violation_history_borrow_record_id ON violation_history(borrow_record_id);
CREATE INDEX idx_violation_history_violation_date ON violation_history(violation_date DESC);
CREATE INDEX idx_violation_history_unresolved ON violation_history(is_resolved) WHERE is_resolved = FALSE;

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Notification details
    type VARCHAR(50) NOT NULL, -- due_soon, overdue, reservation_ready, fine_issued, etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Related entities
    borrow_record_id UUID REFERENCES borrow_records(id),
    reservation_id UUID REFERENCES reservations(id),
    fine_id UUID REFERENCES fines(id),
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Delivery
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email_sent BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- AUDIT LOGS TABLE
-- =====================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Actor
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    user_email VARCHAR(255),
    user_role user_role,
    
    -- Action details
    action VARCHAR(50) NOT NULL, -- create, update, delete, approve, reject, etc.
    table_name VARCHAR(50) NOT NULL,
    record_id UUID,
    
    -- Changes
    old_values JSONB,
    new_values JSONB,
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    description TEXT,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_record_id ON audit_logs(record_id);

-- =====================================================
-- SYSTEM SETTINGS TABLE
-- =====================================================

CREATE TABLE system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    data_type VARCHAR(20) DEFAULT 'string', -- string, number, boolean, json
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES profiles(id)
);

-- Insert default system settings
INSERT INTO system_settings (key, value, description, data_type) VALUES
    ('fine_per_day', '100', 'Fine amount per day overdue (PHP)', 'number'),
    ('max_borrow_limit_normal', '5', 'Maximum books a normal member can borrow', 'number'),
    ('max_borrow_limit_penalized', '2', 'Maximum books a penalized member can borrow', 'number'),
    ('max_borrow_duration', '5', 'Maximum borrow duration in days', 'number'),
    ('violation_threshold', '3', 'Number of violations before penalty', 'number'),
    ('penalty_duration_days', '30', 'Penalty duration in days', 'number'),
    ('reservation_expiry_hours', '48', 'Hours before reservation expires', 'number'),
    ('reminder_days_before_due', '1', 'Days before due date to send reminder', 'number'),
    ('library_name', 'City Public Library', 'Library name', 'string'),
    ('library_email', 'library@example.com', 'Library contact email', 'string'),
    ('library_phone', '+63-XXX-XXX-XXXX', 'Library contact phone', 'string');

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_book_copies_updated_at BEFORE UPDATE ON book_copies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_borrow_requests_updated_at BEFORE UPDATE ON borrow_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_borrow_records_updated_at BEFORE UPDATE ON borrow_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fines_updated_at BEFORE UPDATE ON fines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_violation_history_updated_at BEFORE UPDATE ON violation_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE profiles IS 'User profiles for both staff and members';
COMMENT ON TABLE books IS 'Book catalog with inventory tracking';
COMMENT ON TABLE book_copies IS 'Individual physical copies of books';
COMMENT ON TABLE borrow_requests IS 'Member borrow requests pending staff approval';
COMMENT ON TABLE borrow_records IS 'Active and historical borrow transactions';
COMMENT ON TABLE reservations IS 'Book reservations with queue management';
COMMENT ON TABLE fines IS 'Fines issued for overdue books and violations';
COMMENT ON TABLE payments IS 'Payment transactions for fines';
COMMENT ON TABLE violation_history IS 'Member violation tracking';
COMMENT ON TABLE notifications IS 'System notifications for users';
COMMENT ON TABLE audit_logs IS 'Audit trail for all system actions';
COMMENT ON TABLE system_settings IS 'System-wide configuration settings';
