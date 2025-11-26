// Member Authentication Module

const MemberAuth = {
    // Show alert message
    showAlert: function(message, type = 'error') {
        const alertContainer = document.getElementById('alertContainer');
        const alertClass = type === 'error' ? 'alert-error' : 'alert-success';
        
        alertContainer.innerHTML = `
            <div class="alert ${alertClass}">
                ${message}
            </div>
        `;
        
        setTimeout(() => {
            alertContainer.innerHTML = '';
        }, 5000);
    },

    // Toggle loading state for signup
    toggleSignupLoading: function(isLoading) {
        const signupBtn = document.getElementById('signupBtn');
        const signupBtnText = document.getElementById('signupBtnText');
        const signupSpinner = document.getElementById('signupSpinner');
        
        if (signupBtn && signupBtnText && signupSpinner) {
            signupBtn.disabled = isLoading;
            signupBtnText.textContent = isLoading ? 'Creating account...' : 'Create Account';
            signupSpinner.classList.toggle('hidden', !isLoading);
        }
    },

    // Toggle loading state for login
    toggleLoginLoading: function(isLoading) {
        const loginBtn = document.getElementById('loginBtn');
        const loginBtnText = document.getElementById('loginBtnText');
        const loginSpinner = document.getElementById('loginSpinner');
        
        if (loginBtn && loginBtnText && loginSpinner) {
            loginBtn.disabled = isLoading;
            loginBtnText.textContent = isLoading ? 'Signing in...' : 'Sign In';
            loginSpinner.classList.toggle('hidden', !isLoading);
        }
    },

    // Handle member signup
    handleSignup: async function(event) {
        event.preventDefault();
        
        const fullName = document.getElementById('fullName').value.trim();
        const email = document.getElementById('email').value.trim();
        const phone = document.getElementById('phone').value.trim();
        const address = document.getElementById('address').value.trim();
        const password = document.getElementById('password').value;
        const confirmPassword = document.getElementById('confirmPassword').value;
        const terms = document.getElementById('terms').checked;
        
        // Validation
        if (!fullName || !email || !password || !confirmPassword) {
            this.showAlert('Please fill in all required fields.');
            return;
        }
        
        if (password !== confirmPassword) {
            this.showAlert('Passwords do not match.');
            return;
        }
        
        if (password.length < 6) {
            this.showAlert('Password must be at least 6 characters long.');
            return;
        }
        
        if (!terms) {
            this.showAlert('You must agree to the terms and conditions.');
            return;
        }
        
        this.toggleSignupLoading(true);
        
        try {
            // Sign up with Supabase Auth
            const { data: authData, error: authError } = await supabaseClient.auth.signUp({
                email: email,
                password: password,
                options: {
                    data: {
                        role: 'member',
                        full_name: fullName
                    }
                }
            });
            
            if (authError) throw authError;
            
            console.log('Auth signup successful:', authData);
            
            if (!authData.user) {
                throw new Error('Failed to create user account');
            }
            
            // Wait a moment for auth to complete
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Call the database function to create profile with proper permissions
            const { data: rpcData, error: rpcError } = await supabaseClient
                .rpc('create_member_profile', {
                    user_id: authData.user.id,
                    user_email: email,
                    user_full_name: fullName,
                    user_phone: phone || null,
                    user_address: address || null
                });
            
            if (rpcError) {
                console.error('Profile creation error:', rpcError);
                // If RPC doesn't exist, try direct insert as fallback
                if (rpcError.code === '42883') {
                    console.log('RPC function not found, attempting direct insert...');
                    const { data: profileData, error: profileError } = await supabaseClient
                        .from('profiles')
                        .upsert({
                            id: authData.user.id,
                            role: 'member',
                            email: email,
                            full_name: fullName,
                            phone: phone || null,
                            address: address || null,
                            member_status: 'active'
                        }, {
                            onConflict: 'id'
                        })
                        .select();
                    
                    if (profileError) {
                        console.error('Direct insert error:', profileError);
                        throw new Error('Account created but profile setup failed. Please contact support with your email: ' + email);
                    }
                    console.log('Profile created via direct insert:', profileData);
                } else {
                    throw new Error('Failed to create profile: ' + rpcError.message);
                }
            } else {
                console.log('Profile created successfully via RPC');
            }
            
            // Sign out after signup (Supabase auto-signs in on signup)
            await supabaseClient.auth.signOut();
            
            this.showAlert('Account created successfully! Redirecting to login...', 'success');
            
            // Redirect to login after 2 seconds
            setTimeout(() => {
                window.location.href = 'login.html';
            }, 2000);
            
        } catch (error) {
            console.error('Signup error:', error);
            this.showAlert(error.message || 'Signup failed. Please try again.');
        } finally {
            this.toggleSignupLoading(false);
        }
    },

    // Handle member login
    handleLogin: async function(event) {
        event.preventDefault();
        
        const email = document.getElementById('email').value.trim();
        const password = document.getElementById('password').value;
        
        if (!email || !password) {
            this.showAlert('Please enter both email and password.');
            return;
        }
        
        this.toggleLoginLoading(true);
        
        try {
            // Sign in with Supabase
            const { data, error } = await supabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });
            
            if (error) throw error;
            
            // Check if user is member
            const { data: profiles, error: profileError } = await supabaseClient
                .from('profiles')
                .select('role, full_name, member_id, member_status, is_penalized')
                .eq('id', data.user.id);
            
            console.log('Profile fetch result:', { profiles, profileError, userId: data.user.id });
            
            if (profileError) {
                console.error('Profile error details:', profileError);
                throw new Error('Failed to fetch user profile: ' + profileError.message);
            }
            
            if (!profiles || profiles.length === 0) {
                throw new Error('User profile not found. Please sign up first or contact support.');
            }
            
            if (profiles.length > 1) {
                console.warn('Multiple profiles found for user, using first one');
            }
            
            const profile = profiles[0];
            
            // Verify member role
            if (profile.role !== 'member') {
                await supabaseClient.auth.signOut();
                throw new Error('Access denied. This portal is for members only. Please use the staff login portal.');
            }
            
            // Check member status
            if (profile.member_status === 'inactive') {
                await supabaseClient.auth.signOut();
                throw new Error('Your account is inactive. Please contact the library staff.');
            }
            
            if (profile.member_status === 'suspended') {
                await supabaseClient.auth.signOut();
                throw new Error('Your account has been suspended. Please contact the library staff.');
            }
            
            // Store user info
            localStorage.setItem('userRole', profile.role);
            localStorage.setItem('userName', profile.full_name);
            localStorage.setItem('memberId', profile.member_id);
            
            this.showAlert('Login successful! Redirecting...', 'success');
            
            // Redirect to dashboard
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 1000);
            
        } catch (error) {
            console.error('Login error:', error);
            this.showAlert(error.message || 'Login failed. Please check your credentials.');
        } finally {
            this.toggleLoginLoading(false);
        }
    },

    // Check if already logged in
    checkAuth: async function() {
        const { data: { session } } = await supabaseClient.auth.getSession();
        
        if (session) {
            // Verify member role
            const { data: profile } = await supabaseClient
                .from('profiles')
                .select('role')
                .eq('id', session.user.id)
                .single();
            
            if (profile && profile.role === 'member') {
                window.location.href = 'dashboard.html';
            } else {
                await supabaseClient.auth.signOut();
            }
        }
    },

    // Initialize signup page
    initSignup: function() {
        this.checkAuth();
        
        const signupForm = document.getElementById('signupForm');
        if (signupForm) {
            signupForm.addEventListener('submit', (e) => this.handleSignup(e));
        }
    },

    // Initialize login page
    initLogin: function() {
        this.checkAuth();
        
        const loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => this.handleLogin(e));
        }
    }
};

// Initialize based on page
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('signupForm')) {
        MemberAuth.initSignup();
    } else if (document.getElementById('loginForm')) {
        MemberAuth.initLogin();
    }
});
