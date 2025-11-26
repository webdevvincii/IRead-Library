-- =====================================================
-- Library Management System - Row Level Security
-- Version: 002
-- Description: RLS policies for secure data access
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrow_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE violation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is staff
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'staff'
        AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is member
CREATE OR REPLACE FUNCTION is_member()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'member'
        AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
BEGIN
    RETURN (
        SELECT role FROM profiles
        WHERE id = auth.uid()
        AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PROFILES TABLE POLICIES
-- =====================================================

-- Staff can view all profiles
CREATE POLICY "Staff can view all profiles"
    ON profiles FOR SELECT
    TO authenticated
    USING (is_staff());

-- Members can view only their own profile
CREATE POLICY "Members can view own profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (is_member() AND id = auth.uid());

-- Staff can update all profiles
CREATE POLICY "Staff can update all profiles"
    ON profiles FOR UPDATE
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can update only their own profile (limited fields)
CREATE POLICY "Members can update own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (is_member() AND id = auth.uid())
    WITH CHECK (is_member() AND id = auth.uid());

-- Staff can insert profiles (for member registration)
CREATE POLICY "Staff can insert profiles"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (is_staff());

-- Allow profile creation during signup (handled by trigger)
CREATE POLICY "Allow profile creation on signup"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (id = auth.uid());

-- =====================================================
-- BOOKS TABLE POLICIES
-- =====================================================

-- Staff can do everything with books
CREATE POLICY "Staff full access to books"
    ON books FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can only view available books (not deleted)
CREATE POLICY "Members can view available books"
    ON books FOR SELECT
    TO authenticated
    USING (is_member() AND deleted_at IS NULL);

-- =====================================================
-- BOOK COPIES TABLE POLICIES
-- =====================================================

-- Staff can do everything with book copies
CREATE POLICY "Staff full access to book copies"
    ON book_copies FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view book copies
CREATE POLICY "Members can view book copies"
    ON book_copies FOR SELECT
    TO authenticated
    USING (is_member());

-- =====================================================
-- BORROW REQUESTS TABLE POLICIES
-- =====================================================

-- Staff can view all borrow requests
CREATE POLICY "Staff can view all borrow requests"
    ON borrow_requests FOR SELECT
    TO authenticated
    USING (is_staff());

-- Staff can update borrow requests (approve/reject)
CREATE POLICY "Staff can update borrow requests"
    ON borrow_requests FOR UPDATE
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own borrow requests
CREATE POLICY "Members can view own borrow requests"
    ON borrow_requests FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- Members can create borrow requests
CREATE POLICY "Members can create borrow requests"
    ON borrow_requests FOR INSERT
    TO authenticated
    WITH CHECK (is_member() AND member_id = auth.uid());

-- Members can cancel their pending requests
CREATE POLICY "Members can cancel own pending requests"
    ON borrow_requests FOR UPDATE
    TO authenticated
    USING (is_member() AND member_id = auth.uid() AND status = 'pending')
    WITH CHECK (is_member() AND member_id = auth.uid() AND status = 'cancelled');

-- =====================================================
-- BORROW RECORDS TABLE POLICIES
-- =====================================================

-- Staff can do everything with borrow records
CREATE POLICY "Staff full access to borrow records"
    ON borrow_records FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own borrow records
CREATE POLICY "Members can view own borrow records"
    ON borrow_records FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- =====================================================
-- RESERVATIONS TABLE POLICIES
-- =====================================================

-- Staff can view all reservations
CREATE POLICY "Staff can view all reservations"
    ON reservations FOR SELECT
    TO authenticated
    USING (is_staff());

-- Staff can update reservations
CREATE POLICY "Staff can update reservations"
    ON reservations FOR UPDATE
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own reservations
CREATE POLICY "Members can view own reservations"
    ON reservations FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- Members can create reservations
CREATE POLICY "Members can create reservations"
    ON reservations FOR INSERT
    TO authenticated
    WITH CHECK (is_member() AND member_id = auth.uid());

-- Members can cancel their own active reservations
CREATE POLICY "Members can cancel own reservations"
    ON reservations FOR UPDATE
    TO authenticated
    USING (is_member() AND member_id = auth.uid() AND status = 'active')
    WITH CHECK (is_member() AND member_id = auth.uid() AND status = 'cancelled');

-- =====================================================
-- FINES TABLE POLICIES
-- =====================================================

-- Staff can do everything with fines
CREATE POLICY "Staff full access to fines"
    ON fines FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own fines
CREATE POLICY "Members can view own fines"
    ON fines FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- =====================================================
-- PAYMENTS TABLE POLICIES
-- =====================================================

-- Staff can do everything with payments
CREATE POLICY "Staff full access to payments"
    ON payments FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own payments
CREATE POLICY "Members can view own payments"
    ON payments FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- =====================================================
-- VIOLATION HISTORY TABLE POLICIES
-- =====================================================

-- Staff can do everything with violations
CREATE POLICY "Staff full access to violations"
    ON violation_history FOR ALL
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view their own violations
CREATE POLICY "Members can view own violations"
    ON violation_history FOR SELECT
    TO authenticated
    USING (is_member() AND member_id = auth.uid());

-- =====================================================
-- NOTIFICATIONS TABLE POLICIES
-- =====================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Staff can create notifications for any user
CREATE POLICY "Staff can create notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (is_staff());

-- System can create notifications (via triggers)
CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- AUDIT LOGS TABLE POLICIES
-- =====================================================

-- Staff can view all audit logs
CREATE POLICY "Staff can view audit logs"
    ON audit_logs FOR SELECT
    TO authenticated
    USING (is_staff());

-- System can insert audit logs (via triggers)
CREATE POLICY "System can insert audit logs"
    ON audit_logs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- SYSTEM SETTINGS TABLE POLICIES
-- =====================================================

-- Staff can view system settings
CREATE POLICY "Staff can view system settings"
    ON system_settings FOR SELECT
    TO authenticated
    USING (is_staff());

-- Staff can update system settings
CREATE POLICY "Staff can update system settings"
    ON system_settings FOR UPDATE
    TO authenticated
    USING (is_staff())
    WITH CHECK (is_staff());

-- Members can view public system settings
CREATE POLICY "Members can view public system settings"
    ON system_settings FOR SELECT
    TO authenticated
    USING (is_member() AND key IN (
        'library_name',
        'library_email',
        'library_phone',
        'max_borrow_duration',
        'fine_per_day'
    ));

-- =====================================================
-- ANON/PUBLIC ACCESS POLICIES
-- =====================================================

-- No public access to any table by default
-- All access requires authentication

-- Public can access system settings for library info only
CREATE POLICY "Public can view library info"
    ON system_settings FOR SELECT
    TO anon
    USING (key IN ('library_name', 'library_email', 'library_phone'));

-- =====================================================
-- SECURITY DEFINER FUNCTIONS FOR COMPLEX OPERATIONS
-- =====================================================

-- Function to check if member can borrow (no unpaid fines, not penalized)
CREATE OR REPLACE FUNCTION can_member_borrow(p_member_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_unpaid_fines DECIMAL;
    v_is_penalized BOOLEAN;
    v_member_status member_status;
    v_penalty_until TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Get member status
    SELECT 
        member_status,
        is_penalized,
        penalty_until
    INTO v_member_status, v_is_penalized, v_penalty_until
    FROM profiles
    WHERE id = p_member_id;
    
    -- Check if member is active
    IF v_member_status != 'active' THEN
        RETURN FALSE;
    END IF;
    
    -- Check if penalty has expired
    IF v_is_penalized AND v_penalty_until IS NOT NULL AND v_penalty_until <= NOW() THEN
        -- Auto-remove penalty
        UPDATE profiles
        SET is_penalized = FALSE, penalty_until = NULL, member_status = 'active'
        WHERE id = p_member_id;
        v_is_penalized := FALSE;
    END IF;
    
    -- Check if currently penalized
    IF v_is_penalized THEN
        RETURN FALSE;
    END IF;
    
    -- Check for unpaid fines
    SELECT COALESCE(SUM(balance), 0)
    INTO v_unpaid_fines
    FROM fines
    WHERE member_id = p_member_id AND is_paid = FALSE;
    
    IF v_unpaid_fines > 0 THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current borrow count
CREATE OR REPLACE FUNCTION get_current_borrow_count(p_member_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM borrow_records
        WHERE member_id = p_member_id
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get borrow limit based on member status
CREATE OR REPLACE FUNCTION get_borrow_limit(p_member_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_is_penalized BOOLEAN;
BEGIN
    SELECT is_penalized
    INTO v_is_penalized
    FROM profiles
    WHERE id = p_member_id;
    
    IF v_is_penalized THEN
        RETURN (SELECT value::INTEGER FROM system_settings WHERE key = 'max_borrow_limit_penalized');
    ELSE
        RETURN (SELECT value::INTEGER FROM system_settings WHERE key = 'max_borrow_limit_normal');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- GRANT EXECUTE PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION is_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION is_member() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION can_member_borrow(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_current_borrow_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_borrow_limit(UUID) TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON POLICY "Staff full access to books" ON books IS 
    'Staff members have complete CRUD access to all books';

COMMENT ON POLICY "Members can view available books" ON books IS 
    'Members can only view books that are not soft-deleted';

COMMENT ON FUNCTION is_staff() IS 
    'Helper function to check if current user is staff';

COMMENT ON FUNCTION can_member_borrow(UUID) IS 
    'Checks if member is eligible to borrow (no fines, not penalized, active status)';

COMMENT ON FUNCTION get_borrow_limit(UUID) IS 
    'Returns borrow limit based on member penalty status (2 if penalized, 5 if normal)';
