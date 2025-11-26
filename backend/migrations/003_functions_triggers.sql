-- =====================================================
-- Library Management System - Functions & Triggers
-- Version: 003
-- Description: Business logic, automation, and audit
-- =====================================================

-- =====================================================
-- SEQUENCE GENERATORS
-- =====================================================

-- Generate next member ID
CREATE OR REPLACE FUNCTION generate_member_id()
RETURNS VARCHAR(20) AS $$
DECLARE
    v_next_num INTEGER;
    v_member_id VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(SUBSTRING(member_id FROM 5)::INTEGER), 0) + 1
    INTO v_next_num
    FROM profiles
    WHERE member_id IS NOT NULL;
    
    v_member_id := 'MEM-' || LPAD(v_next_num::TEXT, 5, '0');
    RETURN v_member_id;
END;
$$ LANGUAGE plpgsql;

-- Generate next staff ID
CREATE OR REPLACE FUNCTION generate_staff_id()
RETURNS VARCHAR(20) AS $$
DECLARE
    v_next_num INTEGER;
    v_staff_id VARCHAR(20);
BEGIN
    SELECT COALESCE(MAX(SUBSTRING(staff_id FROM 7)::INTEGER), 0) + 1
    INTO v_next_num
    FROM profiles
    WHERE staff_id IS NOT NULL;
    
    v_staff_id := 'STAFF-' || LPAD(v_next_num::TEXT, 5, '0');
    RETURN v_staff_id;
END;
$$ LANGUAGE plpgsql;

-- Generate request number
CREATE OR REPLACE FUNCTION generate_request_number()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_seq INTEGER;
BEGIN
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    SELECT COALESCE(COUNT(*), 0) + 1
    INTO v_seq
    FROM borrow_requests
    WHERE request_number LIKE 'REQ-' || v_date_part || '%';
    
    RETURN 'REQ-' || v_date_part || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Generate borrow number
CREATE OR REPLACE FUNCTION generate_borrow_number()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_seq INTEGER;
BEGIN
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    SELECT COALESCE(COUNT(*), 0) + 1
    INTO v_seq
    FROM borrow_records
    WHERE borrow_number LIKE 'BRW-' || v_date_part || '%';
    
    RETURN 'BRW-' || v_date_part || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Generate reservation number
CREATE OR REPLACE FUNCTION generate_reservation_number()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_seq INTEGER;
BEGIN
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    SELECT COALESCE(COUNT(*), 0) + 1
    INTO v_seq
    FROM reservations
    WHERE reservation_number LIKE 'RES-' || v_date_part || '%';
    
    RETURN 'RES-' || v_date_part || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Generate fine number
CREATE OR REPLACE FUNCTION generate_fine_number()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_seq INTEGER;
BEGIN
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    SELECT COALESCE(COUNT(*), 0) + 1
    INTO v_seq
    FROM fines
    WHERE fine_number LIKE 'FINE-' || v_date_part || '%';
    
    RETURN 'FINE-' || v_date_part || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Generate payment number
