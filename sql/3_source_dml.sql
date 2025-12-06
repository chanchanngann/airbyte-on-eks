-- INSERT event
INSERT INTO cdc_source.customers (first_name, last_name, email)
VALUES
('Tracy', 'Wong', 'tracy.wong@example.com');

SELECT * FROM cdc_source.customers;

-- UPDATE event
UPDATE cdc_source.customers
SET email = 'alice.new@example.com', updated_at = NOW()
WHERE customer_id = 1;

SELECT * FROM cdc_source.customers;

-- Delete event
DELETE FROM cdc_source.customers
WHERE customer_id = 4;

SELECT * FROM cdc_source.customers;


-- INSERT event #2
INSERT INTO cdc_source.customers (first_name, last_name, email)
VALUES
('Donald', 'Chan', 'donald.chan@example.com');

SELECT * FROM cdc_source.customers;


-- UPDATE event #2
UPDATE cdc_source.customers
SET email = 'charlie.new@example.com', updated_at = NOW()
WHERE customer_id = 3;

SELECT * FROM cdc_source.customers;