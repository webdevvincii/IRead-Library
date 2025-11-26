// Staff Common Functions - Shared across all staff pages

const StaffCommon = {
    // Check authentication and verify staff role
    checkAuth: async function() {
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!session) {
            window.location.href = 'login.html';
            return null;
        }
        
        // Verify staff role
        const { data: profile, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', session.user.id)
            .single();
        
        if (error || !profile || profile.role !== 'staff') {
            await supabase.auth.signOut();
            window.location.href = 'login.html';
            return null;
        }
        
        return profile;
    },

    // Setup user info in navbar
    setupUserInfo: function(profile) {
        const userNameElement = document.getElementById('userName');
        if (userNameElement) {
            userNameElement.textContent = `${profile.full_name} (${profile.staff_id})`;
        }
    },

    // Setup logout functionality
    setupLogout: function() {
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', async () => {
                await supabase.auth.signOut();
                localStorage.clear();
                window.location.href = 'login.html';
            });
        }
    },

    // Format date
    formatDate: function(dateString) {
        if (!dateString) return '-';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    },

    // Format date with time
    formatDateTime: function(dateString) {
        if (!dateString) return '-';
        const date = new Date(dateString);
        return date.toLocaleString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    // Format currency
    formatCurrency: function(amount) {
        return '₱' + parseFloat(amount || 0).toFixed(2);
    },

    // Get status badge class
    getStatusBadgeClass: function(status) {
        const statusMap = {
            'active': 'badge-success',
            'pending': 'badge-warning',
            'approved': 'badge-success',
            'rejected': 'badge-danger',
            'returned': 'badge-info',
            'overdue': 'badge-danger',
            'available': 'badge-success',
            'borrowed': 'badge-warning',
            'reserved': 'badge-info',
            'lost': 'badge-danger',
            'under_repair': 'badge-secondary',
            'cancelled': 'badge-secondary',
            'completed': 'badge-success',
            'inactive': 'badge-secondary',
            'suspended': 'badge-danger',
            'penalized': 'badge-danger'
        };
        return statusMap[status] || 'badge-secondary';
    },

    // Show alert
    showAlert: function(message, type = 'success') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} fixed top-4 right-4 z-50 max-w-md`;
        alertDiv.textContent = message;
        alertDiv.style.animation = 'slideIn 0.3s ease-out';
        
        document.body.appendChild(alertDiv);
        
        setTimeout(() => {
            alertDiv.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => alertDiv.remove(), 300);
        }, 3000);
    },

    // Show loading spinner
    showLoading: function(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = `
                <div class="flex justify-center items-center py-8">
                    <div class="spinner"></div>
                </div>
            `;
        }
    },

    // Show empty state
    showEmptyState: function(elementId, message) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = `
                <div class="text-center py-8 text-gray-500">
                    ${message}
                </div>
            `;
        }
    },

    // Initialize common features
    init: async function() {
        const profile = await this.checkAuth();
        if (profile) {
            this.setupUserInfo(profile);
            this.setupLogout();
            return profile;
        }
        return null;
    }
};

// Add animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);
