CREATE SCHEMA IF NOT EXISTS cdc_source;

CREATE TABLE cdc_source.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);


INSERT INTO cdc_source.customers (first_name, last_name, email)
VALUES
('Alice', 'Kim', 'alice.kim@example.com'),
('Bob', 'Lee', 'bob.lee@example.com'),
('Charlie', 'Park', 'charlie.park@example.com');

SELECT * FROM cdc_source.customers;