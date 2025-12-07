-- Remove sample data
DELETE FROM comments WHERE content IN (
    'Great first post! Looking forward to more content.',
    'Thanks for sharing this. Very informative.',
    'HTMX is indeed amazing. Great tutorial!'
);

DELETE FROM posts WHERE title IN (
    'Welcome to Our Blog',
    'Getting Started with HTMX',
    'Draft Post'
);

DELETE FROM users WHERE email IN (
    'john.doe@example.com',
    'jane.smith@example.com',
    'bob.johnson@example.com'
);