CREATE OR REPLACE FUNCTION generate_payment_number()
RETURNS VARCHAR(30) AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_seq INTEGER;
BEGIN
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    SELECT COALESCE(COUNT(*), 0) + 1
    INTO v_seq
    FROM payments
    WHERE payment_number LIKE 'PAY-' || v_date_part || '%';
    
    RETURN 'PAY-' || v_date_part || '-' || LPAD(v_seq::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PROFILE MANAGEMENT
-- =====================================================

-- Auto-generate member/staff ID on profile insert
CREATE OR REPLACE FUNCTION auto_generate_profile_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'member' AND NEW.member_id IS NULL THEN
        NEW.member_id := generate_member_id();
        NEW.member_status := 'active';
    ELSIF NEW.role = 'staff' AND NEW.staff_id IS NULL THEN
        NEW.staff_id := generate_staff_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_profile_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_profile_id();

-- =====================================================
-- BOOK MANAGEMENT
-- =====================================================

-- Update book status based on available copies
CREATE OR REPLACE FUNCTION update_book_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.available_copies = 0 THEN
        NEW.status := 'borrowed';
    ELSIF NEW.available_copies > 0 AND NEW.status = 'borrowed' THEN
        NEW.status := 'available';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_book_status
    BEFORE UPDATE OF available_copies ON books
    FOR EACH ROW
    EXECUTE FUNCTION update_book_status();

-- Auto-create book copies when book is created
CREATE OR REPLACE FUNCTION auto_create_book_copies()
RETURNS TRIGGER AS $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..NEW.total_copies LOOP
        INSERT INTO book_copies (book_id, copy_number, status)
        VALUES (NEW.id, i, 'available');
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_create_book_copies
    AFTER INSERT ON books
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_book_copies();

-- =====================================================
-- BORROW REQUEST MANAGEMENT
-- =====================================================

-- Auto-generate request number
CREATE OR REPLACE FUNCTION auto_generate_request_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.request_number IS NULL THEN
        NEW.request_number := generate_request_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_request_number
    BEFORE INSERT ON borrow_requests
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_request_number();

-- Validate borrow request before insert
CREATE OR REPLACE FUNCTION validate_borrow_request()
RETURNS TRIGGER AS $$
DECLARE
    v_can_borrow BOOLEAN;
    v_current_count INTEGER;
    v_borrow_limit INTEGER;
    v_available_copies INTEGER;
BEGIN
    -- Check if member can borrow
    v_can_borrow := can_member_borrow(NEW.member_id);
    IF NOT v_can_borrow THEN
        RAISE EXCEPTION 'Member cannot borrow: unpaid fines or penalty active';
    END IF;
    
    -- Check borrow limit
    v_current_count := get_current_borrow_count(NEW.member_id);
    v_borrow_limit := get_borrow_limit(NEW.member_id);
    
    IF v_current_count >= v_borrow_limit THEN
        RAISE EXCEPTION 'Borrow limit reached: % of % books borrowed', v_current_count, v_borrow_limit;
    END IF;
    
    -- Check book availability
    SELECT available_copies INTO v_available_copies
    FROM books WHERE id = NEW.book_id;
    
    IF v_available_copies <= 0 THEN
        RAISE EXCEPTION 'Book is not available for borrowing';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_borrow_request
    BEFORE INSERT ON borrow_requests
    FOR EACH ROW
    EXECUTE FUNCTION validate_borrow_request();

-- =====================================================
-- BORROW RECORD MANAGEMENT
-- =====================================================

-- Auto-generate borrow number
CREATE OR REPLACE FUNCTION auto_generate_borrow_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.borrow_number IS NULL THEN
        NEW.borrow_number := generate_borrow_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_borrow_number
    BEFORE INSERT ON borrow_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_borrow_number();

-- Decrease available copies when book is borrowed
CREATE OR REPLACE FUNCTION decrease_available_copies()
RETURNS TRIGGER AS $$
DECLARE
    v_copy_id UUID;
BEGIN
    -- Update book available copies
    UPDATE books
    SET available_copies = available_copies - 1
    WHERE id = NEW.book_id;
    
    -- Find and assign an available copy
    SELECT id INTO v_copy_id
    FROM book_copies
    WHERE book_id = NEW.book_id AND status = 'available'
    LIMIT 1;
    
    IF v_copy_id IS NOT NULL THEN
        UPDATE book_copies
        SET status = 'borrowed'
        WHERE id = v_copy_id;
        
        NEW.book_copy_id := v_copy_id;
    END IF;
    
    -- Create notification
    INSERT INTO notifications (user_id, type, title, message, borrow_record_id)
    VALUES (
        NEW.member_id,
        'borrow_approved',
        'Book Borrowed Successfully',
        'Your borrow request has been approved. Due date: ' || NEW.due_date::TEXT,
        NEW.id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_decrease_available_copies
    BEFORE INSERT ON borrow_records
    FOR EACH ROW
    EXECUTE FUNCTION decrease_available_copies();

-- Increase available copies when book is returned
CREATE OR REPLACE FUNCTION increase_available_copies()
RETURNS TRIGGER AS $$
DECLARE
    v_days_overdue INTEGER;
    v_fine_amount DECIMAL(10, 2);
    v_fine_per_day DECIMAL(10, 2);
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        -- Update book available copies
        UPDATE books
        SET available_copies = available_copies + 1
        WHERE id = NEW.book_id;
        
        -- Update book copy status
        IF NEW.book_copy_id IS NOT NULL THEN
            UPDATE book_copies
            SET status = 'available'
            WHERE id = NEW.book_copy_id;
        END IF;
        
        -- Calculate overdue days and fine
        v_days_overdue := GREATEST(0, (NEW.return_date - NEW.due_date)::INTEGER);
        NEW.days_overdue := v_days_overdue;
        
        IF v_days_overdue > 0 THEN
            -- Get fine per day from settings
            SELECT value::DECIMAL INTO v_fine_per_day
            FROM system_settings WHERE key = 'fine_per_day';
            
            v_fine_amount := v_days_overdue * v_fine_per_day;
            NEW.fine_amount := v_fine_amount;
            
            -- Create fine record
            INSERT INTO fines (
                fine_number, member_id, borrow_record_id,
                amount, reason, days_overdue, issued_by
            ) VALUES (
                generate_fine_number(),
                NEW.member_id,
                NEW.id,
                v_fine_amount,
                'Overdue return: ' || v_days_overdue || ' days late',
                v_days_overdue,
                NEW.returned_to
            );
            
            -- Create violation record
            INSERT INTO violation_history (
                member_id, borrow_record_id,
                violation_type, description, severity,
                days_overdue, recorded_by
            ) VALUES (
                NEW.member_id,
                NEW.id,
                'overdue',
                'Book returned ' || v_days_overdue || ' days late',
                CASE 
                    WHEN v_days_overdue > 7 THEN 'major'
                    WHEN v_days_overdue > 3 THEN 'minor'
                    ELSE 'minor'
                END,
                v_days_overdue,
                NEW.returned_to
            );
            
            -- Update member violation count
            UPDATE profiles
            SET total_violations = total_violations + 1
            WHERE id = NEW.member_id;
            
            -- Check if penalty should be applied
            PERFORM apply_penalty_if_needed(NEW.member_id);
            
            NEW.status := 'overdue';
        ELSE
            NEW.status := 'returned';
        END IF;
        
        -- Promote next reservation if any
        PERFORM promote_next_reservation(NEW.book_id);
        
        -- Create notification
        INSERT INTO notifications (user_id, type, title, message, borrow_record_id)
        VALUES (
            NEW.member_id,
            'book_returned',
            'Book Returned',
            CASE 
                WHEN v_days_overdue > 0 THEN 'Book returned with fine: ₱' || v_fine_amount::TEXT
                ELSE 'Book returned successfully. Thank you!'
            END,
            NEW.id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increase_available_copies
    BEFORE UPDATE OF return_date ON borrow_records
    FOR EACH ROW
    EXECUTE FUNCTION increase_available_copies();

-- =====================================================
-- VIOLATION & PENALTY MANAGEMENT
-- =====================================================

-- Apply penalty if violation threshold reached
CREATE OR REPLACE FUNCTION apply_penalty_if_needed(p_member_id UUID)
RETURNS VOID AS $$
DECLARE
    v_violation_count INTEGER;
    v_threshold INTEGER;
    v_penalty_days INTEGER;
    v_recent_violations INTEGER;
BEGIN
    -- Get threshold from settings
    SELECT value::INTEGER INTO v_threshold
    FROM system_settings WHERE key = 'violation_threshold';
    
    -- Get penalty duration
    SELECT value::INTEGER INTO v_penalty_days
    FROM system_settings WHERE key = 'penalty_duration_days';
    
    -- Count recent unresolved violations (last 90 days)
    SELECT COUNT(*) INTO v_recent_violations
    FROM violation_history
    WHERE member_id = p_member_id
    AND violation_date >= NOW() - INTERVAL '90 days'
    AND is_resolved = FALSE;
    
    -- Apply penalty if threshold reached
    IF v_recent_violations >= v_threshold THEN
        UPDATE profiles
        SET 
            is_penalized = TRUE,
            penalty_until = NOW() + (v_penalty_days || ' days')::INTERVAL,
            member_status = 'penalized'
        WHERE id = p_member_id;
        
        -- Create notification
        INSERT INTO notifications (user_id, type, title, message)
        VALUES (
            p_member_id,
            'penalty_applied',
            'Account Penalized',
            'Your account has been penalized due to ' || v_recent_violations || ' violations. Penalty expires: ' || 
            (NOW() + (v_penalty_days || ' days')::INTERVAL)::DATE::TEXT
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- RESERVATION MANAGEMENT
-- =====================================================

-- Auto-generate reservation number and queue position
CREATE OR REPLACE FUNCTION auto_generate_reservation()
RETURNS TRIGGER AS $$
DECLARE
    v_max_position INTEGER;
BEGIN
    IF NEW.reservation_number IS NULL THEN
        NEW.reservation_number := generate_reservation_number();
    END IF;
    
    -- Get next queue position
    SELECT COALESCE(MAX(queue_position), 0) + 1
    INTO v_max_position
    FROM reservations
    WHERE book_id = NEW.book_id AND status = 'active';
    
    NEW.queue_position := v_max_position;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_reservation
    BEFORE INSERT ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_reservation();

-- Validate reservation (no duplicate active reservations)
CREATE OR REPLACE FUNCTION validate_reservation()
RETURNS TRIGGER AS $$
DECLARE
    v_existing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existing_count
    FROM reservations
    WHERE member_id = NEW.member_id
    AND book_id = NEW.book_id
    AND status = 'active';
    
    IF v_existing_count > 0 THEN
        RAISE EXCEPTION 'You already have an active reservation for this book';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_reservation
    BEFORE INSERT ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION validate_reservation();

-- Promote next reservation in queue
CREATE OR REPLACE FUNCTION promote_next_reservation(p_book_id UUID)
RETURNS VOID AS $$
DECLARE
    v_reservation RECORD;
    v_expiry_hours INTEGER;
BEGIN
    -- Get expiry hours from settings
    SELECT value::INTEGER INTO v_expiry_hours
    FROM system_settings WHERE key = 'reservation_expiry_hours';
    
    -- Find next in queue
    SELECT * INTO v_reservation
    FROM reservations
    WHERE book_id = p_book_id
    AND status = 'active'
    ORDER BY queue_position ASC
    LIMIT 1;
    
    IF FOUND THEN
        -- Set expiry time
        UPDATE reservations
        SET expires_at = NOW() + (v_expiry_hours || ' hours')::INTERVAL
        WHERE id = v_reservation.id;
        
        -- Notify member
        INSERT INTO notifications (user_id, type, title, message, reservation_id)
        VALUES (
            v_reservation.member_id,
            'reservation_ready',
            'Your Reserved Book is Available!',
            'Your reserved book is now available. Please borrow within ' || v_expiry_hours || ' hours.',
            v_reservation.id
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PAYMENT MANAGEMENT
-- =====================================================

-- Auto-generate payment number
CREATE OR REPLACE FUNCTION auto_generate_payment_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_number IS NULL THEN
        NEW.payment_number := generate_payment_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_payment_number
    BEFORE INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_payment_number();

-- Update fine when payment is made
CREATE OR REPLACE FUNCTION update_fine_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_fine_balance DECIMAL(10, 2);
BEGIN
    -- Update fine paid amount
    UPDATE fines
    SET 
        paid_amount = paid_amount + NEW.amount,
        is_paid = (paid_amount + NEW.amount) >= amount,
        paid_at = CASE WHEN (paid_amount + NEW.amount) >= amount THEN NOW() ELSE paid_at END
    WHERE id = NEW.fine_id
    RETURNING balance INTO v_fine_balance;
    
    -- Create notification
    INSERT INTO notifications (user_id, type, title, message, fine_id)
    VALUES (
        NEW.member_id,
        'payment_received',
        'Payment Received',
        'Payment of ₱' || NEW.amount::TEXT || ' received. ' || 
        CASE WHEN v_fine_balance > 0 THEN 'Remaining balance: ₱' || v_fine_balance::TEXT ELSE 'Fine fully paid!' END,
        NEW.fine_id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fine_on_payment
    AFTER INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_fine_on_payment();

-- =====================================================
-- AUDIT LOGGING
-- =====================================================

-- Generic audit log function
CREATE OR REPLACE FUNCTION audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_user_email VARCHAR(255);
    v_user_role user_role;
BEGIN
    -- Get user info
    SELECT email, role INTO v_user_email, v_user_role
    FROM profiles WHERE id = auth.uid();
    
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (
            user_id, user_email, user_role, action,
            table_name, record_id, old_values, description
        ) VALUES (
            auth.uid(), v_user_email, v_user_role, 'delete',
            TG_TABLE_NAME, OLD.id, to_jsonb(OLD), 
            'Record deleted from ' || TG_TABLE_NAME
        );
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (
            user_id, user_email, user_role, action,
            table_name, record_id, old_values, new_values, description
        ) VALUES (
            auth.uid(), v_user_email, v_user_role, 'update',
            TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW),
            'Record updated in ' || TG_TABLE_NAME
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (
            user_id, user_email, user_role, action,
            table_name, record_id, new_values, description
        ) VALUES (
            auth.uid(), v_user_email, v_user_role, 'create',
            TG_TABLE_NAME, NEW.id, to_jsonb(NEW),
            'Record created in ' || TG_TABLE_NAME
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to key tables
CREATE TRIGGER audit_books AFTER INSERT OR UPDATE OR DELETE ON books
    FOR EACH ROW EXECUTE FUNCTION audit_log();

CREATE TRIGGER audit_borrow_requests AFTER INSERT OR UPDATE ON borrow_requests
    FOR EACH ROW EXECUTE FUNCTION audit_log();

CREATE TRIGGER audit_borrow_records AFTER INSERT OR UPDATE ON borrow_records
    FOR EACH ROW EXECUTE FUNCTION audit_log();

CREATE TRIGGER audit_fines AFTER INSERT OR UPDATE ON fines
    FOR EACH ROW EXECUTE FUNCTION audit_log();

CREATE TRIGGER audit_payments AFTER INSERT ON payments
    FOR EACH ROW EXECUTE FUNCTION audit_log();

-- =====================================================
-- SCHEDULED JOBS / UTILITY FUNCTIONS
-- =====================================================

-- Check and update overdue borrow records
CREATE OR REPLACE FUNCTION check_overdue_records()
RETURNS VOID AS $$
BEGIN
    UPDATE borrow_records
    SET status = 'overdue'
    WHERE status = 'active'
    AND due_date < CURRENT_DATE
    AND return_date IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Send due date reminders
CREATE OR REPLACE FUNCTION send_due_date_reminders()
RETURNS TABLE(member_id UUID, borrow_id UUID, book_title VARCHAR, due_date DATE) AS $$
DECLARE
    v_reminder_days INTEGER;
BEGIN
    SELECT value::INTEGER INTO v_reminder_days
    FROM system_settings WHERE key = 'reminder_days_before_due';
    
    RETURN QUERY
    INSERT INTO notifications (user_id, type, title, message, borrow_record_id)
    SELECT 
        br.member_id,
        'due_soon',
        'Book Due Tomorrow',
        'Your book "' || b.title || '" is due on ' || br.due_date::TEXT,
        br.id
    FROM borrow_records br
    JOIN books b ON b.id = br.book_id
    WHERE br.status = 'active'
    AND br.due_date = CURRENT_DATE + v_reminder_days
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.borrow_record_id = br.id
        AND n.type = 'due_soon'
        AND n.created_at::DATE = CURRENT_DATE
    )
    RETURNING user_id, borrow_record_id, NULL::VARCHAR, NULL::DATE;
END;
$$ LANGUAGE plpgsql;

-- Send overdue notifications
CREATE OR REPLACE FUNCTION send_overdue_notifications()
RETURNS VOID AS $$
BEGIN
    INSERT INTO notifications (user_id, type, title, message, borrow_record_id)
    SELECT 
        br.member_id,
        'overdue',
        'Overdue Book Alert',
        'Your book "' || b.title || '" is overdue. Due date was ' || br.due_date::TEXT || 
        '. Fine: ₱' || ((CURRENT_DATE - br.due_date) * (SELECT value::DECIMAL FROM system_settings WHERE key = 'fine_per_day'))::TEXT,
        br.id
    FROM borrow_records br
    JOIN books b ON b.id = br.book_id
    WHERE br.status = 'overdue'
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.borrow_record_id = br.id
        AND n.type = 'overdue'
        AND n.created_at::DATE = CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql;

-- Expire old reservations
CREATE OR REPLACE FUNCTION expire_old_reservations()
RETURNS VOID AS $$
BEGIN
    -- Cancel expired reservations
    UPDATE reservations
    SET 
        status = 'expired',
        cancellation_reason = 'Reservation expired after ' || 
            (SELECT value FROM system_settings WHERE key = 'reservation_expiry_hours') || ' hours'
    WHERE status = 'active'
    AND expires_at IS NOT NULL
    AND expires_at < NOW();
    
    -- Reorder queue positions
    UPDATE reservations r1
    SET queue_position = (
        SELECT COUNT(*) 
        FROM reservations r2
        WHERE r2.book_id = r1.book_id
        AND r2.status = 'active'
        AND r2.created_at < r1.created_at
    ) + 1
    WHERE status = 'active';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- REPORTS & ANALYTICS FUNCTIONS
-- =====================================================

-- Get overdue books report
CREATE OR REPLACE FUNCTION get_overdue_books_report()
RETURNS TABLE(
    borrow_number VARCHAR,
    member_name VARCHAR,
    member_id VARCHAR,
    book_title VARCHAR,
    due_date DATE,
    days_overdue INTEGER,
    estimated_fine DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.borrow_number,
        p.full_name,
        p.member_id,
        b.title,
        br.due_date,
        (CURRENT_DATE - br.due_date)::INTEGER,
        ((CURRENT_DATE - br.due_date)::INTEGER * 
            (SELECT value::DECIMAL FROM system_settings WHERE key = 'fine_per_day'))
    FROM borrow_records br
    JOIN profiles p ON p.id = br.member_id
    JOIN books b ON b.id = br.book_id
    WHERE br.status IN ('active', 'overdue')
    AND br.due_date < CURRENT_DATE
    ORDER BY br.due_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get most borrowed books
CREATE OR REPLACE FUNCTION get_most_borrowed_books(p_limit INTEGER DEFAULT 10)
RETURNS TABLE(
    book_id UUID,
    title VARCHAR,
    author VARCHAR,
    borrow_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.title,
        b.author,
        COUNT(br.id) as borrow_count
    FROM books b
    LEFT JOIN borrow_records br ON br.book_id = b.id
    WHERE b.deleted_at IS NULL
    GROUP BY b.id, b.title, b.author
    ORDER BY borrow_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get member statistics
CREATE OR REPLACE FUNCTION get_member_statistics()
RETURNS TABLE(
    total_members BIGINT,
    active_members BIGINT,
    penalized_members BIGINT,
    inactive_members BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) FILTER (WHERE role = 'member' AND deleted_at IS NULL),
        COUNT(*) FILTER (WHERE role = 'member' AND member_status = 'active' AND deleted_at IS NULL),
        COUNT(*) FILTER (WHERE role = 'member' AND is_penalized = TRUE AND deleted_at IS NULL),
        COUNT(*) FILTER (WHERE role = 'member' AND member_status = 'inactive' AND deleted_at IS NULL)
    FROM profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION generate_member_id() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_staff_id() TO authenticated;
GRANT EXECUTE ON FUNCTION apply_penalty_if_needed(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION promote_next_reservation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_overdue_records() TO authenticated;
GRANT EXECUTE ON FUNCTION send_due_date_reminders() TO authenticated;
GRANT EXECUTE ON FUNCTION send_overdue_notifications() TO authenticated;
GRANT EXECUTE ON FUNCTION expire_old_reservations() TO authenticated;
GRANT EXECUTE ON FUNCTION get_overdue_books_report() TO authenticated;
GRANT EXECUTE ON FUNCTION get_most_borrowed_books(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_statistics() TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION apply_penalty_if_needed(UUID) IS 
    'Checks violation count and applies 30-day penalty if threshold (3) is reached';

COMMENT ON FUNCTION promote_next_reservation(UUID) IS 
    'Promotes next member in reservation queue when book becomes available';

COMMENT ON FUNCTION send_due_date_reminders() IS 
    'Sends notifications to members whose books are due tomorrow';

COMMENT ON FUNCTION get_overdue_books_report() IS 
    'Returns list of overdue books with member details and calculated fines';
