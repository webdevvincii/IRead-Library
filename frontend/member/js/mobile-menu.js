// Mobile Navigation Toggle for Member Portal
document.addEventListener('DOMContentLoaded', function() {
    const mobileNavBtn = document.getElementById('mobileNavBtn');
    const mobileNav = document.getElementById('mobileNav');
    const mobileLogoutBtn = document.getElementById('mobileLogoutBtn');
    const logoutBtn = document.getElementById('logoutBtn');
    
    // Toggle mobile menu
    if (mobileNavBtn && mobileNav) {
        mobileNavBtn.addEventListener('click', function() {
            mobileNav.classList.toggle('hidden');
        });
        
        // Close menu when clicking outside
        document.addEventListener('click', function(event) {
            if (!mobileNavBtn.contains(event.target) && !mobileNav.contains(event.target)) {
                mobileNav.classList.add('hidden');
            }
        });
    }
    
    // Sync mobile logout with desktop logout
    if (mobileLogoutBtn && logoutBtn) {
        mobileLogoutBtn.addEventListener('click', function() {
            logoutBtn.click();
        });
    }
    
    // Sync user name to mobile menu
    const userName = document.getElementById('userName');
    const mobileUserName = document.getElementById('mobileUserName');
    if (userName && mobileUserName) {
        const syncUserName = function() {
            mobileUserName.textContent = userName.textContent;
        };
        syncUserName();
        const observer = new MutationObserver(syncUserName);
        observer.observe(userName, { childList: true, characterData: true, subtree: true });
    }
});
