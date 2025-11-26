-- =====================================================
-- Library Management System - Seed Data
-- Version: 001
-- Description: Initial data for testing and development
-- =====================================================

-- =====================================================
-- STAFF USER (Superuser)
-- =====================================================
-- Note: This needs to be created via Supabase Auth first
-- Then the profile will be auto-created by trigger
-- For manual setup, insert after creating auth user:

-- INSERT INTO profiles (id, role, email, full_name, phone, address, department)
-- VALUES (
--     '<auth_user_id>',
--     'staff',
--     'admin@library.com',
--     'Library Administrator',
--     '+63-917-123-4567',
--     '123 Library St, City',
--     'Administration'
-- );

-- =====================================================
-- MEMBER USERS
-- =====================================================
-- Note: Create these via member signup or staff registration
-- Member IDs will be auto-generated: MEM-00001, MEM-00002, etc.

-- Sample member data structure (create via auth first):
-- Member 1: john.doe@email.com - Active
-- Member 2: jane.smith@email.com - Active
-- Member 3: bob.johnson@email.com - Active
-- Member 4: alice.williams@email.com - Active  
-- Member 5: charlie.brown@email.com - Active

-- =====================================================
-- BOOKS - Fiction Category
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-0-06-112008-4',
        'To Kill a Mockingbird',
        'Harper Lee',
        'Fiction',
        'F-A-001',
        'A gripping tale of racial injustice and childhood innocence in the American South.',
        'J. B. Lippincott & Co.',
        1960,
        3,
        3,
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
        'available'
    ),
    (
        '978-0-14-028329-3',
        '1984',
        'George Orwell',
        'Fiction',
        'F-A-002',
        'A dystopian social science fiction novel and cautionary tale about totalitarianism.',
        'Secker & Warburg',
        1949,
        4,
        4,
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400',
        'available'
    ),
    (
        '978-0-7432-7356-5',
        'The Great Gatsby',
        'F. Scott Fitzgerald',
        'Fiction',
        'F-A-003',
        'A novel about the American Dream in the Roaring Twenties.',
        'Charles Scribner''s Sons',
        1925,
        2,
        2,
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
        'available'
    ),
    (
        '978-0-316-76948-0',
        'The Catcher in the Rye',
        'J.D. Salinger',
        'Fiction',
        'F-A-004',
        'A story about teenage rebellion and alienation.',
        'Little, Brown and Company',
        1951,
        3,
        3,
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400',
        'available'
    ),
    (
        '978-0-06-093546-7',
        'One Hundred Years of Solitude',
        'Gabriel García Márquez',
        'Fiction',
        'F-B-001',
        'A landmark novel in magical realism, chronicling the Buendía family.',
        'Harper & Row',
        1967,
        2,
        2,
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400',
        'available'
    );

-- =====================================================
-- BOOKS - Science Fiction
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-0-441-17271-9',
        'Dune',
        'Frank Herbert',
        'Science Fiction',
        'SF-A-001',
        'An epic science fiction novel set in the distant future amidst a huge interstellar empire.',
        'Chilton Books',
        1965,
        3,
        3,
        'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
        'available'
    ),
    (
        '978-0-345-40957-0',
        'Foundation',
        'Isaac Asimov',
        'Science Fiction',
        'SF-A-002',
        'The first novel in the Foundation series about the collapse and rebirth of galactic civilization.',
        'Gnome Press',
        1951,
        2,
        2,
        'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
        'available'
    ),
    (
        '978-0-553-29337-0',
        'Ender''s Game',
        'Orson Scott Card',
        'Science Fiction',
        'SF-A-003',
        'A military science fiction novel about a young genius trained to fight an alien threat.',
        'Tor Books',
        1985,
        3,
        3,
        'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
        'available'
    );

-- =====================================================
-- BOOKS - Mystery & Thriller
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-0-307-58837-1',
        'The Girl with the Dragon Tattoo',
        'Stieg Larsson',
        'Mystery',
        'M-A-001',
        'A compelling thriller about murder, corruption, and dark family secrets.',
        'Norstedts Förlag',
        2005,
        4,
        4,
        'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400',
        'available'
    ),
    (
        '978-0-06-207348-5',
        'Gone Girl',
        'Gillian Flynn',
        'Mystery',
        'M-A-002',
        'A psychological thriller about a marriage gone terribly wrong.',
        'Crown Publishing Group',
        2012,
        3,
        3,
        'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400',
        'available'
    ),
    (
        '978-0-385-51190-8',
        'And Then There Were None',
        'Agatha Christie',
        'Mystery',
        'M-B-001',
        'Ten strangers are invited to an island where they are accused of murder.',
        'Collins Crime Club',
        1939,
        2,
        2,
        'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=400',
        'available'
    );

