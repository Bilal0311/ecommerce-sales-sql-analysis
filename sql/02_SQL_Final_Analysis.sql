/*================================================================================
PART 2 — FINAL POLISHED VERSION
E-Commerce Sales SQL Analysis
SQL Server / T-SQL

Purpose:
- Keep the learning-phase script above as evidence of progression.
- Use this section as the clean, portfolio-ready analysis.
- Revenue is based on completed orders unless the business question explicitly
  concerns all orders.
================================================================================*/

USE EcommerceSalesDB;
GO

/*==============================================================================
DATA QUALITY
==============================================================================*/

-- DQ 1 — Confirm table sizes
SELECT 'Customers' AS TableName, COUNT(*) AS RowCount
FROM dbo.Customers
UNION ALL
SELECT 'Products', COUNT(*)
FROM dbo.Products
UNION ALL
SELECT 'Orders', COUNT(*)
FROM dbo.Orders
UNION ALL
SELECT 'OrderItems', COUNT(*)
FROM dbo.OrderItems;


-- DQ 2 — Check NULL counts directly
SELECT
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS NullCountry,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS NullSignupDate
FROM dbo.Customers;

SELECT
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS NullProductName,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS NullCategory
FROM dbo.Products;

SELECT
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS NullOrderID,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS NullCustomerID,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS NullOrderDate,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS NullStatus
FROM dbo.Orders;

SELECT
    COUNT(*) AS TotalOrderItems,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS NullOrderID,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS NullQuantity,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS NullPrice
FROM dbo.OrderItems;


-- DQ 3 — Check duplicate IDs
SELECT customer_id, COUNT(*) AS DuplicateCount
FROM dbo.Customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*) AS DuplicateCount
FROM dbo.Products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS DuplicateCount
FROM dbo.Orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- DQ 4 — Check orphan orders / order items
SELECT COUNT(*) AS OrdersWithoutCustomer
FROM dbo.Orders O
LEFT JOIN dbo.Customers C
    ON O.customer_id = C.customer_id
WHERE C.customer_id IS NULL;

SELECT COUNT(*) AS OrderItemsWithoutOrder
FROM dbo.OrderItems OI
LEFT JOIN dbo.Orders O
    ON OI.order_id = O.order_id
WHERE O.order_id IS NULL;

SELECT COUNT(*) AS OrderItemsWithoutProduct
FROM dbo.OrderItems OI
LEFT JOIN dbo.Products P
    ON OI.product_id = P.product_id
WHERE P.product_id IS NULL;


/*==============================================================================
ANALYSIS 1 — DATABASE SIZE
Business question: How large is the e-commerce database?
==============================================================================*/
SELECT 'Customers' AS TableName, COUNT(*) AS TotalCount
FROM dbo.Customers
UNION ALL
SELECT 'Products', COUNT(*)
FROM dbo.Products
UNION ALL
SELECT 'Orders', COUNT(*)
FROM dbo.Orders
UNION ALL
SELECT 'OrderItems', COUNT(*)
FROM dbo.OrderItems;


/*==============================================================================
ANALYSIS 2 — INACTIVE CUSTOMERS
Business question: How many registered customers have never placed an order?
==============================================================================*/
SELECT COUNT(*) AS InactiveCustomers
FROM dbo.Customers C
LEFT JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
WHERE O.order_id IS NULL;


/*==============================================================================
ANALYSIS 3 — ACTIVE CUSTOMERS
Business question: How many registered customers have placed at least one order?
==============================================================================*/
SELECT COUNT(DISTINCT O.customer_id) AS ActiveCustomers
FROM dbo.Orders O;


/*==============================================================================
ANALYSIS 4 — CUSTOMER PURCHASE CONVERSION
Business question: What percentage of registered customers have placed an order?
==============================================================================*/
SELECT
    COUNT(DISTINCT O.customer_id) AS ActiveCustomers,
    COUNT(DISTINCT C.customer_id) AS RegisteredCustomers,
    CAST(
        COUNT(DISTINCT O.customer_id) * 100.0
        / NULLIF(COUNT(DISTINCT C.customer_id), 0)
        AS DECIMAL(6,2)
    ) AS ActiveCustomerPct
FROM dbo.Customers C
LEFT JOIN dbo.Orders O
    ON C.customer_id = O.customer_id;


/*==============================================================================
ANALYSIS 5 — ORDER STATUS DISTRIBUTION
Business question: How many orders were Completed, Cancelled and Returned?
==============================================================================*/
SELECT
    O.status,
    COUNT(*) AS OrderCount
