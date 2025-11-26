// Member Common Functions - Shared across all member pages

const MemberCommon = {
    // Check authentication and verify member role
    checkAuth: async function() {
        const { data: { session } } = await supabaseClient.auth.getSession();
        
        if (!session) {
            window.location.href = 'login.html';
            return null;
        }
        
        // Verify member role
        const { data: profile, error } = await supabaseClient
            .from('profiles')
            .select('*')
            .eq('id', session.user.id)
            .single();
        
        if (error || !profile || profile.role !== 'member') {
            await supabaseClient.auth.signOut();
            window.location.href = 'login.html';
            return null;
        }
        
        return profile;
    },

    // Setup user info in navbar
    setupUserInfo: function(profile) {
        const userNameElement = document.getElementById('userName');
        const memberNameElement = document.getElementById('memberName');
        const memberIdElement = document.getElementById('memberId');
        
        if (userNameElement) {
            userNameElement.textContent = profile.full_name;
        }
        if (memberNameElement) {
            memberNameElement.textContent = profile.full_name;
        }
        if (memberIdElement) {
            memberIdElement.textContent = profile.member_id;
        }
    },

    // Setup account status banner
    setupAccountStatus: function(profile) {
        const accountStatusDiv = document.getElementById('accountStatus');
        if (!accountStatusDiv) return;
        
        let statusHTML = '';
        
        if (profile.is_penalized) {
            const penaltyDate = new Date(profile.penalty_until);
            statusHTML = `
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                    <strong>⚠️ Account Penalized</strong>
                    <p class="text-sm">Borrow limit reduced to 2 books until ${this.formatDate(profile.penalty_until)}</p>
                </div>
            `;
        } else if (profile.member_status !== 'active') {
            statusHTML = `
                <div class="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded">
                    <strong>ℹ️ Account Status: ${profile.member_status}</strong>
                    <p class="text-sm">Please contact library staff for assistance.</p>
                </div>
            `;
        }
        
        accountStatusDiv.innerHTML = statusHTML;
    },

    // Setup logout functionality
    setupLogout: function() {
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', async () => {
                await supabaseClient.auth.signOut();
                localStorage.clear();
                window.location.href = 'login.html';
            });
        }
    },

    // Setup notifications
    setupNotifications: async function(userId) {
        // Get unread count
        const { count, error } = await supabaseClient
            .from('notifications')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', userId)
            .eq('is_read', false);
        
        const badge = document.getElementById('notificationBadge');
        if (badge) {
            if (count > 0) {
                badge.textContent = count > 9 ? '9+' : count;
                badge.classList.remove('hidden');
            } else {
                badge.classList.add('hidden');
            }
        }
        
        // Setup notification button click
        const notificationBtn = document.getElementById('notificationBtn');
        if (notificationBtn) {
            notificationBtn.addEventListener('click', () => {
                window.location.href = 'notifications.html';
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
            'cancelled': 'badge-secondary',
            'fulfilled': 'badge-success',
            'expired': 'badge-secondary'
        };
        return statusMap[status] || 'badge-secondary';
    },

    // Calculate days until date
    daysUntil: function(dateString) {
        const targetDate = new Date(dateString);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        targetDate.setHours(0, 0, 0, 0);
        
        const diffTime = targetDate - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    },

    // Calculate days overdue
    daysOverdue: function(dateString) {
        const dueDate = new Date(dateString);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        dueDate.setHours(0, 0, 0, 0);
        
        const diffTime = today - dueDate;
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        return Math.max(0, diffDays);
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

    // Check if member can borrow
    canBorrow: async function(memberId) {
        try {
            const { data, error } = await supabaseClient
                .rpc('can_member_borrow', { p_member_id: memberId });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error checking borrow eligibility:', error);
            return false;
        }
    },

    // Get borrow limit
    getBorrowLimit: async function(memberId) {
        try {
            const { data, error } = await supabaseClient
                .rpc('get_borrow_limit', { p_member_id: memberId });
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error getting borrow limit:', error);
            return 5; // Default
        }
    },

    // Initialize common features
    init: async function() {
        const profile = await this.checkAuth();
        if (profile) {
            this.setupUserInfo(profile);
            this.setupAccountStatus(profile);
            this.setupLogout();
            this.setupNotifications(profile.id);
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
