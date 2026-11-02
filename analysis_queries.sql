
CREATE DATABASE IF NOT EXISTS ecommerce_olist;
USE ecommerce_olist;

-- ============================================================
-- SECTION 1: DATABASE SCHEMA
-- Run this section once, before importing CSV data.
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10, 7),
    geolocation_lng DECIMAL(10, 7),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10, 2),
    product_length_cm DECIMAL(10, 2),
    product_height_cm DECIMAL(10, 2),
    product_width_cm DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

/*
PAUSE HERE AND IMPORT YOUR CSV FILES INTO THE TABLES ABOVE.
The remaining sections assume the tables contain the Olist dataset.
*/

-- ============================================================
-- SECTION 2: DATA QUALITY CHECKS
-- ============================================================

-- 2.1 Check row counts in the main tables.
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews;

-- 2.2 Check duplicate geolocation records.
SELECT COUNT(*) AS total_rows
FROM geolocation;

SELECT COUNT(*) AS distinct_rows
FROM (
    SELECT DISTINCT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM geolocation
) AS distinct_geolocation;

-- 2.3 Check missing or blank product categories.
SELECT COUNT(*) AS products_with_missing_category
FROM products
WHERE product_category_name IS NULL
   OR TRIM(product_category_name) = '';

-- 2.4 Check orders without a matching customer.
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2.5 Check order items without a matching product.
SELECT COUNT(*) AS orphan_product_items
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 2.6 Check order items without a matching seller.
SELECT COUNT(*) AS orphan_seller_items
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 2.7 Check order items without a matching order.
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 2.8 Check missing product dimensions before cleaning.
SELECT
    COUNT(*) AS products_with_missing_dimensions
FROM products
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;

-- ============================================================
-- SECTION 3: DATA CLEANING
-- Review the checks above before applying these changes.
-- ============================================================

-- 3.1 Standardize missing product categories.
UPDATE products
SET product_category_name = 'uncategorized'
WHERE product_category_name IS NULL
   OR TRIM(product_category_name) = '';

-- 3.2 Remove exact duplicate geolocation records without dropping the table.
CREATE TEMPORARY TABLE geolocation_deduplicated AS
SELECT DISTINCT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM geolocation;

TRUNCATE TABLE geolocation;

INSERT INTO geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM geolocation_deduplicated;

DROP TEMPORARY TABLE geolocation_deduplicated;

-- 3.3 Calculate actual medians for missing product dimensions.
-- This avoids assuming that fixed values are the medians for every dataset.
CREATE TEMPORARY TABLE product_dimension_medians AS
SELECT
    (
        SELECT AVG(product_weight_g)
        FROM (
            SELECT
                product_weight_g,
                ROW_NUMBER() OVER (ORDER BY product_weight_g) AS rn,
                COUNT(*) OVER () AS total_rows
            FROM products
            WHERE product_weight_g IS NOT NULL
        ) AS ranked_weight
        WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
    ) AS median_weight_g,
    (
        SELECT AVG(product_length_cm)
        FROM (
            SELECT
                product_length_cm,
                ROW_NUMBER() OVER (ORDER BY product_length_cm) AS rn,
                COUNT(*) OVER () AS total_rows
            FROM products
            WHERE product_length_cm IS NOT NULL
        ) AS ranked_length
        WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
    ) AS median_length_cm,
    (
        SELECT AVG(product_height_cm)
        FROM (
            SELECT
                product_height_cm,
                ROW_NUMBER() OVER (ORDER BY product_height_cm) AS rn,
                COUNT(*) OVER () AS total_rows
            FROM products
            WHERE product_height_cm IS NOT NULL
        ) AS ranked_height
        WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
    ) AS median_height_cm,
    (
        SELECT AVG(product_width_cm)
        FROM (
            SELECT
                product_width_cm,
                ROW_NUMBER() OVER (ORDER BY product_width_cm) AS rn,
                COUNT(*) OVER () AS total_rows
            FROM products
            WHERE product_width_cm IS NOT NULL
        ) AS ranked_width
        WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))
    ) AS median_width_cm;