FROM dbo.Orders O
GROUP BY O.status
ORDER BY OrderCount DESC;


/*==============================================================================
ANALYSIS 6 — ORDER STATUS PERCENTAGE
Business question: What percentage of all orders fall into each status?
==============================================================================*/
SELECT
    O.status,
    COUNT(*) AS OrderCount,
    CAST(
        COUNT(*) * 100.0
        / NULLIF(SUM(COUNT(*)) OVER (), 0)
        AS DECIMAL(6,2)
    ) AS StatusPercentage
FROM dbo.Orders O
GROUP BY O.status
ORDER BY StatusPercentage DESC;


/*==============================================================================
ANALYSIS 7 — TOTAL COMPLETED REVENUE
Business question: How much revenue did successfully completed orders generate?
==============================================================================*/
SELECT
    SUM(OI.quantity * OI.price) AS TotalCompletedRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed';


/*==============================================================================
ANALYSIS 8 — MONTHLY REVENUE IN 2024
Business question: Which month generated the highest completed-order revenue
in 2024?
==============================================================================*/
SELECT
    MONTH(O.order_date) AS MonthNumber,
    DATENAME(MONTH, O.order_date) AS MonthName,
    SUM(OI.quantity * OI.price) AS TotalCompletedRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
  AND O.order_date >= '2024-01-01'
  AND O.order_date <  '2025-01-01'
GROUP BY
    MONTH(O.order_date),
    DATENAME(MONTH, O.order_date)
ORDER BY TotalCompletedRevenue DESC;


/*==============================================================================
ANALYSIS 9 — CATEGORY REVENUE
Business question: Which product category generates the highest completed-order
revenue?
==============================================================================*/
SELECT
    P.category,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
JOIN dbo.Products P
    ON OI.product_id = P.product_id
WHERE O.status = 'Completed'
GROUP BY P.category
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 10 — TOP-SELLING PRODUCT IN JANUARY 2024
Business question: Which individual product sold the most units during January
2024 among completed orders?
==============================================================================*/
SELECT
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity) AS UnitsSold
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
JOIN dbo.Products P
    ON OI.product_id = P.product_id
WHERE O.status = 'Completed'
  AND O.order_date >= '2024-01-01'
  AND O.order_date <  '2024-02-01'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY UnitsSold DESC;


/*==============================================================================
ANALYSIS 11 — TOP-REVENUE PRODUCT IN JANUARY 2024
Business question: Which product generated the highest completed-order revenue
during January 2024?
==============================================================================*/
SELECT
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
JOIN dbo.Products P
    ON OI.product_id = P.product_id
WHERE O.status = 'Completed'
  AND O.order_date >= '2024-01-01'
  AND O.order_date <  '2024-02-01'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 12 — AVERAGE ORDER VALUE
