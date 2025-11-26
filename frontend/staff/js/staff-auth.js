// Staff Authentication Module

const StaffAuth = {
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

    // Toggle loading state
    toggleLoading: function(isLoading) {
        const loginBtn = document.getElementById('loginBtn');
        const loginBtnText = document.getElementById('loginBtnText');
        const loginSpinner = document.getElementById('loginSpinner');
        
        loginBtn.disabled = isLoading;
        loginBtnText.textContent = isLoading ? 'Signing in...' : 'Sign In';
        loginSpinner.classList.toggle('hidden', !isLoading);
    },

    // Handle staff login
    handleLogin: async function(event) {
        event.preventDefault();

        const email = document.getElementById('email').value.trim();
        const password = document.getElementById('password').value;

        if (!email || !password) {
            this.showAlert('Please enter both email and password.');
            return;
        }

        this.toggleLoading(true);

        try {
            // Sign in with Supabase
            const { data, error } = await supabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });
            console.log('Login response:', data, error);

            if (error) {
                console.error('Login error:', error);
                throw error;
            }

            // Check if user is staff
            const { data: profile, error: profileError } = await supabaseClient
                .from('profiles')
                .select('role, full_name, staff_id')
                .eq('id', data.user.id)
                .single();
            console.log('Profile fetch:', profile, profileError);

            if (profileError) {
                console.error('Profile fetch error:', profileError);
                throw new Error('Failed to fetch user profile');
            }

            // Verify staff role
            if (profile.role !== 'staff') {
                console.warn('Role is not staff:', profile.role);
                // Sign out non-staff user
                await supabaseClient.auth.signOut();
                throw new Error('Access denied. This portal is for staff members only. Please use the member login portal.');
            }

            // Store user info
            localStorage.setItem('userRole', profile.role);
            localStorage.setItem('userName', profile.full_name);
            localStorage.setItem('staffId', profile.staff_id);

            this.showAlert('Login successful! Redirecting...', 'success');
            
            // Redirect to dashboard
            setTimeout(() => {
                window.location.href = 'dashboard.html';
            }, 1000);
            
        } catch (error) {
            console.error('Login error:', error);
            this.showAlert(error.message || 'Login failed. Please check your credentials.');
        } finally {
            this.toggleLoading(false);
        }
    },

    // Check if already logged in
    checkAuth: async function() {
        const { data: { session } } = await supabaseClient.auth.getSession();
        
        if (session) {
            // Verify staff role
            const { data: profile } = await supabaseClient
                .from('profiles')
                .select('role')
                .eq('id', session.user.id)
                .single();
            
            if (profile && profile.role === 'staff') {
                window.location.href = 'dashboard.html';
            } else {
                // Sign out if not staff
                await supabaseClient.auth.signOut();
            }
        }
    },

    // Initialize
    init: function() {
        // Check if already authenticated
        this.checkAuth();
        
        // Handle form submission
        const loginForm = document.getElementById('loginForm');
        loginForm.addEventListener('submit', (e) => this.handleLogin(e));
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    StaffAuth.init();
});
