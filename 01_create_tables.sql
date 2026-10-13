-- =====================================================================
-- 01_create_tables.sql
-- Normalizes the flat Superstore file into 4 related tables.
-- Staging table "stg_superstore" is loaded from the CSV first.
-- Dialect: SQLite (works in DB Browser for SQLite). See README for MySQL notes.
-- =====================================================================

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    segment       TEXT NOT NULL
);

CREATE TABLE products (
    product_id   TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    sub_category TEXT NOT NULL
);

CREATE TABLE orders (
    order_id    TEXT PRIMARY KEY,
    order_date  TEXT NOT NULL,          -- ISO format YYYY-MM-DD
    ship_date   TEXT NOT NULL,
    ship_mode   TEXT NOT NULL,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    city        TEXT,
    state       TEXT,
    region      TEXT,
    postal_code TEXT
);

CREATE TABLE order_items (
    row_id     INTEGER PRIMARY KEY,
    order_id   TEXT NOT NULL REFERENCES orders(order_id),
    product_id TEXT NOT NULL REFERENCES products(product_id),
    sales      REAL NOT NULL,
    quantity   INTEGER NOT NULL,
    discount   REAL NOT NULL,
    profit     REAL NOT NULL
);

-- Fill the tables from the staging table (dates converted from M/D/YYYY to ISO)
INSERT INTO customers
SELECT DISTINCT customer_id, customer_name, segment
FROM stg_superstore;

-- 32 product IDs carry more than one product name in the raw data;
-- MIN() keeps one name per ID.
INSERT INTO products
SELECT product_id, MIN(product_name), MIN(category), MIN(sub_category)
FROM stg_superstore
GROUP BY product_id;

INSERT INTO orders
SELECT DISTINCT
    order_id,
    printf('%04d-%02d-%02d',
           CAST(substr(order_date, length(order_date) - 3) AS INT),
           CAST(substr(order_date, 1, instr(order_date, '/') - 1) AS INT),
           CAST(substr(order_date, instr(order_date, '/') + 1,
                instr(substr(order_date, instr(order_date, '/') + 1), '/') - 1) AS INT)),
    printf('%04d-%02d-%02d',
           CAST(substr(ship_date, length(ship_date) - 3) AS INT),
           CAST(substr(ship_date, 1, instr(ship_date, '/') - 1) AS INT),
           CAST(substr(ship_date, instr(ship_date, '/') + 1,
                instr(substr(ship_date, instr(ship_date, '/') + 1), '/') - 1) AS INT)),
    ship_mode, customer_id, city, state, region, CAST(postal_code AS TEXT)
FROM stg_superstore;

INSERT INTO order_items
SELECT row_id, order_id, product_id, sales, quantity, discount, profit
FROM stg_superstore;

CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