Business question: What is the average amount spent per completed order?
==============================================================================*/
SELECT
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(COUNT(DISTINCT O.order_id), 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed';


/*==============================================================================
ANALYSIS 13 — AOV BY COUNTRY
Business question: Which customer country has the highest Average Order Value?
==============================================================================*/
SELECT
    C.country,
    COUNT(DISTINCT O.order_id) AS CompletedOrders,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(COUNT(DISTINCT O.order_id), 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM dbo.Customers C
JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY C.country
ORDER BY AOV DESC;


/*==============================================================================
ANALYSIS 14 — REVENUE BY COUNTRY
Business question: Which country generated the highest total completed revenue?
==============================================================================*/
SELECT
    C.country,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Customers C
JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY C.country
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 15 — CUSTOMER BASE BY COUNTRY
Business question: Which country has the largest registered customer base?
==============================================================================*/
SELECT
    C.country,
    COUNT(*) AS CustomerCount
FROM dbo.Customers C
GROUP BY C.country
ORDER BY CustomerCount DESC;


/*==============================================================================
ANALYSIS 16 — SIGNUP COHORT AOV
Business question: Do customers who signed up in 2024 have a higher completed-
order AOV than customers who signed up in 2023?

Important: Group by signup year, not order year.
==============================================================================*/
SELECT
    YEAR(C.signup_date) AS SignupYear,
    COUNT(DISTINCT C.customer_id) AS PurchasingCustomers,
    COUNT(DISTINCT O.order_id) AS CompletedOrders,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(COUNT(DISTINCT O.order_id), 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM dbo.Customers C
JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY YEAR(C.signup_date)
ORDER BY SignupYear;


/*==============================================================================
ANALYSIS 17 — CUSTOMER TYPE
Business question: How many customers are inactive, one-time, or repeat?
==============================================================================*/
;WITH CustomerOrders AS
(
    SELECT
        C.customer_id,
        COUNT(O.order_id) AS TotalOrders
    FROM dbo.Customers C
    LEFT JOIN dbo.Orders O
        ON C.customer_id = O.customer_id
    GROUP BY C.customer_id
),
CustomerTypes AS
(
    SELECT
        customer_id,
        TotalOrders,
        CASE
            WHEN TotalOrders = 0 THEN 'Never Ordered'
            WHEN TotalOrders = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS CustomerType
    FROM CustomerOrders
)
SELECT
    CustomerType,
    COUNT(*) AS CustomerCount,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(6,2)
    ) AS CustomerPercentage
FROM CustomerTypes
GROUP BY CustomerType
ORDER BY CustomerCount DESC;


/*==============================================================================
ANALYSIS 18 — CUSTOMER REVENUE
Business question: Which customers generate the highest completed-order revenue?
==============================================================================*/
SELECT
    O.customer_id,
    COUNT(DISTINCT O.order_id) AS TotalCompletedOrders,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY O.customer_id
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 19 — CUSTOMER AOV
Business question: Which customers have the highest Average Order Value?
==============================================================================*/
SELECT
    O.customer_id,
    COUNT(DISTINCT O.order_id) AS TotalCompletedOrders,
    SUM(OI.quantity * OI.price) AS TotalRevenue,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(COUNT(DISTINCT O.order_id), 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY O.customer_id
ORDER BY AOV DESC;


/*==============================================================================
ANALYSIS 20 — REPEAT VS ONE-TIME REVENUE
Business question: How much completed revenue comes from repeat customers versus
one-time customers?

Customer type is based on ALL orders placed. Revenue is based only on completed
orders. This separation avoids misclassifying customers.
==============================================================================*/
;WITH CustomerType AS
(
    SELECT
        O.customer_id,
        CASE
            WHEN COUNT(O.order_id) = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS CustomerType
    FROM dbo.Orders O
    GROUP BY O.customer_id
),
RevenueByType AS
(
    SELECT
        CT.CustomerType,
        COUNT(DISTINCT O.customer_id) AS CustomersWithCompletedOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM CustomerType CT
    JOIN dbo.Orders O
        ON CT.customer_id = O.customer_id
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY CT.CustomerType
)
SELECT
    CustomerType,
    CustomersWithCompletedOrders,
    TotalRevenue,
    CAST(
        TotalRevenue * 100.0
        / NULLIF(SUM(TotalRevenue) OVER (), 0)
        AS DECIMAL(6,2)
    ) AS RevenuePercentage
FROM RevenueByType
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 21 — CUSTOMER PURCHASE FREQUENCY
Business question: How many active customers placed 1, 2, 3, 4, or 5+ orders?
==============================================================================*/
;WITH CustomerOrders AS
(
    SELECT
        O.customer_id,
        COUNT(O.order_id) AS TotalOrders
    FROM dbo.Orders O
    GROUP BY O.customer_id
),
FrequencyGroups AS
(
    SELECT
        customer_id,
        TotalOrders,
        CASE
            WHEN TotalOrders = 1 THEN '1'
            WHEN TotalOrders = 2 THEN '2'
            WHEN TotalOrders = 3 THEN '3'
            WHEN TotalOrders = 4 THEN '4'
            ELSE '5+'
        END AS OrderFrequency,
        CASE
            WHEN TotalOrders = 1 THEN 1
            WHEN TotalOrders = 2 THEN 2
            WHEN TotalOrders = 3 THEN 3
            WHEN TotalOrders = 4 THEN 4
            ELSE 5
        END AS SortOrder
    FROM CustomerOrders
)
SELECT
    OrderFrequency,
    COUNT(*) AS CustomerCount
FROM FrequencyGroups
GROUP BY OrderFrequency, SortOrder
ORDER BY SortOrder;


/*==============================================================================
ANALYSIS 22 — ORDER STATUS BY COUNTRY
Business question: Which country has the highest percentage of non-completed
orders (Cancelled + Returned)?
==============================================================================*/
;WITH CountryOrders AS
(
    SELECT
        C.country,
        COUNT(O.order_id) AS TotalOrders,
        SUM(CASE WHEN O.status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
        SUM(CASE WHEN O.status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled,
        SUM(CASE WHEN O.status = 'Returned' THEN 1 ELSE 0 END) AS Returned
    FROM dbo.Customers C
    JOIN dbo.Orders O
        ON C.customer_id = O.customer_id
    GROUP BY C.country
)
SELECT
    country,
    TotalOrders,
    Completed,
    Cancelled,
    Returned,
    CAST(
        (Cancelled + Returned) * 100.0
        / NULLIF(TotalOrders, 0)
        AS DECIMAL(6,2)
    ) AS NonCompletedPct
FROM CountryOrders
ORDER BY NonCompletedPct DESC;


/*==============================================================================
ANALYSIS 23 — CANCELLED VS RETURNED BY COUNTRY
Business question: For each country, what percentage of orders are cancelled
versus returned?
==============================================================================*/
;WITH CountryOrders AS
(
    SELECT
        C.country,
        COUNT(O.order_id) AS TotalOrders,
        SUM(CASE WHEN O.status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled,
        SUM(CASE WHEN O.status = 'Returned' THEN 1 ELSE 0 END) AS Returned
    FROM dbo.Customers C
    JOIN dbo.Orders O
        ON C.customer_id = O.customer_id
    GROUP BY C.country
)
SELECT
    country,
    TotalOrders,
    CAST(
        Cancelled * 100.0 / NULLIF(TotalOrders, 0)
        AS DECIMAL(6,2)
    ) AS CancelledPct,
    CAST(
        Returned * 100.0 / NULLIF(TotalOrders, 0)
        AS DECIMAL(6,2)
    ) AS ReturnedPct
FROM CountryOrders
ORDER BY ReturnedPct DESC;


/*==============================================================================
ANALYSIS 24 — PRODUCT PERFORMANCE
Business question: Which products generate the most completed revenue, and how
many units were sold?
==============================================================================*/
SELECT
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity) AS UnitsSold,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Products P
JOIN dbo.OrderItems OI
    ON P.product_id = OI.product_id
JOIN dbo.Orders O
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 25 — UNITS VS REVENUE
Business question: Are the highest-volume products also the highest-revenue
products?
==============================================================================*/
;WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS UnitsSold,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM dbo.Products P
    JOIN dbo.OrderItems OI
        ON P.product_id = OI.product_id
    JOIN dbo.Orders O
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY
        P.product_id,
        P.product_name,
        P.category
)
SELECT
    product_id,
    product_name,
    category,
    UnitsSold,
    TotalRevenue,
    DENSE_RANK() OVER (ORDER BY UnitsSold DESC) AS UnitRank,
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
FROM ProductMetrics
ORDER BY UnitRank, RevenueRank;


/*==============================================================================
ANALYSIS 26 — REALIZED PRICE PER UNIT
Business question: Which products have the highest average realized selling
price per unit among completed orders?
==============================================================================*/
SELECT
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity) AS UnitsSold,
    SUM(OI.quantity * OI.price) AS TotalRevenue,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(SUM(OI.quantity), 0)
        AS DECIMAL(10,2)
    ) AS AvgRealizedPricePerUnit
FROM dbo.Products P
JOIN dbo.OrderItems OI
    ON P.product_id = OI.product_id
JOIN dbo.Orders O
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY AvgRealizedPricePerUnit DESC;


/*==============================================================================
ANALYSIS 27 — PRODUCT VOLUME VS REVENUE
Business question:
1) Which products are top-10 in unit volume but not top-10 in revenue?
2) Which products are top-10 in revenue but not top-10 in unit volume?
==============================================================================*/
;WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS TotalQuantity,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM dbo.Products P
    JOIN dbo.OrderItems OI
        ON P.product_id = OI.product_id
    JOIN dbo.Orders O
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY
        P.product_id,
        P.product_name,
        P.category
),
ProductRanks AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY TotalQuantity DESC, product_id
        ) AS UnitRank,
        ROW_NUMBER() OVER (
            ORDER BY TotalRevenue DESC, product_id
        ) AS RevenueRank
    FROM ProductMetrics
)
SELECT
    CASE
        WHEN UnitRank <= 10 AND RevenueRank > 10
            THEN 'High Volume / Lower Revenue'
        WHEN RevenueRank <= 10 AND UnitRank > 10
            THEN 'High Revenue / Lower Volume'
    END AS PerformancePattern,
    product_id,
    product_name,
    category,
    TotalQuantity,
    TotalRevenue,
    UnitRank,
    RevenueRank