-- Inspect the calculated medians before updating missing values.
SELECT * FROM product_dimension_medians;

-- Replace only NULL dimension values; preserve all existing non-NULL values.
UPDATE products p
CROSS JOIN product_dimension_medians m
SET
    p.product_weight_g = COALESCE(p.product_weight_g, m.median_weight_g),
    p.product_length_cm = COALESCE(p.product_length_cm, m.median_length_cm),
    p.product_height_cm = COALESCE(p.product_height_cm, m.median_height_cm),
    p.product_width_cm = COALESCE(p.product_width_cm, m.median_width_cm)
WHERE p.product_weight_g IS NULL
   OR p.product_length_cm IS NULL
   OR p.product_height_cm IS NULL
   OR p.product_width_cm IS NULL;

DROP TEMPORARY TABLE product_dimension_medians;

-- 3.4 Verify that product dimensions no longer contain NULL values.
SELECT COUNT(*) AS products_with_missing_dimensions_after_cleaning
FROM products
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;

-- 3.5 Correct misspelled product column names, if they still exist.
-- Run these ALTER statements only once. If you already renamed these columns,
-- do not run these two statements again.
-- ALTER TABLE products RENAME COLUMN product_name_lenght TO product_name_length;
-- ALTER TABLE products RENAME COLUMN product_description_lenght TO product_description_length;

-- ============================================================
-- SECTION 4: FOREIGN KEY RELATIONSHIPS
-- Run once, after orphan checks return zero for the relevant tables.
-- If these constraints already exist, skip this entire section.
-- ============================================================

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_sellers
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_payments
    ADD CONSTRAINT fk_order_payments_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
    ADD CONSTRAINT fk_order_reviews_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- ============================================================
-- SECTION 5: BUSINESS ANALYSIS QUERIES
-- ============================================================

-- QUERY 1
-- Business Question: How many orders were placed in each month?
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- QUERY 2
-- Business Question: Which product categories have the highest item sales volume?
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name) AS product_category,
    COUNT(*) AS total_items_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name)
ORDER BY total_items_sold DESC
LIMIT 10;

-- QUERY 3
-- Business Question: Which states have the highest number of unique customers?
-- customer_unique_id identifies a person across multiple customer_id records.
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_count
FROM customers
GROUP BY customer_state
ORDER BY unique_customer_count DESC;

