-- Insert sample users
INSERT INTO users (email, name) VALUES 
    ('john.doe@example.com', 'John Doe'),
    ('jane.smith@example.com', 'Jane Smith'),
    ('bob.johnson@example.com', 'Bob Johnson')
ON CONFLICT (email) DO NOTHING;

-- Insert sample posts
INSERT INTO posts (title, content, user_id, published) VALUES 
    ('Welcome to Our Blog', 'This is our first blog post. Welcome to our HTMX + Go application!', 1, true),
    ('Getting Started with HTMX', 'HTMX is a fantastic library for building modern web applications...', 2, true),
    ('Draft Post', 'This is a draft post that is not yet published.', 1, false);

-- Insert sample comments
INSERT INTO comments (post_id, user_id, content) VALUES 
    (1, 2, 'Great first post! Looking forward to more content.'),
    (1, 3, 'Thanks for sharing this. Very informative.'),
    (2, 1, 'HTMX is indeed amazing. Great tutorial!');