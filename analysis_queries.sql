create database ecommerce_olist;

USE ecommerce_olist;

-- ============================================
-- 1. CUSTOMERS
-- ============================================
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- ============================================
-- 2. GEOLOCATION
-- ============================================
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10, 7),
    geolocation_lng DECIMAL(10, 7),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

-- ============================================
-- 3. SELLERS
-- ============================================
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- ============================================
-- 4. PRODUCTS
-- ============================================
CREATE TABLE products (
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

-- ============================================
-- 5. PRODUCT CATEGORY TRANSLATION
-- ============================================
CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- ============================================
-- 6. ORDERS
-- ============================================
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- ============================================
-- 7. ORDER ITEMS
-- ============================================
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- ============================================
-- 8. ORDER PAYMENTS
-- ============================================
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential)
);
DROP TABLE IF EXISTS order_reviews;
-- ============================================
-- 9. ORDER REVIEWS
-- ============================================
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

SELECT COUNT(*) AS total_rows FROM geolocation;

-- Count distinct rows
SELECT COUNT(*) AS distinct_rows FROM (
    SELECT DISTINCT geolocation_zip_code_prefix, geolocation_lat, 
                    geolocation_lng, geolocation_city, geolocation_state
    FROM geolocation
) t;

-- How many products have missing category?
SELECT COUNT(*) AS missing_category 
FROM products 
WHERE product_category_name IS NULL 
   OR product_category_name = '';
   
   -- Orders with no matching customer?
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items with no matching product?
SELECT COUNT(*) AS orphan_items
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items with no matching seller?
SELECT COUNT(*) AS orphan_sellers
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

select * from products;

set sql_safe_updates = 0;

-- Products table null values cleared--
update products
set product_category_name = 'uncategorized'
where product_category_name is null or product_category_name = ' ';

-- new table with only distinct rows--
CREATE TABLE geolocation_clean AS
SELECT DISTINCT * FROM geolocation;

--  Verify the count--
SELECT COUNT(*) FROM geolocation_clean;

-- Drop old table--
DROP TABLE geolocation;

-- Rename new table to original name
RENAME TABLE geolocation_clean TO geolocation;

-- Verify--
SELECT COUNT(*) FROM geolocation;


select * from products 
where product_weight_g is null 
or product_length_cm is null
or product_height_cm is null
or product_width_cm is null;

-- for products null values we can replace it by median--

with ranked as (
select product_weight_g,
row_number() over(order by product_weight_g) as rn,
count(*) over() as total
from products
where product_weight_g is not null
)
select avg(product_weight_g) as median_weight
from ranked 
where rn in (floor((total+1)/2), ceil((total+1)/2));

with ranked as (
select product_length_cm,
row_number() over(order by product_length_cm) as rn,
count(*) over() as total
from products
where product_length_cm is not null
)
select avg(product_length_cm) as median_length
from ranked 
where rn in (floor((total+1)/2),ceil((total+1)/2));

with ranked as (
select product_height_cm,
row_number() over(order by product_height_cm) as rn,
count(*) over() as total
from products
where product_height_cm is not null
)
select avg(product_height_cm) as median_length
from ranked 
where rn in (floor((total+1)/2),ceil((total+1)/2));

with ranked as (
select product_width_cm,
row_number() over(order by product_width_cm) as rn,
count(*) over() as total
from products
where product_width_cm is not null
)
select avg(product_width_cm) as median_length
from ranked 
where rn in (floor((total+1)/2),ceil((total+1)/2));

-- the median values is inserted inplace of null values--
update products
set product_weight_g = 700,
product_length_cm = 25, 
product_height_cm =13,
product_width_cm = 20
where product_weight_g is null;

-- in products table the column name has spellig mistake length ---
alter table products 
rename column product_name_lenght to product_name_length;
alter table products 
rename column product_description_lenght to product_description_length;
select * from products;

-- adding foreign key to enforce relationships -- 
alter table orders 
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
alter table order_items
add constraint fk_order_items_orders
foreign key (order_id)references orders(order_id);
alter table order_items
add constraint fk_order_items_product
foreign key (product_id)references products(product_id);
alter table order_items
add constraint fk_order_items_sellers
foreign key (seller_id)references sellers(seller_id);
alter table order_payments
add constraint fk_order_payments_orders
foreign key (order_id)references orders(order_id);
alter table order_reviews
add constraint fk_order_reviews_orders
foreign key (order_id)references orders(order_id);

