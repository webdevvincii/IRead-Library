-- =====================================================
-- Create Member Profile Function
-- Purpose: Allow authenticated users to create their own profile after signup
-- =====================================================

-- Function to create member profile (bypasses RLS with SECURITY DEFINER)
CREATE OR REPLACE FUNCTION create_member_profile(
    user_id UUID,
    user_email VARCHAR,
    user_full_name VARCHAR,
    user_phone VARCHAR DEFAULT NULL,
    user_address TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    -- Check if profile already exists
    IF EXISTS (SELECT 1 FROM profiles WHERE id = user_id) THEN
        RAISE EXCEPTION 'Profile already exists for this user';
    END IF;
    
    -- Insert the profile
    INSERT INTO profiles (
        id,
        role,
        email,
        full_name,
        phone,
        address,
        member_status,
        created_at
    ) VALUES (
        user_id,
        'member',
        user_email,
        user_full_name,
        user_phone,
        user_address,
        'active',
        NOW()
    );
    
    -- Return success
    SELECT json_build_object(
        'success', true,
        'user_id', user_id,
        'message', 'Profile created successfully'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN unique_violation THEN
        -- Profile already exists, return success anyway
        SELECT json_build_object(
            'success', true,
            'user_id', user_id,
            'message', 'Profile already exists'
        ) INTO v_result;
        RETURN v_result;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating profile: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_member_profile(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT) TO authenticated;

-- Comment
COMMENT ON FUNCTION create_member_profile IS 'Creates a member profile for a newly signed up user. Uses SECURITY DEFINER to bypass RLS.';