FROM ProductRanks
WHERE (UnitRank <= 10 AND RevenueRank > 10)
   OR (RevenueRank <= 10 AND UnitRank > 10)
ORDER BY PerformancePattern, UnitRank, RevenueRank;


/*==============================================================================
ANALYSIS 28 — CUSTOMER PURCHASE FREQUENCY VS REVENUE
Business question: Do customers who place more completed orders necessarily
generate more completed revenue?

The two ranks make mismatches easy to identify.
==============================================================================*/
;WITH CustomerMetrics AS
(
    SELECT
        O.customer_id,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue,
        CAST(
            SUM(OI.quantity * OI.price) * 1.0
            / NULLIF(COUNT(DISTINCT O.order_id), 0)
            AS DECIMAL(10,2)
        ) AS AOV
    FROM dbo.Orders O
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY O.customer_id
),
CustomerRanks AS
(
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY TotalOrders DESC) AS OrderRank,
        DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM CustomerMetrics
)
SELECT
    customer_id,
    TotalOrders,
    TotalRevenue,
    AOV,
    OrderRank,
    RevenueRank,
    RevenueRank - OrderRank AS RankGap
FROM CustomerRanks
ORDER BY OrderRank, RevenueRank;


/*==============================================================================
ANALYSIS 29 — HIGHEST-VALUE CUSTOMERS
Business question: Which customers generate the most completed-order revenue?
==============================================================================*/
SELECT
    C.customer_id,
    C.country,
    COUNT(DISTINCT O.order_id) AS CompletedOrders,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Customers C
JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    C.customer_id,
    C.country
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 30 — HIGH REVENUE BUT NOT HIGH AOV
Business definition used:
- Top 10 customers by completed revenue
- Excluding customers who are also top 10 by AOV
==============================================================================*/
;WITH CustomerMetrics AS
(
    SELECT
        O.customer_id,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue,
        CAST(
            SUM(OI.quantity * OI.price) * 1.0
            / NULLIF(COUNT(DISTINCT O.order_id), 0)
            AS DECIMAL(10,2)
        ) AS AOV
    FROM dbo.Orders O
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY O.customer_id
),
CustomerRanks AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY TotalRevenue DESC, customer_id
        ) AS RevenueRank,
        ROW_NUMBER() OVER (
            ORDER BY AOV DESC, customer_id
        ) AS AOVRank
    FROM CustomerMetrics
)
SELECT
    customer_id,
    TotalOrders,
    TotalRevenue,
    AOV,
    RevenueRank,
    AOVRank
FROM CustomerRanks
WHERE RevenueRank <= 10
  AND AOVRank > 10
ORDER BY RevenueRank;


/*==============================================================================
ANALYSIS 31 — CUSTOMER LOYALTY VS VALUE
Business question: Which customers have both a high number of completed orders
and high completed revenue?

Definition of "high": above the customer-level average for both metrics.
==============================================================================*/
;WITH CustomerDetails AS
(
    SELECT
        O.customer_id,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM dbo.Orders O
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY O.customer_id
),
Benchmarks AS
(
    SELECT
        AVG(TotalOrders * 1.0) AS AverageOrders,
        AVG(TotalRevenue * 1.0) AS AverageRevenue
    FROM CustomerDetails
)
SELECT
    CD.customer_id,
    CD.TotalOrders,
    CD.TotalRevenue,
    CAST(
        CD.TotalRevenue * 1.0 / NULLIF(CD.TotalOrders, 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM CustomerDetails CD
CROSS JOIN Benchmarks B
WHERE CD.TotalOrders > B.AverageOrders
  AND CD.TotalRevenue > B.AverageRevenue
ORDER BY CD.TotalRevenue DESC;


/*==============================================================================
ANALYSIS 32 — REPEAT VS ONE-TIME REVENUE SHARE
Business question: Do repeat customers generate a larger share of completed
revenue than one-time customers?

Customer type is based on all orders; revenue is based on completed orders.
==============================================================================*/
;WITH CustomerType AS
(
    SELECT
        O.customer_id,
        CASE
            WHEN COUNT(O.order_id) = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS CustomerType
    FROM dbo.Orders O
    GROUP BY O.customer_id
),
RevenueByType AS
(
    SELECT
        CT.CustomerType,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM CustomerType CT
    JOIN dbo.Orders O
        ON CT.customer_id = O.customer_id
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY CT.CustomerType
)
SELECT
    CustomerType,
    TotalRevenue,
    CAST(
        TotalRevenue * 100.0
        / NULLIF(SUM(TotalRevenue) OVER (), 0)
        AS DECIMAL(6,2)
    ) AS RevenuePercentage
FROM RevenueByType
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 33 — CUSTOMER BASE COMPOSITION
Business question: What percentage of the registered customer base is inactive,
one-time, or repeat?
==============================================================================*/
;WITH CustomerOrders AS
(
    SELECT
        C.customer_id,
        COUNT(O.order_id) AS TotalOrders
    FROM dbo.Customers C
    LEFT JOIN dbo.Orders O
        ON C.customer_id = O.customer_id
    GROUP BY C.customer_id
),
CustomerTypes AS
(
    SELECT
        customer_id,
        CASE
            WHEN TotalOrders = 0 THEN 'Never Ordered'
            WHEN TotalOrders = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS CustomerType
    FROM CustomerOrders
)
SELECT
    CustomerType,
    COUNT(*) AS CustomerCount,
    CAST(
        COUNT(*) * 100.0
        / NULLIF(SUM(COUNT(*)) OVER (), 0)
        AS DECIMAL(6,2)
    ) AS CustomerPercentage
FROM CustomerTypes
GROUP BY CustomerType
ORDER BY CustomerCount DESC;


/*==============================================================================
ANALYSIS 34 — HIGHEST CUSTOMER AOV
Business question: Which customer has the highest AOV among completed orders?
==============================================================================*/
SELECT TOP (1) WITH TIES
    O.customer_id,
    COUNT(DISTINCT O.order_id) AS TotalOrders,
    SUM(OI.quantity * OI.price) AS TotalRevenue,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / NULLIF(COUNT(DISTINCT O.order_id), 0)
        AS DECIMAL(10,2)
    ) AS AOV
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY O.customer_id
ORDER BY AOV DESC;


/*==============================================================================
ANALYSIS 35 — HIGHEST-REVENUE PRODUCT
Business question: Which product generates the highest completed-order revenue?
==============================================================================*/
SELECT TOP (1) WITH TIES
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity) AS UnitsSold,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Products P
JOIN dbo.OrderItems OI
    ON P.product_id = OI.product_id