-- =====================================================
-- BOOKS - Non-Fiction & Self-Help
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-1-59184-021-0',
        'Atomic Habits',
        'James Clear',
        'Self-Help',
        'SH-A-001',
        'A practical guide to building good habits and breaking bad ones.',
        'Avery',
        2018,
        5,
        5,
        'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400',
        'available'
    ),
    (
        '978-0-7432-7357-2',
        'Sapiens: A Brief History of Humankind',
        'Yuval Noah Harari',
        'History',
        'H-A-001',
        'An exploration of how Homo sapiens came to dominate the world.',
        'Harvill Secker',
        2011,
        3,
        3,
        'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400',
        'available'
    ),
    (
        '978-0-06-112241-5',
        'The 7 Habits of Highly Effective People',
        'Stephen Covey',
        'Self-Help',
        'SH-A-002',
        'A principle-centered approach to solving personal and professional problems.',
        'Simon & Schuster',
        1989,
        4,
        4,
        'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400',
        'available'
    );

-- =====================================================
-- BOOKS - Programming & Technology
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-0-13-468599-1',
        'Clean Code',
        'Robert C. Martin',
        'Programming',
        'P-A-001',
        'A handbook of agile software craftsmanship.',
        'Prentice Hall',
        2008,
        3,
        3,
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
        'available'
    ),
    (
        '978-0-135-95705-9',
        'The Pragmatic Programmer',
        'Andrew Hunt, David Thomas',
        'Programming',
        'P-A-002',
        'Your journey to mastery in software development.',
        'Addison-Wesley',
        1999,
        2,
        2,
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
        'available'
    ),
    (
        '978-0-201-63361-0',
        'Design Patterns',
        'Gang of Four',
        'Programming',
        'P-A-003',
        'Elements of reusable object-oriented software.',
        'Addison-Wesley',
        1994,
        2,
        2,
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
        'available'
    ),
    (
        '978-0-596-51774-8',
        'JavaScript: The Good Parts',
        'Douglas Crockford',
        'Programming',
        'P-B-001',
        'Unearthing the excellence in JavaScript.',
        'O''Reilly Media',
        2008,
        3,
        3,
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400',
        'available'
    );

-- =====================================================
-- BOOKS - Fantasy
-- =====================================================

INSERT INTO books (isbn, title, author, category, shelf_no, description, publisher, publication_year, total_copies, available_copies, cover_url, status)
VALUES
    (
        '978-0-547-92821-7',
        'The Hobbit',
        'J.R.R. Tolkien',
        'Fantasy',
        'FN-A-001',
        'A fantasy novel about the adventures of hobbit Bilbo Baggins.',
        'George Allen & Unwin',
        1937,
        4,
        4,
        'https://images.unsplash.com/photo-1621351183012-e2f9972dd9bf?w=400',
        'available'
    ),
    (
        '978-0-439-70415-3',
        'Harry Potter and the Philosopher''s Stone',
        'J.K. Rowling',
        'Fantasy',
        'FN-A-002',
        'The first novel in the Harry Potter series.',
        'Bloomsbury',
        1997,
        5,
        5,
        'https://images.unsplash.com/photo-1621351183012-e2f9972dd9bf?w=400',
        'available'
    ),
    (
        '978-0-765-31178-0',
        'The Name of the Wind',
        'Patrick Rothfuss',
        'Fantasy',
        'FN-B-001',
        'The first book in The Kingkiller Chronicle series.',
        'DAW Books',
        2007,
        3,
        3,
        'https://images.unsplash.com/photo-1621351183012-e2f9972dd9bf?w=400',
        'available'
    );

-- =====================================================
-- Update created_by to first staff user (if exists)
-- =====================================================

-- This should be run after staff user is created
-- UPDATE books SET created_by = (SELECT id FROM profiles WHERE role = 'staff' LIMIT 1);

-- =====================================================
-- SAMPLE NOTIFICATIONS (Optional)
-- =====================================================

-- Welcome notifications will be created automatically by triggers
-- when users sign up or borrow books

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check total books inserted
-- SELECT category, COUNT(*) as book_count, SUM(total_copies) as total_copies
-- FROM books
-- GROUP BY category
-- ORDER BY category;

-- Expected Results:
-- Fiction: 5 books, 14 copies
-- Science Fiction: 3 books, 8 copies  
-- Mystery: 3 books, 9 copies
-- Self-Help: 2 books, 9 copies
-- History: 1 book, 3 copies
-- Programming: 4 books, 10 copies
-- Fantasy: 3 books, 12 copies
-- TOTAL: 21 books, 65 copies

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON COLUMN books.cover_url IS 
    'Using Unsplash placeholder images. Replace with actual book covers in production.';
