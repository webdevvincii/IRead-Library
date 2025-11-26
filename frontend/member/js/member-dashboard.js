// Member Dashboard Module

const MemberDashboard = {
    memberProfile: null,

    // Load dashboard statistics
    loadStats: async function() {
        try {
            // Active borrows
            const { count: activeBorrows } = await supabaseClient
                .from('borrow_records')
                .select('*', { count: 'exact', head: true })
                .eq('member_id', this.memberProfile.id)
                .eq('status', 'active');
            
            document.getElementById('activeBorrows').textContent = activeBorrows || 0;

            // Pending requests
            const { count: pendingRequests } = await supabaseClient
                .from('borrow_requests')
                .select('*', { count: 'exact', head: true })
                .eq('member_id', this.memberProfile.id)
                .eq('status', 'pending');
            
            document.getElementById('pendingRequests').textContent = pendingRequests || 0;

            // Active reservations
            const { count: activeReservations } = await supabaseClient
                .from('reservations')
                .select('*', { count: 'exact', head: true })
                .eq('member_id', this.memberProfile.id)
                .eq('status', 'active');
            
            document.getElementById('activeReservations').textContent = activeReservations || 0;

            // Unpaid fines
            const { data: fines } = await supabaseClient
                .from('fines')
                .select('balance')
                .eq('member_id', this.memberProfile.id)
                .eq('is_paid', false);
            
            const totalFines = fines?.reduce((sum, fine) => sum + parseFloat(fine.balance), 0) || 0;
            document.getElementById('unpaidFines').textContent = MemberCommon.formatCurrency(totalFines);

        } catch (error) {
            console.error('Error loading stats:', error);
        }
    },

    // Load current borrows
    loadCurrentBorrows: async function() {
        MemberCommon.showLoading('currentBorrows');
        
        try {
            const { data: borrows, error } = await supabaseClient
                .from('borrow_records')
                .select(`
                    *,
                    book:book_id(title, author, cover_url)
                `)
                .eq('member_id', this.memberProfile.id)
                .eq('status', 'active')
                .order('due_date', { ascending: true })
                .limit(5);

            if (error) throw error;

            const container = document.getElementById('currentBorrows');
            
            if (!borrows || borrows.length === 0) {
                container.innerHTML = `
                    <div class="text-center py-8">
                        <p class="text-gray-500 mb-2">No active borrows</p>
                        <a href="catalog.html" class="text-blue-600 hover:text-blue-700 text-sm">
                            Browse books to borrow →
                        </a>
                    </div>
                `;
                return;
            }

            container.innerHTML = borrows.map(borrow => {
                const daysUntilDue = MemberCommon.daysUntil(borrow.due_date);
                let dueDateClass = 'text-gray-600';
                let dueDateText = `Due: ${MemberCommon.formatDate(borrow.due_date)}`;
                
                if (daysUntilDue < 0) {
                    dueDateClass = 'text-red-600 font-semibold';
                    dueDateText = `Overdue by ${Math.abs(daysUntilDue)} days`;
                } else if (daysUntilDue === 0) {
                    dueDateClass = 'text-orange-600 font-semibold';
                    dueDateText = 'Due today!';
                } else if (daysUntilDue === 1) {
                    dueDateClass = 'text-yellow-600 font-semibold';
                    dueDateText = 'Due tomorrow';
                }
                
                return `
                    <div class="flex items-start space-x-3 border-b border-gray-200 pb-3">
                        <img 
                            src="${borrow.book?.cover_url || 'https://via.placeholder.com/60x90'}" 
                            alt="${borrow.book?.title}"
                            class="w-12 h-16 object-cover rounded"
                        >
                        <div class="flex-1">
                            <p class="text-sm font-medium text-gray-900">
                                ${borrow.book?.title || 'Unknown Book'}
                            </p>
                            <p class="text-xs text-gray-500">
                                ${borrow.book?.author || 'Unknown Author'}
                            </p>
                            <p class="text-xs ${dueDateClass} mt-1">
                                ${dueDateText}
                            </p>
                        </div>
                    </div>
                `;
            }).join('');

        } catch (error) {
            console.error('Error loading current borrows:', error);
            MemberCommon.showEmptyState('currentBorrows', 'Error loading borrows');
        }
    },

    // Load recent notifications
    loadRecentNotifications: async function() {
        MemberCommon.showLoading('recentNotifications');
        
        try {
            const { data: notifications, error } = await supabaseClient
                .from('notifications')
                .select('*')
                .eq('user_id', this.memberProfile.id)
                .order('created_at', { ascending: false })
                .limit(5);

            if (error) throw error;

            const container = document.getElementById('recentNotifications');
            
            if (!notifications || notifications.length === 0) {
                MemberCommon.showEmptyState('recentNotifications', 'No notifications');
                return;
            }

            container.innerHTML = notifications.map(notif => {
                const isUnread = !notif.is_read;
                const notifTypeIcons = {
                    'due_soon': '⏰',
                    'overdue': '⚠️',
                    'reservation_ready': '🔔',
                    'fine_issued': '💰',
                    'payment_received': '✅',
                    'borrow_approved': '✓',
                    'book_returned': '📚'
                };
                
                return `
                    <div class="border-b border-gray-200 pb-3 ${isUnread ? 'bg-blue-50 -mx-2 px-2 py-2 rounded' : ''}">
                        <div class="flex items-start">
                            <span class="text-lg mr-2">${notifTypeIcons[notif.type] || '📬'}</span>
                            <div class="flex-1">
                                <p class="text-sm font-medium text-gray-900">
                                    ${notif.title}
                                </p>
                                <p class="text-xs text-gray-600 mt-1">
                                    ${notif.message}
                                </p>
                                <p class="text-xs text-gray-400 mt-1">
                                    ${MemberCommon.formatDateTime(notif.created_at)}
                                </p>
                            </div>
                        </div>
                    </div>
                `;
            }).join('');

        } catch (error) {
            console.error('Error loading notifications:', error);
            MemberCommon.showEmptyState('recentNotifications', 'Error loading notifications');
        }
    },

    // Initialize dashboard
    init: async function() {
        this.memberProfile = await MemberCommon.init();
        
        if (this.memberProfile) {
            await Promise.all([
                this.loadStats(),
                this.loadCurrentBorrows(),
                this.loadRecentNotifications()
            ]);

            // Auto-refresh every 60 seconds
            setInterval(() => {
                this.loadStats();
                this.loadCurrentBorrows();
                this.loadRecentNotifications();
            }, 60000);
        }
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    MemberDashboard.init();
});
