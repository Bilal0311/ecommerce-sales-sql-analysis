/*==============================================================
E-COMMERCE SALES DATABASE
Database Setup and Data Import
SQL Server / T-SQL
==============================================================*/

USE EcommerceSalesDB;
GO


/*==============================================================
1. CREATE TABLES
==============================================================*/

CREATE TABLE dbo.Customers
(
    customer_id INT PRIMARY KEY,
    country VARCHAR(50),
    signup_date DATE
);


CREATE TABLE dbo.Products
(
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);


CREATE TABLE dbo.Orders
(
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),

    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (customer_id)
        REFERENCES dbo.Customers(customer_id)
);


/*
A surrogate OrderItemID is used as the primary key because the source
data can contain multiple rows with the same order_id and product_id.
*/

CREATE TABLE dbo.OrderItems
(
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (order_id)
        REFERENCES dbo.Orders(order_id),

    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (product_id)
        REFERENCES dbo.Products(product_id)
);


/*==============================================================
2. VERIFY TABLE CREATION
==============================================================*/

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';


/*==============================================================
3. IMPORT CUSTOMERS
Update file paths before executing.
==============================================================*/

BULK INSERT dbo.Customers
FROM 'C:\path\to\customers.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);


/*==============================================================
4. IMPORT PRODUCTS
==============================================================*/

BULK INSERT dbo.Products
FROM 'C:\path\to\products.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);


/*==============================================================
5. IMPORT ORDERS
==============================================================*/

BULK INSERT dbo.Orders
FROM 'C:\path\to\orders.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);


/*==============================================================
6. CREATE STAGING TABLE FOR ORDER ITEMS
==============================================================*/

/*
The source CSV does not contain OrderItemID because it is generated
by SQL Server. A staging table is therefore used to import the four
source columns before transferring them into dbo.OrderItems.
*/

CREATE TABLE dbo.OrderItems_Staging
(
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2)
);


BULK INSERT dbo.OrderItems_Staging
FROM 'C:\path\to\order_items.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);


/*==============================================================
7. VALIDATE STAGED DATA
==============================================================*/

-- Check for order IDs that do not exist in Orders

SELECT COUNT(*) AS InvalidOrders
FROM dbo.OrderItems_Staging S
LEFT JOIN dbo.Orders O
    ON S.order_id = O.order_id
WHERE O.order_id IS NULL;


-- Check for product IDs that do not exist in Products

SELECT COUNT(*) AS InvalidProducts
FROM dbo.OrderItems_Staging S
LEFT JOIN dbo.Products P
    ON S.product_id = P.product_id
WHERE P.product_id IS NULL;


/*==============================================================
8. LOAD VALIDATED ORDER ITEMS
==============================================================*/

INSERT INTO dbo.OrderItems
(
    order_id,
    product_id,
    quantity,
    price
)
SELECT
    order_id,
    product_id,
    quantity,
    price
FROM dbo.OrderItems_Staging;


/*==============================================================
9. VERIFY IMPORT COUNTS
==============================================================*/

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


/*==============================================================
10. CLEAN UP STAGING TABLE
==============================================================*/

DROP TABLE dbo.OrderItems_Staging;
