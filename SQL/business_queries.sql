/* CREATING A DATABASE FOR RETAIL SALES ANALYTICS PROJECT */
CREATE DATABASE PROJECT
USE PROJECT

/* IMPORTING DATA TO MS SQL SERVER */

/*
    - Open SQL Server Management Studio (SSMS).
    - Connect to your target database.
    - Right-click the database → Tasks → Import Data.
    - Choose Microsoft Excel as the data source.
    - Browse and select your Excel file (.xlsx).
    - Choose the correct Excel version (e.g., Excel 2007).
    - Set SQL Server Native Client as the destination.
    - Select the target database.
    - Choose the sheet(s) to import.
    - Preview and confirm the data.
    - Map columns and adjust data types if needed.
    - Name the destination table (e.g., Customers_Cleaned).
    - Click Finish to run the import.   
*/


/* --------------------- PRIMARY KEY VALIDATION --------------------- */

--> Sales primary key
SELECT order_id, COUNT(*)
FROM Sales_Cleaned
GROUP BY order_id
HAVING COUNT(*) > 1;

--> Customers primary key
SELECT customer_id, COUNT(*)
FROM Customers_Cleaned
GROUP BY customer_id
HAVING COUNT(*) > 1;

--> Products primary key
SELECT product_id, COUNT(*)
FROM Products_Cleaned
GROUP BY product_id
HAVING COUNT(*) > 1;

--> Stores primary key
SELECT store_id, COUNT(*)
FROM Stores_Cleaned
GROUP BY store_id
HAVING COUNT(*) > 1;

--> Returns primary key
SELECT return_id, COUNT(*)
FROM Returns_Cleaned
GROUP BY return_id
HAVING COUNT(*) > 1;

/* ------------ INSERTING A DUMMY RECORD TO PREVENT JOIN FAILURES ------------- */

INSERT INTO Stores_Cleaned (
    store_id, store_name, store_type, region, city, operating_cost
)
VALUES (
    'Unknown', 'Unknown Store', 'Unknown', 'Unknown', 'Unknown', 0
);

-- NOTE:
-- A dummy record with store_id = 'Unknown' was inserted into Stores_Cleaned
-- to handle sales transactions where store information was missing.
-- This ensures referential integrity, prevents join failures, and allows
-- complete revenue and profit analysis without dropping valid sales records.
-- Such records can be excluded or analyzed separately in business queries
-- when required.

/* -------------------------- UPDATING THE PRIMARY KEYS ----------------------- */

-- Customers Table
ALTER TABLE Customers_Cleaned
ALTER COLUMN customer_id VARCHAR(10) NOT NULL;

ALTER TABLE Customers_Cleaned
ADD CONSTRAINT PK_Customers
PRIMARY KEY (customer_id);

-- Products Table
ALTER TABLE Products_Cleaned
ALTER COLUMN product_id VARCHAR(10) NOT NULL;

ALTER TABLE Products_Cleaned
ADD CONSTRAINT PK_Products
PRIMARY KEY (product_id);

-- Stores Table
ALTER TABLE Stores_Cleaned
ALTER COLUMN store_id VARCHAR(10) NOT NULL;

ALTER TABLE Stores_Cleaned
ADD CONSTRAINT PK_Stores
PRIMARY KEY (store_id);

-- Sales Table
ALTER TABLE Sales_Cleaned
ALTER COLUMN order_id VARCHAR(10) NOT NULL;

ALTER TABLE Sales_Cleaned
ADD CONSTRAINT PK_Sales
PRIMARY KEY (order_id);

-- Returns Table
ALTER TABLE Returns_Cleaned
ALTER COLUMN return_id VARCHAR(10) NOT NULL;

ALTER TABLE Returns_Cleaned
ADD CONSTRAINT PK_Returns
PRIMARY KEY (return_id);

/* ------------------------------ FOREIGN KEYS ---------------------------- */

/* sales ---> customers */
ALTER TABLE Sales_Cleaned
ADD CONSTRAINT FK_Sales_Customers
FOREIGN KEY (customer_id)
REFERENCES Customers_Cleaned(customer_id);

/*sales ---> products*/

ALTER TABLE Sales_Cleaned
ALTER COLUMN product_id VARCHAR(10) NOT NULL;

ALTER TABLE Sales_Cleaned
ADD CONSTRAINT FK_Sales_Products
FOREIGN KEY (product_id)
REFERENCES Products_Cleaned(product_id);

/*sales ---> stores*/
ALTER TABLE Sales_Cleaned
ALTER COLUMN store_id VARCHAR(10) NOT NULL;


ALTER TABLE Sales_Cleaned
ADD CONSTRAINT FK_Sales_Stores
FOREIGN KEY (store_id)
REFERENCES Stores_Cleaned(store_id);

/*returns ---> sales*/
ALTER TABLE Returns_Cleaned
ALTER COLUMN order_id VARCHAR(10) NOT NULL;


ALTER TABLE Returns_Cleaned
ADD CONSTRAINT FK_Returns_Sales
FOREIGN KEY (order_id)
REFERENCES Sales_Cleaned(order_id);

/* ------------------------ FOREIGN KEY VALIDATION ----------------------- */

-- Check orphan customers
SELECT COUNT(*) AS Orphan_Customers
FROM Sales_Cleaned s
LEFT JOIN Customers_Cleaned c
ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check orphan products
SELECT COUNT(*) AS Orphan_Products
FROM Sales_Cleaned s
LEFT JOIN Products_Cleaned p
ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check orphan stores
SELECT COUNT(*) AS Orphan_Stores
FROM Sales_Cleaned s
LEFT JOIN Stores_Cleaned st
ON s.store_id = st.store_id
WHERE st.store_id IS NULL;

