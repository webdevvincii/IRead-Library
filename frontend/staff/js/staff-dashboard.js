// Staff Dashboard Module

const StaffDashboard = {
    staffProfile: null,

    // Load dashboard statistics
    loadStats: async function() {
        try {
            // Total books
            const { count: totalBooks } = await supabaseClient
                .from('books')
                .select('*', { count: 'exact', head: true })
                .is('deleted_at', null);
            
            document.getElementById('totalBooks').textContent = totalBooks || 0;

            // Active borrows
            const { count: activeBorrows } = await supabaseClient
                .from('borrow_records')
                .select('*', { count: 'exact', head: true })
                .eq('status', 'active');
            
            document.getElementById('activeBorrows').textContent = activeBorrows || 0;

            // Pending requests
            const { count: pendingRequests } = await supabaseClient
                .from('borrow_requests')
                .select('*', { count: 'exact', head: true })
                .eq('status', 'pending');
            
            document.getElementById('pendingRequests').textContent = pendingRequests || 0;

            // Overdue books
            const { count: overdueBooks } = await supabaseClient
                .from('borrow_records')
                .select('*', { count: 'exact', head: true })
                .in('status', ['overdue', 'active'])
                .lt('due_date', new Date().toISOString().split('T')[0]);
            
            document.getElementById('overdueBooks').textContent = overdueBooks || 0;

        } catch (error) {
            console.error('Error loading stats:', error);
        }
    },

    // Load recent borrow requests
    loadRecentRequests: async function() {
        StaffCommon.showLoading('recentRequests');
        
        try {
            const { data: requests, error } = await supabaseClient
                .from('borrow_requests')
                .select(`
                    *,
                    member:member_id(full_name, member_id),
                    book:book_id(title, author)
                `)
                .order('created_at', { ascending: false })
                .limit(5);

            if (error) throw error;

            const container = document.getElementById('recentRequests');
            
            if (!requests || requests.length === 0) {
                StaffCommon.showEmptyState('recentRequests', 'No recent requests');
                return;
            }

            container.innerHTML = requests.map(req => `
                <div class="flex items-center justify-between border-b border-gray-200 pb-3">
                    <div class="flex-1">
                        <p class="text-sm font-medium text-gray-900">
                            ${req.book?.title || 'Unknown Book'}
                        </p>
                        <p class="text-xs text-gray-500">
                            ${req.member?.full_name || 'Unknown Member'} (${req.member?.member_id || '-'})
                        </p>
                        <p class="text-xs text-gray-400">
                            ${StaffCommon.formatDateTime(req.created_at)}
                        </p>
                    </div>
                    <div>
                        <span class="badge ${StaffCommon.getStatusBadgeClass(req.status)}">
                            ${req.status}
                        </span>
                    </div>
                </div>
            `).join('');

        } catch (error) {
            console.error('Error loading recent requests:', error);
            StaffCommon.showEmptyState('recentRequests', 'Error loading requests');
        }
    },

    // Load overdue items
    loadOverdueItems: async function() {
        StaffCommon.showLoading('overdueItems');
        
        try {
            const { data: overdueItems, error } = await supabaseClient
                .from('borrow_records')
                .select(`
                    *,
                    member:member_id(full_name, member_id),
                    book:book_id(title, author)
                `)
                .in('status', ['overdue', 'active'])
                .lt('due_date', new Date().toISOString().split('T')[0])
                .order('due_date', { ascending: true })
                .limit(5);

            if (error) throw error;

            const container = document.getElementById('overdueItems');
            
            if (!overdueItems || overdueItems.length === 0) {
                container.innerHTML = `
                    <div class="text-center py-8 text-green-600">
                        ✓ No overdue items
                    </div>
                `;
                return;
            }

            container.innerHTML = overdueItems.map(item => {
                const daysOverdue = Math.floor((new Date() - new Date(item.due_date)) / (1000 * 60 * 60 * 24));
                return `
                    <div class="flex items-center justify-between border-b border-gray-200 pb-3">
                        <div class="flex-1">
                            <p class="text-sm font-medium text-gray-900">
                                ${item.book?.title || 'Unknown Book'}
                            </p>
                            <p class="text-xs text-gray-500">
                                ${item.member?.full_name || 'Unknown Member'} (${item.member?.member_id || '-'})
                            </p>
                            <p class="text-xs text-red-600 font-medium">
                                ${daysOverdue} ${daysOverdue === 1 ? 'day' : 'days'} overdue
                            </p>
                        </div>
                        <div>
                            <span class="badge badge-danger">
                                Due: ${StaffCommon.formatDate(item.due_date)}
                            </span>
                        </div>
                    </div>
                `;
            }).join('');

        } catch (error) {
            console.error('Error loading overdue items:', error);
            StaffCommon.showEmptyState('overdueItems', 'Error loading overdue items');
        }
    },

    // Initialize dashboard
    init: async function() {
        this.staffProfile = await StaffCommon.init();
        
        if (this.staffProfile) {
            await Promise.all([
                this.loadStats(),
                this.loadRecentRequests(),
                this.loadOverdueItems()
            ]);

            // Auto-refresh every 30 seconds
            setInterval(() => {
                this.loadStats();
                this.loadRecentRequests();
                this.loadOverdueItems();
            }, 30000);
        }
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    StaffDashboard.init();
});
