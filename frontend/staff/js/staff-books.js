// Books Management JavaScript

let books = [];
let categories = [];
let bookToDelete = null;

// Initialize page
document.addEventListener('DOMContentLoaded', async () => {
    // Debug: log session and profile info
    if (typeof supabase !== 'undefined') {
        const { data: { session } } = await supabase.auth.getSession();
        console.log('Session:', session);
        if (session && session.user) {
            const { data: profile, error } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', session.user.id)
                .single();
            console.log('Profile:', profile);
            if (error) console.error('Profile error:', error);
        }
    }
    const profile = await StaffCommon.checkAuth();
    if (profile) {
        StaffCommon.setupUserInfo(profile);
        StaffCommon.setupLogout();
    }
    await loadCategories();
    await loadBooks();
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    document.getElementById('searchInput').addEventListener('input', filterBooks);
    document.getElementById('categoryFilter').addEventListener('change', filterBooks);
    document.getElementById('availabilityFilter').addEventListener('change', filterBooks);
    document.getElementById('bookForm').addEventListener('submit', handleBookSubmit);
}

// Load categories
async function loadCategories() {
    try {
        const { data, error } = await supabase
            .from('books')
            .select('category')
            .order('category');

        if (error) throw error;

        // Get unique categories
        const uniqueCategories = [...new Set(data.map(book => book.category))].filter(Boolean);
        categories = uniqueCategories;

        // Populate category filters
        const categoryFilter = document.getElementById('categoryFilter');
        const categorySelect = document.getElementById('category');

        uniqueCategories.forEach(cat => {
            categoryFilter.innerHTML += `<option value="${cat}">${cat}</option>`;
            categorySelect.innerHTML += `<option value="${cat}">${cat}</option>`;
        });

        // Add option to create new category
        categorySelect.innerHTML += `<option value="_new_">+ Add New Category</option>`;

    } catch (error) {
        console.error('Error loading categories:', error);
    }
}

// Load all books
async function loadBooks() {
    try {
        const { data, error } = await supabase
            .from('books')
            .select('*')
            .is('deleted_at', null)
            .order('title');

        if (error) {
            console.error('Supabase error:', error);
            throw error;
        }

        console.log('Books loaded:', data);
        
        // Calculate available copies for each book
        const booksWithAvailability = await Promise.all((data || []).map(async (book) => {
            const { data: copies, error: copiesError } = await supabase
                .from('book_copies')
                .select('status')
                .eq('book_id', book.id);
            
            if (!copiesError && copies) {
                book.available_copies = copies.filter(c => c.status === 'available').length;
            } else {
                book.available_copies = book.total_copies || 0;
            }
            return book;
        }));
        
        books = booksWithAvailability;
        displayBooks(books);

    } catch (error) {
        console.error('Error loading books:', error);
        showNotification('Failed to load books: ' + error.message, 'error');
        document.getElementById('booksTableBody').innerHTML = `
            <tr>
                <td colspan="7" class="px-6 py-4 text-center text-red-500">
                    <i class="fas fa-exclamation-circle mr-2"></i>Error loading books: ${error.message}
                </td>
            </tr>
        `;
    }
}

// Display books in table
function displayBooks(booksToDisplay) {
    const tbody = document.getElementById('booksTableBody');

    if (booksToDisplay.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="px-6 py-4 text-center text-gray-500">
                    <i class="fas fa-book-open mr-2"></i>No books found
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = booksToDisplay.map(book => {
        const availableCopies = book.available_copies ?? (book.total_copies || 0);
        const isAvailable = availableCopies > 0;

        return `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 text-sm text-gray-900">${book.isbn || 'N/A'}</td>
                <td class="px-6 py-4">
                    <div class="text-sm font-medium text-gray-900">${book.title || 'Untitled'}</div>
                    ${book.description ? `<div class="text-xs text-gray-500 mt-1">${book.description.substring(0, 50)}...</div>` : ''}
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">${book.author || 'Unknown'}</td>
                <td class="px-6 py-4">
                    <span class="px-2 py-1 text-xs rounded-full bg-indigo-100 text-indigo-800">
                        ${book.category || 'Uncategorized'}
                    </span>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">${book.total_copies || 0}</td>
                <td class="px-6 py-4">
                    <span class="px-2 py-1 text-xs rounded-full ${isAvailable ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
                        ${availableCopies} available
                    </span>
                </td>
                <td class="px-6 py-4 text-sm">
                    <div class="flex space-x-2">
                        <button onclick="viewBook('${book.id}')" 
                                class="text-blue-600 hover:text-blue-800" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button onclick="editBook('${book.id}')" 
                                class="text-indigo-600 hover:text-indigo-800" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button onclick="openDeleteModal('${book.id}')" 
                                class="text-red-600 hover:text-red-800" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

// Filter books
function filterBooks() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const categoryFilter = document.getElementById('categoryFilter').value;
    const availabilityFilter = document.getElementById('availabilityFilter').value;

    let filtered = books.filter(book => {
        const matchesSearch = !searchTerm || 
            book.title.toLowerCase().includes(searchTerm) ||
            book.author.toLowerCase().includes(searchTerm) ||
            book.isbn.toLowerCase().includes(searchTerm);

        const matchesCategory = !categoryFilter || book.category === categoryFilter;

        const availableCopies = book.available_copies ?? book.total_copies;
        const matchesAvailability = !availabilityFilter || 
            (availabilityFilter === 'available' && availableCopies > 0) ||
            (availabilityFilter === 'unavailable' && availableCopies === 0);

        return matchesSearch && matchesCategory && matchesAvailability;
    });

    displayBooks(filtered);
}

// Open add book modal
function openAddBookModal() {
    document.getElementById('modalTitle').textContent = 'Add New Book';
    document.getElementById('bookForm').reset();
    document.getElementById('bookId').value = '';
    document.getElementById('bookModal').classList.remove('hidden');
}

// View book details
async function viewBook(bookId) {
    try {
        const { data: book, error } = await supabase
            .from('books')
            .select('*')
            .eq('id', bookId)
            .single();

        if (error) throw error;

        // Get available copies count
        const { data: copies, error: copiesError } = await supabase
            .from('book_copies')
            .select('status')
            .eq('book_id', book.id);
        
        const availableCopies = copiesError ? book.total_copies : copies.filter(c => c.status === 'available').length;
        const borrowedCopies = book.total_copies - availableCopies;

        alert(`
Book Details:
━━━━━━━━━━━━━━━━━━━━
ISBN: ${book.isbn}
Title: ${book.title}
Author: ${book.author}
Publisher: ${book.publisher || 'N/A'}
Year: ${book.publication_year || 'N/A'}
Category: ${book.category || 'N/A'}

Copies: ${book.total_copies}
Available: ${availableCopies}
Borrowed: ${borrowedCopies}

Description:
${book.description || 'No description'}
        `);

    } catch (error) {
        console.error('Error viewing book:', error);
        showNotification('Failed to load book details', 'error');
    }
}

// Edit book
async function editBook(bookId) {
    try {
        const { data: book, error } = await supabase
            .from('books')
            .select('*')
            .eq('id', bookId)
            .single();

        if (error) throw error;

        document.getElementById('modalTitle').textContent = 'Edit Book';
        document.getElementById('bookId').value = book.id;
        document.getElementById('isbn').value = book.isbn;
        document.getElementById('title').value = book.title;
        document.getElementById('author').value = book.author;
        document.getElementById('publisher').value = book.publisher || '';
        document.getElementById('publicationYear').value = book.publication_year || '';
        document.getElementById('category').value = book.category || '';
        document.getElementById('totalCopies').value = book.total_copies;
        document.getElementById('description').value = book.description || '';

        document.getElementById('bookModal').classList.remove('hidden');

    } catch (error) {
        console.error('Error loading book:', error);
        showNotification('Failed to load book details', 'error');
    }
}

// Handle book form submit
async function handleBookSubmit(e) {
    e.preventDefault();

    const bookId = document.getElementById('bookId').value;
    const isbn = document.getElementById('isbn').value.trim();
    const title = document.getElementById('title').value.trim();
    const author = document.getElementById('author').value.trim();
    const publisher = document.getElementById('publisher').value.trim();
    const publicationYear = document.getElementById('publicationYear').value;
    let category = document.getElementById('category').value;
    const totalCopies = parseInt(document.getElementById('totalCopies').value);
    const description = document.getElementById('description').value.trim();

    // Handle new category
    if (category === '_new_') {
        category = prompt('Enter new category name:');
        if (!category) return;
        category = category.trim();
    }

    const bookData = {
        isbn,
        title,
        author,
        publisher: publisher || null,
        publication_year: publicationYear ? parseInt(publicationYear) : null,
        category: category || null,
        total_copies: totalCopies,
        description: description || null,
        updated_at: new Date().toISOString()
    };

    try {
        if (bookId) {
            // Update existing book
            const { error } = await supabase
                .from('books')
                .update(bookData)
                .eq('id', bookId);

            if (error) throw error;

            // Clear cache and reload
            books = [];
            
            showNotification('Book updated successfully', 'success');
        } else {
            // Check if ISBN already exists
            const { data: existingBook } = await supabase
                .from('books')
                .select('id')
                .eq('isbn', isbn)
                .is('deleted_at', null)
                .single();

            if (existingBook) {
                showNotification('A book with this ISBN already exists!', 'error');
                return;
            }

            // Create new book
            const { data: book, error } = await supabase
                .from('books')
                .insert([bookData])
                .select()
                .single();

            if (error) {
                console.error('Book insert error:', error);
                if (error.code === '23505') {
                    showNotification('This ISBN already exists in the database', 'error');
                } else {
                    showNotification(error.message || 'Failed to add book', 'error');
                }
                return;
            }

            // Check if copies already exist (in case of partial failure)
            const { data: existingCopies } = await supabase
                .from('book_copies')
                .select('copy_number')
                .eq('book_id', book.id);

            if (!existingCopies || existingCopies.length === 0) {
                // Create book copies
                const copies = [];
                for (let i = 1; i <= totalCopies; i++) {
                    copies.push({
                        book_id: book.id,
                        copy_number: i,
                        status: 'available'
                    });
                }

                const { error: copiesError } = await supabase
                    .from('book_copies')
                    .insert(copies);

                if (copiesError) {
                    console.error('Book copies insert error:', copiesError);
                    // Don't treat this as fatal - book was already created
                    showNotification('Book created but some copies may need to be added manually', 'warning');
                    closeBookModal();
                    await loadBooks();
                    return;
                }
            }

            showNotification('Book added successfully', 'success');
        }

        closeBookModal();
        await loadBooks();
        await loadCategories();

    } catch (error) {
        console.error('Error saving book:', error);
        let errorMessage = 'Failed to save book';
        
        if (error.code === '23505') {
            errorMessage = 'This ISBN already exists in the database';
        } else if (error.message) {
            errorMessage = error.message;
        }
        
        showNotification(errorMessage, 'error');
    }
}

// Close book modal
function closeBookModal() {
    document.getElementById('bookModal').classList.add('hidden');
    document.getElementById('bookForm').reset();
}

// Open delete modal
function openDeleteModal(bookId) {
    bookToDelete = bookId;
    document.getElementById('deleteModal').classList.remove('hidden');
}

// Close delete modal
function closeDeleteModal() {
    bookToDelete = null;
    document.getElementById('deleteModal').classList.add('hidden');
}

// Confirm delete
async function confirmDelete() {
    if (!bookToDelete) return;

    try {
        // Check if book has active borrows
        const { data: activeBorrows, error: borrowError } = await supabase
            .from('borrow_records')
            .select('id')
            .eq('book_id', bookToDelete)
            .in('status', ['active', 'overdue']);

        if (borrowError) throw borrowError;

        if (activeBorrows && activeBorrows.length > 0) {
            showNotification('Cannot delete book with active borrows', 'error');
            closeDeleteModal();
            return;
        }

        // Soft delete - mark as deleted
        const { error } = await supabase
            .from('books')
            .update({ 
                deleted_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            })
            .eq('id', bookToDelete);

        if (error) throw error;

        showNotification('Book deleted successfully', 'success');
        closeDeleteModal();
        bookToDelete = null;
        books = [];
        await loadBooks();

    } catch (error) {
        console.error('Error deleting book:', error);
        showNotification(error.message || 'Failed to delete book', 'error');
    }
}

// Show notification
function showNotification(message, type = 'info') {
    const bgColor = type === 'success' ? 'bg-green-500' : 
                    type === 'error' ? 'bg-red-500' : 
                    type === 'warning' ? 'bg-yellow-500' : 'bg-blue-500';
    
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-50`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 3000);
}