/* ============================== BUSINESS QUESTIONS ============================ */

/* 1. What is the total revenue generated in the last 12 months?  */
-- Query: 

SELECT 
    SUM(total_amount) AS Total_Revenue_Last_12_Months
FROM Sales_Cleaned
WHERE order_date >= DATEADD(MONTH, -12, GETDATE());

/* 2. Which are the top 5 best-selling products by quantity? */
-- Query:

SELECT TOP 5
    p.product_name AS Product_Name,
    SUM(s.quantity) AS Total_Quantity_Sold
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC;

/* 3. How many customers are from each region? */
-- Query:

SELECT
    region AS Region,
    COUNT(*) AS Customer_Count
FROM Customers_Cleaned
GROUP BY region
ORDER BY customer_count DESC;

/* 4. Which store has the highest profit in the past year? */
-- Query:

---> 'Unknown' Dummy Record included:
SELECT TOP 1
    st.store_name AS Store_Name,
    SUM(p.Profit * s.quantity) AS Total_Profit
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
JOIN Stores_Cleaned st
    ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY st.store_name
ORDER BY total_profit DESC;

---> 'Unknown' Dummy Record Excluded:
SELECT TOP 1
    st.store_name AS Store_Name,
    SUM(p.Profit * s.quantity) AS Total_Profit
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
JOIN Stores_Cleaned st
    ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -1, GETDATE())
  AND st.store_id <> 'Unknown'
GROUP BY st.store_name
ORDER BY total_profit DESC;

/* 5. What is the return rate by product category? */
-- Query:

SELECT
    p.category AS Category,
    COUNT(r.return_id) * 1.0 / COUNT(s.order_id) AS Return_Rate
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
LEFT JOIN Returns_Cleaned r
    ON s.order_id = r.order_id
GROUP BY p.category
ORDER BY return_rate DESC;

/* 6. What is the average revenue per customer by age group? */
-- Query:

SELECT
    Age_Group,
    AVG(customer_revenue) AS Avg_Revenue_Per_Customer
FROM (
    SELECT
        c.customer_id,
        c.Age_Group,
        SUM(s.total_amount) AS customer_revenue
    FROM Sales_Cleaned s
    JOIN Customers_Cleaned c
        ON s.customer_id = c.customer_id
    GROUP BY c.customer_id, c.Age_Group
) t
GROUP BY Age_Group
ORDER BY avg_revenue_per_customer DESC;

/* 7. Which sales channel (Online vs In-Store) is more profitable on average? */
-- Query:

SELECT
    s.sales_channel AS Sales_Channel,
    AVG(p.Profit * s.quantity) AS Avg_Profit
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
GROUP BY s.sales_channel
ORDER BY avg_profit DESC;

/* 8. How has monthly profit changed over the last 2 years by region? */
-- Query:

---> 'Unknown' Dummy Record included:
SELECT
    FORMAT(s.order_date, 'yyyy-MM') AS Month,
    st.region AS Region,
    SUM(p.Profit * s.quantity) AS Monthly_Profit
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
JOIN Stores_Cleaned st
    ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -2, GETDATE())
GROUP BY FORMAT(s.order_date, 'yyyy-MM'), st.region
ORDER BY month, st.region;

---> 'Unknown' Dummy Record Excluded:
SELECT
    FORMAT(s.order_date, 'yyyy-MM') AS Month,
    st.region AS Region,
    SUM(p.Profit * s.quantity) AS Monthly_Profit
FROM Sales_Cleaned s
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
JOIN Stores_Cleaned st
    ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(YEAR, -2, GETDATE())
  AND st.region <> 'Unknown'
GROUP BY FORMAT(s.order_date, 'yyyy-MM'), st.region
ORDER BY month, st.region;

/* 9. Identify the top 3 products with the highest return rate in each category. */
-- Query:

WITH ProductStats AS (
    SELECT
        p.category,
        p.product_name,
        COUNT(DISTINCT r.return_id) AS total_returns,
        COUNT(DISTINCT s.order_id) AS total_orders
    FROM Sales_Cleaned s
    JOIN Products_Cleaned p
        ON s.product_id = p.product_id
    LEFT JOIN Returns_Cleaned r
        ON s.order_id = r.order_id
    GROUP BY p.category, p.product_name
),
ReturnRates AS (
    SELECT
        category,
        product_name,
        CAST(total_returns AS FLOAT) / total_orders AS return_rate
    FROM ProductStats
    WHERE total_returns > 0 
),
RankedProducts AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY category
               ORDER BY return_rate DESC
           ) AS rn
    FROM ReturnRates
)
SELECT
    category AS Category,
    product_name AS Product_Name,
    return_rate as Return_Rate
FROM RankedProducts
WHERE rn <= 3
ORDER BY category, return_rate DESC;

/* 10. Which 5 customers have contributed the most to total profit, and what is their tenure with the company?  */
-- Query:

SELECT TOP 5
    c.customer_id AS Customer_ID,
    c.first_name AS First_Name,
    c.last_name AS Last_Name,
    SUM(p.Profit * s.quantity) AS Total_Profit,
    DATEDIFF(YEAR, c.signup_date, GETDATE()) AS Tenure_Years
FROM Sales_Cleaned s
JOIN Customers_Cleaned c
    ON s.customer_id = c.customer_id
JOIN Products_Cleaned p
    ON s.product_id = p.product_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.signup_date
ORDER BY total_profit DESC;