-- ============================================
-- Query 1: Monthly Order Trend
-- Business Question: How many orders were placed each month?
-- ============================================
select date_format(order_purchase_timestamp, '%Y-%m') as month,
count(*) as order_count
from orders
where order_status = 'delivered'
group by date_format(order_purchase_timestamp, "%Y-%m") 
order by month;

-- Which product categories have the highest order volume (most items sold)?--

with prd as (
select p.product_category_name, count(*) as total_items_sold
from products p
join order_items ot 
on p.product_id = ot.product_id
group by p.product_category_name)
select pct.product_category_name_english,p.total_items_sold
from product_category_translation pct 
join prd p
on pct.product_category_name = p.product_category_name
order by p.total_items_sold desc 
limit 10; 

-- Which states have the highest customer concentration? --

select  customer_state,count(*) as customer_count
from customers
group by customer_state
order by customer_count desc;

-- What is the average order value (AOV) across all orders? --

select sum(payment_value)/count(distinct order_id) as average_order_value
from order_payments;

-- What is the average delivery time in days (from purchase to customer delivery)? --

select avg(datediff(order_delivered_customer_date, order_purchase_timestamp)) as avg_delivery_days
from orders
where order_status= 'delivered';

-- What is the late delivery percentage? --

select count(*) as total_delivered,
sum(case when  order_delivered_customer_date > order_estimated_delivery_date then 1 else 0 end) as late_orders,
round((sum(case when  order_delivered_customer_date > order_estimated_delivery_date then 1 else 0 end) *100.0/count(*)),2) as late_pct
from orders
where order_status = 'delivered';

-- Which sellers have poor customer ratings (average review score below 3)? --
select avg(o.review_score) as avg_review_score, ot.seller_id , count(o.review_score) as total_reviews
from order_reviews o 
join order_items ot 
on o.order_id = ot.order_id
group by ot.seller_id
having count(o.review_score) > 5 and avg(o.review_score) < 3
order by avg_review_score asc;

-- Which payment methods are most frequently used? --

select payment_type,count(*) as usage_count
from order_payments
group by payment_type
order by usage_count desc;

-- Which product categories have the worst average review scores? --

select avg(o.review_score) as avg_review_score, count(o.review_score) as total_reviews, pct.product_category_name_english
from order_reviews o
join order_items ot on o.order_id = ot.order_id
join products p on ot.product_id=p.product_id
join product_category_translation pct on p.product_category_name= pct.product_category_name
group by pct.product_category_name_english
having count(o.review_score) > 50
order by avg_review_score asc
limit 10 ;

-- Which cities have the most customers? --

select customer_city, count(*) as customer_count 
from customers
group by customer_city
order by count(*) desc
limit 10;

-- What is the monthly revenue trend? (Sum of payments per month) --

select date_format(o.order_purchase_timestamp, '%Y-%m') as month, sum(op.payment_value) as total_revenue
from orders o
join order_payments op
on o.order_id = op.order_id
group by date_format(o.order_purchase_timestamp, '%Y-%m') 
order by month asc;

-- Which product categories generate the most revenue? --

select pct.product_category_name_english, sum(oi.price) as total_revenue
from order_items oi
join products p on oi.product_id = p.product_id
join product_category_translation pct on pct.product_category_name = p.product_category_name
group by  pct.product_category_name_english 
order by total_revenue desc
limit 10;

-- What is the average review score per product category (English names), sorted from best to worst? --

select pct.product_category_name_english , avg(r.review_score) as avg_review_score, count(r.review_score) as total_reviews
from order_reviews r	
join order_items ot
on r.order_id=ot.order_id
join products p on p.product_id= ot.product_id
join product_category_translation pct on pct.product_category_name = p.product_category_name
group by  pct.product_category_name_english
having total_reviews >100 
order by avg_review_score desc;

-- What is the average number of items per order? --

select count(*)/ count(distinct order_id) as avg_items_per_order
from order_items;

--  What is the repeat customer percentage? --

with customer_orders as (
select c.customer_unique_id, count(o.order_id) as order_count
from orders o 
join customers c
on c.customer_id = o.customer_id
group by c.customer_unique_id
)
select count(*) as total_customers,
sum(case when order_count > 1 then 1  else 0 end) as repeat_customers,
round((sum(case when order_count > 1 then 1  else 0 end))*100.0/count(*),2) as repeat_pct
from customer_orders;