JOIN dbo.Orders O
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 36 — COUNTRY REVENUE
Business question: Which country generates the highest completed-order revenue?
==============================================================================*/
SELECT
    C.country,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Customers C
JOIN dbo.Orders O
    ON C.customer_id = O.customer_id
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY C.country
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 37 — CATEGORY REVENUE
Business question: Which product category generates the highest completed-order
revenue?
==============================================================================*/
SELECT
    P.category,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM dbo.Orders O
JOIN dbo.OrderItems OI
    ON O.order_id = OI.order_id
JOIN dbo.Products P
    ON OI.product_id = P.product_id
WHERE O.status = 'Completed'
GROUP BY P.category
ORDER BY TotalRevenue DESC;


/*==============================================================================
ANALYSIS 38 — OVERALL ORDER COMPLETION RATE
Business question: What percentage of all orders are successfully completed?
==============================================================================*/
SELECT
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS CompletedOrders,
    CAST(
        SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS CompletionRate
FROM dbo.Orders;


/*==============================================================================
ANALYSIS 39 — TOP-10 CUSTOMER REVENUE CONCENTRATION
Business question: What percentage of completed revenue comes from the top 10
customers?
==============================================================================*/
;WITH CustomerRevenue AS
(
    SELECT
        O.customer_id,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM dbo.Orders O
    JOIN dbo.OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY O.customer_id
),
RankedCustomers AS
(
    SELECT
        customer_id,
        TotalRevenue,
        ROW_NUMBER() OVER (
            ORDER BY TotalRevenue DESC, customer_id
        ) AS RevenueRank
    FROM CustomerRevenue
)
SELECT
    SUM(
        CASE
            WHEN RevenueRank <= 10 THEN TotalRevenue
            ELSE 0
        END
    ) AS Top10Revenue,
    SUM(TotalRevenue) AS TotalRevenue,
    CAST(
        SUM(
            CASE
                WHEN RevenueRank <= 10 THEN TotalRevenue
                ELSE 0
            END
        ) * 100.0
        / NULLIF(SUM(TotalRevenue), 0)
        AS DECIMAL(6,2)
    ) AS Top10RevenuePercentage
FROM RankedCustomers;


/*==============================================================================
END OF FINAL POLISHED VERSION
==============================================================================*/