-- QUERY 4
-- Business Question: What is the average order value across all recorded payments?
-- AOV = total payment value / number of distinct paid orders.
SELECT
    ROUND(SUM(payment_value) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM order_payments;

-- QUERY 5
-- Business Question: What is the average delivery time in days for delivered orders?
-- Uses elapsed time, including partial days.
SELECT
    ROUND(AVG(TIMESTAMPDIFF(SECOND, order_purchase_timestamp,
                            order_delivered_customer_date) / 86400), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;

-- QUERY 6
-- Business Question: What percentage of delivered orders arrived later than estimated?
SELECT
    COUNT(*) AS total_delivered_orders,
    SUM(CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
            ELSE 0
        END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE
                        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
                        ELSE 0
                    END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- QUERY 7
-- Business Question: Which sellers are associated with low average order review scores?
-- Reviews belong to orders, not individual sellers. One order review can be associated
-- with each seller present in that order. Duplicate seller/order item rows are removed.
WITH seller_orders AS (
    SELECT DISTINCT seller_id, order_id
    FROM order_items
),
seller_reviews AS (
    SELECT
        so.seller_id,
        so.order_id,
        r.review_score
    FROM seller_orders so
    JOIN order_reviews r
        ON so.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
)
SELECT
    seller_id,
    ROUND(AVG(review_score), 2) AS avg_order_review_score,
    COUNT(*) AS reviewed_orders
FROM seller_reviews
GROUP BY seller_id
HAVING COUNT(*) > 5
   AND AVG(review_score) < 3
ORDER BY avg_order_review_score ASC;

-- QUERY 8
-- Business Question: Which payment types have the highest number of payment records?
-- This counts payment records, not unique orders. An order can have multiple payment records.
SELECT
    payment_type,
    COUNT(*) AS payment_record_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY payment_record_count DESC;

-- QUERY 9
-- Business Question: Which product categories have the lowest average order review scores?
-- Each order is counted once per category, even if it contains multiple items in that category.
-- An order-level review may be associated with more than one category if the order contains several categories.
WITH category_orders AS (
    SELECT DISTINCT
        p.product_category_name,
        oi.order_id
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
),
category_reviews AS (
    SELECT
        co.product_category_name,
        r.order_id,
        r.review_score
    FROM category_orders co
    JOIN order_reviews r
        ON co.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
)
SELECT
    COALESCE(pct.product_category_name_english, cr.product_category_name) AS product_category,
    ROUND(AVG(cr.review_score), 2) AS avg_order_review_score,
    COUNT(*) AS reviewed_orders
FROM category_reviews cr
LEFT JOIN product_category_translation pct
    ON cr.product_category_name = pct.product_category_name
GROUP BY COALESCE(pct.product_category_name_english, cr.product_category_name)
HAVING COUNT(*) > 50
ORDER BY avg_order_review_score ASC
LIMIT 10;

-- QUERY 10
-- Business Question: Which 10 cities have the most unique customers?
SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_count
FROM customers
GROUP BY customer_city, customer_state
ORDER BY unique_customer_count DESC
LIMIT 10;

-- QUERY 11
-- Business Question: What is the monthly trend in total recorded customer payments?
-- This is payment value grouped by purchase month, not accounting profit.
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value
FROM orders o
JOIN order_payments op
    ON o.order_id = op.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- QUERY 12
-- Business Question: Which product categories generate the highest merchandise revenue?
-- Revenue here is item price only; freight is excluded.
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name) AS product_category,
    ROUND(SUM(oi.price), 2) AS merchandise_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name)
ORDER BY merchandise_revenue DESC
LIMIT 10;

-- QUERY 13
-- Business Question: Which categories have the highest average order review scores?
-- Each order is counted once per category to avoid item-level row multiplication.
WITH category_orders AS (
    SELECT DISTINCT
        p.product_category_name,
        oi.order_id
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
),
category_reviews AS (
    SELECT
        co.product_category_name,
        r.order_id,
        r.review_score
    FROM category_orders co
    JOIN order_reviews r
        ON co.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
)
SELECT
    COALESCE(pct.product_category_name_english, cr.product_category_name) AS product_category,
    ROUND(AVG(cr.review_score), 2) AS avg_order_review_score,
    COUNT(*) AS reviewed_orders
FROM category_reviews cr
LEFT JOIN product_category_translation pct
    ON cr.product_category_name = pct.product_category_name
GROUP BY COALESCE(pct.product_category_name_english, cr.product_category_name)
HAVING COUNT(*) > 100
ORDER BY avg_order_review_score DESC;

-- QUERY 14
-- Business Question: What is the average number of items per order?
SELECT
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_items_per_order
FROM order_items;

-- QUERY 15
-- Business Question: What percentage of customers made more than one delivered purchase?
-- Denominator: unique customers with at least one delivered order.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS customers_with_delivered_orders,
    SUM(CASE WHEN delivered_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN delivered_orders > 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_percentage
FROM customer_orders;

-- QUERY 16
-- Business Question: What are the monthly order counts and payment values?
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_payment_value
FROM orders o
JOIN order_payments op
    ON o.order_id = op.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- QUERY 17
-- Business Question: Who are the top 10 unique customers by total recorded spend?
SELECT
    c.customer_unique_id,
    ROUND(SUM(op.payment_value), 2) AS total_spend,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spend DESC
LIMIT 10;

-- QUERY 18
-- Business Question: Which 10 sellers have the highest number of distinct orders?
-- Revenue includes item price plus freight for each item sold.
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(price + freight_value), 2) AS item_and_freight_revenue
FROM order_items
GROUP BY seller_id
ORDER BY order_count DESC
LIMIT 10;

-- QUERY 19
-- Business Question: How does the average review score change by review creation month?
SELECT
    DATE_FORMAT(review_creation_date, '%Y-%m') AS review_month,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS review_record_count
FROM order_reviews
WHERE review_score IS NOT NULL
  AND review_creation_date IS NOT NULL
GROUP BY DATE_FORMAT(review_creation_date, '%Y-%m')
ORDER BY review_month;

-- QUERY 20
-- Business Question: Which five customer states have the highest late-delivery percentage?
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
            ELSE 0
        END) AS late_orders,
    ROUND(
        100.0 * SUM(CASE
                        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
                        ELSE 0
                    END) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_percentage DESC
LIMIT 5;

-- QUERY 21
-- Business Question: What is the average freight charge per order item by customer state?
-- This is an item-level average, not an average per complete order.
SELECT
    c.customer_state,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_per_item,
    COUNT(*) AS item_count
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_per_item DESC;

-- QUERY 22
-- Business Question: What was the monthly average order value in 2017?
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    ROUND(SUM(op.payment_value) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS monthly_aov
FROM orders o
JOIN order_payments op
    ON o.order_id = op.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-01-01'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- QUERY 23
-- Business Question: Which product categories have the highest average item price?
SELECT
    COALESCE(pct.product_category_name_english, p.product_category_name) AS product_category,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    COUNT(*) AS item_count
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY COALESCE(pct.product_category_name_english, p.product_category_name)
HAVING COUNT(*) > 50
ORDER BY avg_item_price DESC
LIMIT 10;

-- QUERY 24
-- Business Question: Which customers placed delivered orders in two or more different months?
WITH customer_months AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')) AS months_active,
        COUNT(DISTINCT o.order_id) AS delivered_order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    months_active,
    delivered_order_count
FROM customer_months
WHERE months_active >= 2
ORDER BY months_active DESC, delivered_order_count DESC
LIMIT 10;

-- QUERY 25
-- Business Question: Which five sellers have the highest average order review scores,
-- considering sellers with at least 20 reviewed orders?
-- Important: the review is order-level, not seller-specific.
WITH seller_orders AS (
    SELECT DISTINCT seller_id, order_id
    FROM order_items
),
seller_reviews AS (
    SELECT
        so.seller_id,
        so.order_id,
        r.review_score
    FROM seller_orders so
    JOIN order_reviews r
        ON so.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
)
SELECT
    seller_id,
    ROUND(AVG(review_score), 2) AS avg_order_review_score,
    COUNT(*) AS reviewed_orders
FROM seller_reviews
GROUP BY seller_id
HAVING COUNT(*) >= 20
ORDER BY avg_order_review_score DESC
LIMIT 5;

-- QUERY 26
-- Business Question: How many customer records have no matching order?
-- Olist's customers table has customer_id records associated with orders;
-- this should not be described as registered users without a purchase.
SELECT
    COUNT(*) AS customer_records_without_order
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- QUERY 27
-- Business Question: Rank the top 20 unique customers by total recorded spend.
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(op.payment_value) AS total_spend
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_payments op
        ON o.order_id = op.order_id
    GROUP BY c.customer_unique_id
),
ranked_customers AS (
    SELECT
        customer_unique_id,
        ROUND(total_spend, 2) AS total_spend,
        ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS customer_rank
    FROM customer_spending
)
SELECT
    customer_unique_id,
    total_spend,
    customer_rank
FROM ranked_customers
WHERE customer_rank <= 20
ORDER BY customer_rank;

-- ============================================================
-- END OF PROJECT SQL SCRIPT
-- ============================================================
