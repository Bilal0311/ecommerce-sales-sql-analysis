CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    country VARCHAR(50),
    signup_date DATE
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),

    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id)
);

CREATE TABLE OrderItems (
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),

    CONSTRAINT PK_OrderItems
        PRIMARY KEY (order_id, product_id),

    CONSTRAINT FK_OrderItems_Orders
        FOREIGN KEY (order_id)
        REFERENCES Orders(order_id),

    CONSTRAINT FK_OrderItems_Products
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
);

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';


SELECT 'Customers' AS TableName, COUNT(*) AS Row_Count
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

BULK INSERT dbo.Customers
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT COUNT(*) AS CustomerCount
FROM dbo.Customers

BULK INSERT dbo.Products
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT COUNT(*) AS ProductCount
FROM dbo.Products;

BULK INSERT dbo.Orders
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT COUNT(*) AS OrderCount
FROM dbo.Orders;

--this was an error, coz considered both order_id and Customer_id as primary keys, which was a mistake as in the data there is two records with same order_id,product_id but differentquantity and price
/*
BULK INSERT dbo.OrderItems
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
*/
-- droping the table as before it was created with two primary keys, which resulted in the error, so to allign with the data redsigning the database schema
DROP TABLE dbo.OrderItems;

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

BULK INSERT dbo.OrderItems
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
--had to create a staging table with no primary key, coz an issue arrised while importing the data, mismatch in the created table and the data importing(in the created table we added order_itemID but in the csv file there is no such column)

CREATE TABLE dbo.OrderItems_Staging
(
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2)
);

BULK INSERT dbo.OrderItems_Staging
FROM 'C:\Users\BILAL\OneDrive\Desktop\Projects\SQL\Dataset\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT COUNT(*) AS StagingCount
FROM dbo.OrderItems_Staging;

--Step 4 — Validate before moving the data
--First, let's check whether the foreign-key values are valid.
--Check 1: Every order_id exists in Orders
SELECT COUNT(*) AS InvalidOrders
FROM dbo.OrderItems_Staging s
LEFT JOIN dbo.Orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS InvalidProducts
FROM dbo.OrderItems_Staging s
LEFT JOIN dbo.Products p
    ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

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

select *
from OrderItems

SELECT *
FROM dbo.OrderItems
WHERE order_id = 17
  AND product_id = 35;