-- For each month, show total orders and total revenue side by side. --

select date_format(o.order_purchase_timestamp, '%Y-%m') as month, sum(op.payment_value) as total_revenue, count(distinct op.order_id) as total_orders
from orders o 
join order_payments op
on o.order_id = op.order_id
group by date_format(o.order_purchase_timestamp, '%Y-%m')
order by month asc;

-- Who are the top 10 customers by total spend?--

select c.customer_unique_id, sum(op.payment_value) as total_spend, count(distinct op.order_id) as total_order
from customers c 
join orders o on c.customer_id = o.customer_id 
join order_payments op on o.order_id = op.order_id
group by c.customer_unique_id
order by total_spend desc
limit 10 ;

-- Which 10 sellers have the most orders? --

select seller_id, count(distinct order_id) as order_count, sum(price + freight_value) as total_revenue
from order_items 
group by seller_id
order by order_count desc 
limit 10;

-- What is the average review score per month (trend over time)? --

select date_format(review_creation_date, '%Y-%m')  as month, avg(review_score) as avg_review_score
from order_reviews
group by date_format(review_creation_date, '%Y-%m') 
order by month asc;

-- Which 5 states have the highest late delivery percentage? -- 

select c.customer_state,count(*) as total_delivered, 
sum(case when order_estimated_delivery_date < order_delivered_customer_date then 1 else 0 end) as late_orders,
round((sum(case when order_estimated_delivery_date < order_delivered_customer_date then 1 else 0 end))*100.0/count(*),2) as late_pct
from customers c
join orders o 
on c.customer_id = o.customer_id
where o.order_status = 'delivered' and order_delivered_customer_date is not null
group by c.customer_state
order by late_pct desc
limit 5 ;

-- What is the average freight value per state? --

select c.customer_state, avg(oi.freight_value) as avg_freight_value 
from order_items oi 
join orders o on o.order_id=oi.order_id
join customers c on c.customer_id = o.customer_id
group by c.customer_state
order by avg_freight_value desc ;

-- What is the monthly average order value (AOV) in 2017? -- 

select date_format(o.order_purchase_timestamp, '%Y-%m') as month,
sum(op.payment_value)/count(distinct op.order_id) as aov
from order_payments op 
join orders o
on o.order_id = op.order_id
where year(order_purchase_timestamp) = 2017
group by date_format(o.order_purchase_timestamp, '%Y-%m') 
order by month asc;

-- Which product categories have the highest average price per item? --

select pct.product_category_name_english, avg(oi.price) as avg_price , count(*) as total_items
from order_items oi
join products p 
on oi.product_id = p.product_id
join product_category_translation pct 
on pct.product_category_name = p.product_category_name 
group by pct.product_category_name_english
having count(*)  > 50 
order by avg_price desc
limit 10;

-- Which customers have placed orders in 2 or more different months? (Loyalty / repeat behavior across time) -- 

with customer_months as (
select customer_unique_id,
count(distinct date_format(order_purchase_timestamp, '%Y-%m')) as months_active,
count(distinct o.order_id) as order_count
from customers c
join orders o 
on c.customer_id = o.customer_id
group by customer_unique_id
)
select customer_unique_id, months_active,order_count
from customer_months
where months_active >= 2
order by months_active desc, order_count desc
limit 10;

--  Top 5 sellers with best avg ratings (min 20 reviews) -- 

select oi.seller_id, avg(r.review_score) as avg_review_rating , count(distinct oi.order_id) as order_count
from order_items oi
join order_reviews r
on oi.order_id=r.order_id
group by oi.seller_id
having count(distinct oi.order_id) >=20
order by avg_review_rating desc 
limit 5; 

--  Customers who registered but never placed an order --

select count(*) as customer_without_order
from customers c
left join orders o
on c.customer_id = o.customer_id
where order_id is null;

-- Top 20 customers ranked by spend --

select customer_unique_id, total_spend,
rank() over(order by total_spend desc) as customer_rank 
from (
select sum(op.payment_value) as total_spend, c.customer_unique_id
from order_payments op 
join orders o on o.order_id=op.order_id
join customers c on o.customer_id = c.customer_id
group by c.customer_unique_id
order by total_spend desc 
) t
limit 20;