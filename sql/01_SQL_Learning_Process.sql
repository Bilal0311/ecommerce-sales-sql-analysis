/*================================================================================
PART 1 — LEARNING PHASE
Original SQL exactly as developed during the analysis process.
This section intentionally preserves experiments, mistakes, corrections and notes.
================================================================================*/

use EcommerceSalesDB

--DATA QUALITY
--Before an analyst calculates revenue, they should know whether the data can be trusted.


--Analysis 1 — Confirm table sizes
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


--Analysis 2 — Check for NULLs, for each table
SELECT
    COUNT(*) AS TotalCustomers,
    COUNT(customer_id) AS CustomersWithID,
    COUNT(country) AS CustomersWithCountry,
    COUNT(signup_date) AS CustomersWithSignupDate
FROM dbo.Customers;

SELECT
    COUNT(*) AS TotalOrders,
    COUNT(order_id) AS OrdersWithID,
    COUNT(customer_id) AS OrdersWithCustomerID,
    COUNT(order_date) AS OrdersWithDate,
    COUNT(status) AS OrdersWithStatus
FROM dbo.Orders;

SELECT
    COUNT(*) AS TotalItems,
    COUNT(Product_id),
    COUNT(product_name),
    COUNT(category)
FROM Products

SELECT
    COUNT(*) AS TotalItems,
    COUNT(order_id) AS ItemsWithOrderID,
    COUNT(product_id) AS ItemsWithProductID,
    COUNT(quantity) AS ItemsWithQuantity,
    COUNT(price) AS ItemsWithPrice
FROM dbo.OrderItems;

--ANALYSIS 1 — How many customers, products, orders and order items do we have?
--Business question
--How large is our e-commerce database?
select 'Customers' TableName, count(*) as TotalCount
from Customers
union all
select 'Products',count(*)
from Products
union all
select 'Orders',count(*)
from Orders
union all
select 'OrderItems',COUNT(*)
from OrderItems

--ANALYSIS 2 — How many customers have never placed an order?
--Business question
--How many registered customers have never purchased anything?
select *
from Customers C
left join Orders O
on c.customer_id = O.customer_id 
where order_id is NULL
order by C.customer_id asc

SELECT COUNT(*) AS InactiveCustomers
FROM Customers C
LEFT JOIN Orders O
    ON C.customer_id = O.customer_id
WHERE O.order_id IS NULL;


--ANALYSIS 3 — How many customers actually placed orders?
--Business question
--Out of our 300 registered customers, how many actually made at least one purchase?

select *
from Customers

select *
from Orders

SELECT DISTINCT O.customer_id,
    C.country,
    C.signup_date
FROM Customers C
INNER JOIN Orders O
    ON C.customer_id = O.customer_id;

SELECT count(DISTINCT O.customer_id) ActiveCustomers
FROM Customers C
INNER JOIN Orders O
    ON C.customer_id = O.customer_id;


--ANALYSIS 4 — What percentage of customers have actually purchased?
--Business question
--What percentage of registered customers have converted into purchasing customers?

SELECT format(
            count(DISTINCT O.customer_id)*100.0
            /(select count(customer_id) from Customers),
            '0.00'
        )+ '%' ActiveCustomers
FROM Orders O
--95% of registered customers placed at least one order, while 5% of registered customers have never ordered.


--ANALYSIS 5 — How many orders were Completed, Cancelled and Returned?
--Business question
--What is the overall order-status distribution?

select 
    status,
    count(*) StatusCount
from Orders
group by status
order by StatusCount desc


--ANALYSIS 6 — What percentage of orders are Completed, Cancelled and Returned?
--Business question
--What percentage of all orders were completed, cancelled, and returned?

select 
    status,
    count(*) OrderCount,
    format(
        count(*)*100.0
        /(select count(*) from Orders),'0.00'
       ) + '%' StatusCountPercent
from Orders
group by status
order by OrderCount desc

SELECT
    status,
    COUNT(*) AS OrderCount,
    cast(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Orders)as decimal(5,2)) StatusPercentage
FROM Orders
GROUP BY status
ORDER BY StatusPercentage DESC;
--when we eventually put this into Power BI, we can format StatusPercentage as %.
--Else there will be issues while calculating

--ANALYSIS 7 — How much revenue did the business generate?
--Business question
--What is the total sales revenue generated from the orders?
select sum(price) TotalSalesRevenue
from OrderItems
--mistake coz only the completed order get counted in the total revenue right

select sum(OI.price * OI.quantity) TotalSalesRevenue
from OrderItems OI
inner join Orders O
    on OI.order_id = O.order_id
where status = 'Completed'
--just to show output with dollar symbol
select '$'+format(
        sum(OI.price * OI.quantity),'0.00' 
    )TotalSalesRevenue
from OrderItems OI
inner join Orders O
    on OI.order_id = O.order_id
where status = 'Completed'


--ANALYSIS 8 — Which month generated the most revenue?
--Business question
--Which months generated the highest completed-order revenue in 2024?

select
    MONTH(O.order_date) AS MonthNumber,
    DateName(Month,O.order_date) MonthOfOrder,
    sum(OI.price*OI.quantity) TotalCompletedRevenue
from Orders O
inner join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed' and o.order_date like '2024%'
group by DateName(Month,O.order_date),
    MONTH(O.order_date)
ORDER BY MonthNumber

--Which month generated the most revenue?
SELECT
    MONTH(O.order_date) AS MonthNumber,
    DATENAME(MONTH, O.order_date) AS MonthOfOrder,
    SUM(OI.price * OI.quantity) AS TotalCompletedRevenue
FROM Orders O
INNER JOIN OrderItems OI
    ON OI.order_id = O.order_id
WHERE O.status = 'Completed'
GROUP BY
    MONTH(O.order_date),
    DATENAME(MONTH, O.order_date)
ORDER BY
    TotalCompletedRevenue desc;


--ANALYSIS 9 — Which product category generates the most revenue?
--Which product category generates the highest completed-order revenue?
select 
    P.category,
    sum(OI.quantity*OI.price) RevenuePerCategory
from orders O
join OrderItems OI
    on O.order_id = OI.order_id
join Products P
    on OI.product_id = P.product_id
where status = 'Completed'
Group by P.category
--My own question we understood that, the most revenue generated month was january, which product was mostly sold in that month 
select 
    P.category,
    sum(OI.quantity*OI.price) RevenuePerCategory
from orders O
join OrderItems OI
    on O.order_id = OI.order_id
join Products P
    on OI.product_id = P.product_id
where status = 'Completed' and o.order_date like '%-01-%'
Group by P.category
--better than this o.order_date like '%-01-%' is Month(O.order_date) = 1
select 
    P.category,
    sum(OI.quantity*OI.price) RevenuePerCategory
from orders O
join OrderItems OI
    on O.order_id = OI.order_id
join Products P
    on OI.product_id = P.product_id
where status = 'Completed' and Month(O.order_date) = 1
Group by P.category
order by RevenuePerCategory desc


--ANALYSIS 10 — Which individual product sold the most units during January among completed orders?
select 
    P.product_id,
    P.product_name,
    P.category,
    sum(OI.quantity) UnitSold
from orders O
join OrderItems OI
    on O.order_id = OI.order_id
join Products P
    on OI.product_id = P.product_id
where status = 'Completed' and Month(O.order_date) = 1
group by P.product_name,
    P.category,
    P.product_id
order by UnitSold desc

--ANALYSIS 11 — Which product generated the most revenue in January?
--Which individual product generated the highest completed-order revenue during January?

select 
    P.product_id,
    P.product_name,
    P.category,
    sum(OI.quantity*OI.price) UnitRevenue
from orders O
join OrderItems OI
    on O.order_id = OI.order_id
join Products P
    on OI.product_id = P.product_id
where status = 'Completed' and Month(O.order_date) = 1
group by P.product_name,
    P.category,
    P.product_id
order by UnitRevenue desc


--ANALYSIS 12 — What is the Average Order Value?
--Business question
--What is the average amount customers spend per completed order?
--AOV = Total Completed Revenue/ Number of Completed Orders

select 
    cast(
        sum(OI.price*OI.quantity) *1.0
        /count(distinct O.order_id)
        as decimal(5,2)
    ) AOV
from Orders O
join OrderItems OI
    on OI.order_id = O.order_id
where status = 'Completed'
--use cast & format in places to make it neat


--ANALYSIS 13 — Which country has the highest Average Order Value?
--Which customer country has the highest Average Order Value for completed orders?
--Customers from which country tend to place the highest-value orders?

select 
    C.country,
    cast(
        sum(OI.price*OI.quantity) *1.0
        /count(distinct O.order_id)
        as decimal(5,2)
    ) AOV
from Customers C
join Orders O
    on C.customer_id = O.customer_id
join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed'
Group by C.country
order by AOV desc


--ANALYSIS 14 — Which country generates the most total revenue?
--Which country generated the highest total completed-order revenue?

select 
    C.country,
    Sum(OI.price*OI.quantity) TotalRevenue
from Customers C
join Orders O
    on C.customer_id = O.customer_id
join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed'
Group by C.country
order by TotalRevenue desc
--Analysis 13:Morocco had the highest AOV: $486.30, But Analysis 14:Italy generated the highest total revenue: $70,719
--So Morocco has the highest average order value, but Italy makes the most total money.
--High-value customers/orders don't necessarily produce the highest total revenue; order volume also matters.


--ANALYSIS 15 — Where are the most customers?
--Which country has the largest customer base?

select 
    country,
    count(customer_id) CustomerCount
from Customers
group by country
order by CustomerCount desc


--ANALYSIS 16 — Are newer customers spending more?
--Do customers who signed up in 2024 have a higher Average Order Value than customers who signed up in 2023?
select 
    '2023' SignUpYear,
    count(*) TotalCustomers
from Customers
where YEAR(signup_date) = 2023
union
select 
    '2024',
    count(*)
from Customers
where YEAR(signup_date) = 2024

select
    year( C.signup_date) SignUpYear,
    cast(
        sum(OI.price*OI.quantity) * 1.0
        /count(distinct O.order_id)
        as decimal(5,2)
     ) AOV
from Customers C
Left join Orders O
    on C.customer_id=O.customer_id
Left join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed' 
group by year(C.signup_date) 

select *
from Orders
where YEAR(order_date) = 2023

--better version
SELECT
    YEAR(O.order_date) AS OrderYear,
    CAST(
        COALESCE(
            SUM(OI.price * OI.quantity) * 1.0
            / NULLIF(COUNT(DISTINCT O.order_id), 0),
            0
        )
        AS DECIMAL(10,2)
    ) AS AOV
FROM Customers C
LEFT JOIN Orders O
    ON C.customer_id = O.customer_id
    AND O.status = 'Completed'
LEFT JOIN OrderItems OI
    ON O.order_id = OI.order_id
GROUP BY YEAR(O.order_date)
ORDER BY OrderYear;

-- actually in this part i got very confused that i thought how come when the 2023 even doesnt exist in the orders table have an AOV
-- but later i understood that customers signed up in 2023 could make an order in 2024 right , and customer signed up in 2024 can also make an order
-- so these two are different signup year and both customers actually completed the order, and to clarify this below is the analysis
SELECT
    YEAR(C.signup_date) AS SignupYear,
    YEAR(O.order_date) AS OrderYear,
    COUNT(DISTINCT C.customer_id) AS Customers,
    COUNT(DISTINCT O.order_id) AS CompletedOrders,
    SUM(OI.quantity * OI.price) AS Revenue
FROM Customers C
INNER JOIN Orders O
    ON C.customer_id = O.customer_id
INNER JOIN OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    YEAR(C.signup_date),
    YEAR(O.order_date)
ORDER BY
    SignupYear,
    OrderYear;

-- so the crct ans for analysis 16
select
    year( C.signup_date) SignUpYear,
    cast(
        sum(OI.price*OI.quantity) * 1.0
        /count(distinct O.order_id)
        as decimal(5,2)
     ) AOV
from Customers C
Left join Orders O
    on C.customer_id=O.customer_id
Left join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed' 
group by year(C.signup_date) 
--And the correct interpretation is:
--  Customers who signed up in 2024 had a slightly higher average completed-order value than customers who signed up in 2023.
--Not "2023 customers spent $385 in 2023."


--ANALYSIS 17 — Repeat Customers
--How many customers are repeat customers — meaning they placed more than one order?
--Why is this useful?
--A business doesn't only care about acquiring customers. It also wants to know whether customers come back and purchase again.

select 
    customer_id,
    count(order_id) TotalOrders
from Orders
group by customer_id
having count(order_id) > 1
--progression
select Count(*) RepeatedCustomerCount
from(
    select 
        customer_id,
        count(order_id) TotalOrders
    from Orders
    group by customer_id
    having count(order_id) > 1
    ) RepeatedCustomer
union
select Count(*)
from(
    select 
        customer_id,
        count(order_id) TotalOrders
    from Orders
    group by customer_id
    having count(order_id) = 1
    ) OneTimeCustomer

--progression
--| Customer Type     | Count |
--| ----------------- | ----: |
--| Never Ordered     |    15 |
--| One-Time Customer |    39 |
--| Repeat Customer   |   246 |











-- using corelated query
select 
    O.customer_id,
    (select
        count(*)
     from Orders O2
     where O.customer_id = O2.customer_id) TotalOrders,
     case  
        when(
            select
                count(*)
             from Orders O2
             where O.customer_id = O2.customer_id) = 1 then 'Onetime'
             when(select
                count(*)
             from Orders O2
             where O.customer_id = O2.customer_id) > 1 then 'Repeated'
     end as CustomerType
from Orders O
group by O.customer_id
-- but too bulky

--to do like if statement in other languages in SQL we use When & Then
select 
     O.customer_id,
     count(O.order_id) TotalOrders,
     case
     when count(O.order_id) = 1 then 'OneTime'
     when count(O.order_id) > 1 then 'Repeated'
     end CustomerType
from Orders O
group by O.customer_id

--smaller version
select 
    CustomerType,
    count(*) Countt
from(
     select 
         O.customer_id,
         count(O.order_id) TotalOrders,
         case
         when count(O.order_id) = 1 then 'OneTime'
         when count(O.order_id) > 1 then 'Repeated'
         end CustomerType
    from Orders O
    group by O.customer_id
    )t
group by CustomerType
Union
select 'Never Ordered',
    count(*)
from Customers C
left join Orders O
    on C.customer_id = O.customer_id
where order_id is Null
--another version, i think this would be the simplest
--first we will categorize the data into (Never Ordered, Onetime, Repeated) then we'll count it groupwise
select 
    C.customer_id,
    count(O.order_id) TotalOrders,
    case
    when count(O.order_id) = 0 then 'Never Ordered'
    when count(O.order_id) = 1 then 'One Time Customer'
    when count(O.order_id) > 1 then 'Repeated Customer'
    End CustomerType
from Customers C
left join Orders O
    on C.customer_id = O.customer_id
group by C.customer_id
-- consider the above result as a table, so we r going to group it now to count each customer type
select
    CustomerType,
    count(TotalOrders) Countt
from(
        select 
            C.customer_id,
            count(O.order_id) TotalOrders,
            case
            when count(O.order_id) = 0 then 'Never Ordered'
            when count(O.order_id) = 1 then 'One Time Customer'
            when count(O.order_id) > 1 then 'Repeated Customer'
            End CustomerType
        from Customers C
        left join Orders O
            on C.customer_id = O.customer_id
        group by C.customer_id
    ) t
group by CustomerType
--Question: How many customers are repeat, one-time, or inactive?
--Result:
--246 repeat customers
--39 one-time customers
--15 never ordered
--300 total customers
--And the repeat-customer rate among active customers is:
--246 / 285 = 86.32%

--ANALYSIS 18 — Next Question(Now let's take the repeat-customer analysis one level deeper.)
--Which customers generate the highest total revenue?
select 
    C.customer_id, 
    count(distinct O.order_id) TotalOrders,
    sum(OI.quantity*OI.price) Revenue
from Customers C
join Orders O
    on C.customer_id = O.customer_id    -- revenue = quqntity * price 
join OrderItems OI
    on O.order_id = OI.order_id
where O.status = 'Completed'
group by C.customer_id
order by Revenue Desc

--testing
select 
    C.customer_id,
    count(*)
from Customers C
join Orders O
    on C.customer_id=O.customer_id
group by C.customer_id
having C.customer_id = 152


--ANALYSIS 19 — Customer Value
--Which customers have the highest Average Order Value?
select 
    C.customer_id, 
    count(distinct O.order_id) TotalOrders,
    sum(OI.quantity*OI.price) Revenue,
    cast(
        sum(OI.quantity*OI.price)*1.0
        /count(distinct O.order_id) 
        as decimal(6,2) 
       )AOV
from Customers C
join Orders O
    on C.customer_id = O.customer_id   
join OrderItems OI
    on O.order_id = OI.order_id
where O.status = 'Completed'
group by C.customer_id
order by AOV Desc


--ANALYSIS 20 — Repeat Customer Revenue
--How much of our total completed revenue comes from repeat customers versus one-time customers?

--first i did mistake by putting O.status = 'Completed in the '

select 
    CustomerType,
    count(distinct t1.customer_id) NumOfCustomers,
    sum(OI.price*OI.quantity) TotalRevenue
from(
        select 
            C.customer_id,
            case
            when count(O.order_id) = 1 then 'One-Time'
            when count(O.order_id) > 1 then 'Repeated'
            end CustomerType
        from Customers C
        left join Orders O
            on C.customer_id = O.customer_id
        group by C.customer_id) t1
join Orders O
    on t1.customer_id = O.customer_id
join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed'
group by CustomerType;
--vs the mistake one
select 
    CustomerType,
    count(TotalOrder) Countt,
    sum(OI.price*OI.quantity) TotalRevenue
from(
        select 
            C.customer_id,
            count(O.order_id) TotalOrder, 
            case
            when count(O.order_id) = 1 then 'One-Time'
            when count(O.order_id) > 1 then 'Repeated'
            end CustomerType
        from Customers C
        left join Orders O
            on C.customer_id = O.customer_id
        where O.status = 'Completed'
        group by C.customer_id) t1
join Orders O
    on t1.customer_id = O.customer_id
join OrderItems OI
    on OI.order_id = O.order_id
group by CustomerType;

--final ans(u can write the subquery like this too)
WITH CustomerType AS
(
    SELECT
        customer_id,
        CASE
            WHEN COUNT(order_id) = 1 THEN 'One-Time'
            WHEN COUNT(order_id) > 1 THEN 'Repeat'
        END AS CustomerType
    FROM Orders
    GROUP BY customer_id
)
SELECT
    CT.CustomerType,
    cast(
        SUM(OI.quantity * OI.price)*100.0
        /(select 
            sum(OI.quantity*OI.price) TotalRevenue
        from OrderItems OI
        join Orders O
            on OI.order_id = O.order_id
        where O.status = 'Completed'
        ) as decimal(4,2)
        ) BusinessPercent
FROM CustomerType CT
JOIN Orders O
    ON CT.customer_id = O.customer_id
JOIN OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY CT.CustomerType; 

select 
    sum(OI.quantity*OI.price)
from OrderItems OI
join Orders O
    on OI.order_id = O.order_id
where O.status = 'Completed'

--ANALYSIS 21 — Customer Purchase Frequency
--How many customers placed 1, 2, 3, 4, 5+ orders?

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS TotalOrders
    FROM Orders
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN TotalOrders = 1 THEN '1'
        WHEN TotalOrders = 2 THEN '2'
        WHEN TotalOrders = 3 THEN '3'
        WHEN TotalOrders = 4 THEN '4'
        ELSE '5+'
    END AS NumberOfOrders,
    COUNT(*) AS NumOfCustomers
FROM CustomerOrders
GROUP BY
    CASE
        WHEN TotalOrders = 1 THEN '1'
        WHEN TotalOrders = 2 THEN '2'
        WHEN TotalOrders = 3 THEN '3'
        WHEN TotalOrders = 4 THEN '4'
        ELSE '5+'
    END;



--ANALYSIS 22 — Order Status by Country
--Now we're going to use everything you've learned so far and introduce a very useful business analysis.
/*We've already discovered:
  Italy has the largest customer base.
  Italy generates the highest total revenue.
  Morocco has the highest AOV.
  Overall orders are:
  Completed: 805
  Cancelled: 103
  Returned: 92*/
--Now let's ask:
/*Does order quality differ by country?
  More specifically:
  Which country has the highest percentage of non-completed orders (Cancelled + Returned)?
  This could reveal a country where the business has a fulfillment, customer-service, or product issue.*/

  --Country | TotalOrders | Completed | Cancelled | Returned | NonCompleted%

select 
    C.country,
    count(O.order_id) TotalOrders,
    sum(
        case
        when O.status = 'Completed' then 1
        else 0
        end
        ) Completed,
    sum(
        case
        when O.status = 'Cancelled' then 1
        else 0
        end
        ) Cancelled,
    sum(
        case
        when O.status = 'Returned' then 1
        else 0
        end
        ) Returned,
    cast((sum(
        case
        when O.status = 'Cancelled' then 1
        else 0
        end
        )+
    sum(
        case
        when O.status = 'Returned' then 1
        else 0
        end
        )) *100.0/count(O.order_id) as decimal(6,2)) 'NonCompletd%'
from Customers C
left join Orders O
    on C.customer_id = O.customer_id
group by C.country
Order by 'NonCompletd%' desc

--better version
SELECT
    C.country,
    COUNT(O.order_id) AS TotalOrders,

    SUM(CASE
        WHEN O.status = 'Completed' THEN 1
        ELSE 0
    END) AS Completed,

    SUM(CASE
        WHEN O.status = 'Cancelled' THEN 1
        ELSE 0
    END) AS Cancelled,

    SUM(CASE
        WHEN O.status = 'Returned' THEN 1
        ELSE 0
    END) AS Returned,

    CAST(
        SUM(CASE
            WHEN O.status IN ('Cancelled', 'Returned') THEN 1
            ELSE 0
        END) * 100.0
        / COUNT(O.order_id)
        AS DECIMAL(6,2)
    ) AS NonCompletedPct

FROM Customers C
JOIN Orders O
    ON C.customer_id = O.customer_id

GROUP BY C.country

ORDER BY NonCompletedPct DESC;

--using CTE(Common Table Expression)
with CountryOfOrder as
    (
     select 
        C.country,
        count(O.order_id) TotalOrders,
        sum(
            case
            when O.status = 'Completed' then 1
            else 0
            end
        ) Completed,
        sum(
            case
            when O.status = 'Cancelled' then 1
            else 0
            end
        ) Cancelled,
        sum(
            case
            when O.status = 'Returned' then 1
            else 0
            end
        ) Returned
     from Customers C
     join Orders O 
        on C.customer_id = O.customer_id
     group by C.country
     )
select
    country,
    TotalOrders,
    Completed,
    Cancelled,
    Returned,
    cast(
        (Returned+Cancelled) *100.0
        / nullif(TotalOrders,0)
        as decimal (6,2)
    ) [NonCompleted%]
from CountryOfOrder;


--ANALYSIS 23 — Germany Investigation
--Since Germany has the highest non-completed rate, let's drill into it.
--Business question
--For each country, what percentage of orders are Cancelled vs Returned?

with CustomerOrder as
(
    select
        C.country,
        count(O.order_id) TotalOrders,
        sum(
            case
            when O.status = 'Cancelled' then 1
            else 0
            end
        ) Cancelled,
        sum(
            case
            when O.status = 'Returned' then 1
            else 0
            end
        ) Returned
    from Customers C
    join Orders O
        on C.customer_id = O.customer_id
    group by C.country
)
select
    country,
    cast(
         Cancelled * 100.0
         /nullif(TotalOrders,0)
         as decimal(6,2)
    ) CancelledPct,
    cast(
        Returned * 100.0
        /TotalOrders
        as decimal(6,2)
    ) ReturnedPct
from CustomerOrder

--simpler version
SELECT
    C.country,

    CAST(
        SUM(CASE WHEN O.status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(O.order_id)
        AS DECIMAL(6,2)
    ) AS CancelledPct,

    CAST(
        SUM(CASE WHEN O.status = 'Returned' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(O.order_id)
        AS DECIMAL(6,2)
    ) AS ReturnedPct

FROM Customers C
JOIN Orders O
    ON C.customer_id = O.customer_id

GROUP BY C.country

ORDER BY ReturnedPct DESC;


--ANALYSIS 24 — Product Performance
--Which individual products generate the most completed-order revenue, and how many units of each product were sold?
select
    OI.product_id,
    P.product_name,
    P.category,
    sum(OI.price*OI.quantity) Revenue,
    sum(OI.quantity) NumOfUnitsSold
from OrderItems OI
join Orders O
    on OI.order_id = O.order_id
join Products P
    on P.product_id = OI.product_id
where O.status = 'Completed'
group by 
    OI.product_id,
    P.category,
    P.product_name
order by Revenue desc


--ANALYSIS 25 — Units vs Revenue
--Which products sell the most units, and are those the same products that generate the most revenue?
select 
    P.product_id,
    P.product_name,
    P.category,
    sum(OI.quantity) NumOfUnits,
    sum(OI.quantity*OI.price) Revenue
from Orders O
join OrderItems OI
    on OI.order_id = O.order_id
join Products P
    on P.product_id = OI.product_id
where O.status = 'Completed'
group by 
    P.product_id,
    P.product_name,
    P.category
order by NumOfUnits desc


--ANALYSIS 26 — Product Price / Revenue Efficiency
/*We know: Product 45 → 154 units, $9,644
           Product 16 → 135 units, $9,732
So,Which products generate the highest revenue per unit sold?*/

select 
    distinct P.product_id,
    P.product_name,
    P.category,
    OI.price UnitPrice
from Products P
join OrderItems OI
    on P.product_id = OI.product_id
join Orders O
    on O.order_id = OI.order_id
where O.status = 'Completed'
order by OI.price Desc

--Does every product have one consistent unit price, or are there products whose price changes across orders?
select 
    P.product_id,
    P.product_name,
    P.category,
    Min(OI.price) MinimumPrice,
    Max(OI.price) MaximumPrice
from Products P
join OrderItems OI
    on P.product_id = OI.product_id
join Orders O
    on O.order_id = OI.order_id
where O.status = 'Completed'
group by 
    P.product_id,
    P.product_name,
    P.category

select 
    O.order_id,
    P.product_id,
    P.product_name,
    P.category,
    OI.quantity,
    OI.price,
    O.customer_id,
    O.order_date
from Products P
join OrderItems OI
    on P.product_id = OI.product_id
join Orders O
    on O.order_id = OI.order_id
where O.status = 'Completed' and P.product_id = 23

--as we did the analysis found out that the same product is sold at different price over the time in the year
--so the question is changed to
--Which products had the highest average realized selling price per unit among completed orders?
--product_id | product_name | category | UnitsSold | Revenue | AvgPricePerUnit
select 
    P.product_id,
    P.product_name,
    P.category,
    sum(OI.quantity) UnitSold,
    sum(OI.price*OI.quantity) Revenue,
    cast(
        sum(OI.price*OI.quantity) * 1.0
        /sum(OI.quantity)
        as decimal(6,2)
    ) AvgPricePerUnit
from Products P
join OrderItems OI
    on OI.product_id = P.product_id
join Orders O
    on O.order_id = OI.order_id
where O.status = 'Completed'
group by 
    P.product_id,
    P.product_name,
    P.category
order by AvgPricePerUnit desc
--Product 50 has the highest average realized price per unit, but it isn't anywhere near the top in total revenue.
--Revenue depends on both price AND volume.


--We now have three different ways of defining "best":
--Highest revenue: Product 16 — $9,732
--Highest volume: Product 45 — 154 units
--Highest average realized price/unit: Product 50 — $76.04
--Three different products.

--ANALYSIS 27 — Product Volume vs Revenue
--Which products sell a high volume of units but generate relatively low revenue,
--and which products generate high revenue despite lower sales volume?

WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS TotalQuantity,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Products P
    JOIN OrderItems OI
        ON P.product_id = OI.product_id
    JOIN Orders O
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY
        P.product_id,
        P.product_name,
        P.category
)
SELECT
        MIN(TotalQuantity) AS MinQuantity,
        MAX(TotalQuantity) AS MaxQuantity,
        MIN(TotalRevenue) AS MinRevenue,
        MAX(TotalRevenue) AS MaxRevenue
    FROM ProductMetrics;
--this wasnt the expected output

WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS TotalQuantity,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Products P
    JOIN OrderItems OI
        ON P.product_id = OI.product_id
    JOIN Orders O
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY
        P.product_id,
        P.product_name,
        P.category
),
TopUnits AS
(
    SELECT TOP 10 *
    FROM ProductMetrics
    ORDER BY TotalQuantity DESC
),
TopRevenue AS
(
    SELECT TOP 10 *
    FROM ProductMetrics
    ORDER BY TotalRevenue DESC
)
SELECT
    TU.product_id,
    TU.product_name,
    TU.category,
    TU.TotalQuantity,
    TU.TotalRevenue
FROM TopUnits TU
LEFT JOIN TopRevenue TR
    ON TU.product_id = TR.product_id
WHERE TR.product_id IS NULL;

-- using window function
WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS TotalQuantity,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Products P
    JOIN OrderItems OI
        ON P.product_id = OI.product_id
    JOIN Orders O
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
            ORDER BY TotalQuantity DESC
        ) AS UnitRank,

        ROW_NUMBER() OVER (
            ORDER BY TotalRevenue DESC
        ) AS RevenueRank

    FROM ProductMetrics
)

SELECT
    product_id,
    product_name,
    category,
    TotalQuantity,
    TotalRevenue,
    UnitRank,
    RevenueRank
FROM ProductRanks
WHERE UnitRank <= 10
   OR RevenueRank <= 10
ORDER BY UnitRank;

--2
WITH ProductMetrics AS
(
    SELECT
        P.product_id,
        P.product_name,
        P.category,
        SUM(OI.quantity) AS TotalQuantity,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Products P
    JOIN OrderItems OI
        ON P.product_id = OI.product_id
    JOIN Orders O
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
            ORDER BY TotalQuantity DESC
        ) AS UnitRank,

        ROW_NUMBER() OVER (
            ORDER BY TotalRevenue DESC
        ) AS RevenueRank
    FROM ProductMetrics
)

SELECT
    product_id,
    product_name,
    category,
    TotalQuantity,
    TotalRevenue,
    UnitRank,
    RevenueRank
FROM ProductRanks
WHERE UnitRank <= 10
  AND RevenueRank > 10
ORDER BY UnitRank;


--ANALYSIS 28 — Customer Purchase Frequency vs Revenue
--Do customers who place more orders necessarily generate more revenue?
/*customer_id
TotalOrders -- count(order_id)
TotalRevenue -- quantity x price
AOV*/ -- (quantity x price)/no. of orders

select 
    C.customer_id, 
    count(distinct O.order_id) TotalOrders,
    sum(OI.quantity*OI.price) Revenue,
    cast(
        sum(OI.quantity*OI.price)*1.0
        /count(distinct O.order_id) 
        as decimal(6,2) 
       )AOV
from Customers C
join Orders O
    on C.customer_id = O.customer_id   
join OrderItems OI
    on O.order_id = OI.order_id
where O.status = 'Completed'
group by C.customer_id
order by TotalOrders Desc


--ANALYSIS 29 — Who are our highest-value customers?
--Which customers generate the most total completed-order revenue?
select 
    C.customer_id,
    C.country,
    sum(OI.price*OI.quantity) TotalRevenue
from Customers C
join Orders O
    on C.customer_id = O.customer_id 
join OrderItems OI
    on OI.order_id = O.order_id
join Products P
    on P.product_id = OI.product_id
where O.status = 'Completed'
group by C.customer_id,
    C.country
order by TotalRevenue desc


--ANALYSIS 30 — High Revenue ≠ High AOV
--Which customers generate high total revenue despite having a relatively low Average Order Value?
select 
    C.customer_id,
    count(distinct O.order_id) TotalOrders,
    sum(OI.quantity*OI.price) TotalRevenue,
    cast(
        sum(OI.quantity*OI.price) *1.0
        /count(distinct O.order_id)
        as decimal(6,2)
    ) AOV
from Customers C
join Orders O
    on O.customer_id = C.customer_id
join OrderItems OI
    on OI.order_id = O.order_id
where O.status = 'Completed'
group by C.customer_id
order by TotalRevenue desc
-- so the ans is 39

--ANALYSIS 31 — Customer Loyalty vs Customer Value
--Which customers have both a high number of completed orders AND high total revenue?
with CustomerDetails as(
    select 
        C.customer_id,
        count(distinct O.order_id) TotalOrders,
        sum(OI.quantity*OI.price) TotalRevenue
    from Customers C
    join Orders O
        on C.customer_id = O.customer_id
    join OrderItems OI
        on OI.order_id = O.order_id
    where O.status = 'Completed'
    group by C.customer_id
),
CustomerRanking as (
    select *,
    ROW_NUMBER() over(
        order by TotalOrders desc
    ) OrderRank,
    ROW_NUMBER() over(
        order by TotalRevenue desc
    ) RevenueRank
    from CustomerDetails
)
SELECT *
FROM CustomerRanking
WHERE OrderRank <= 10
  AND RevenueRank <= 10

--actual answer
WITH CustomerDetails AS
(
    SELECT
        C.customer_id,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Customers C
    JOIN Orders O
        ON C.customer_id = O.customer_id
    JOIN OrderItems OI
        ON OI.order_id = O.order_id
    WHERE O.status = 'Completed'
    GROUP BY C.customer_id
)
SELECT
    AVG(TotalOrders) AS AverageOrders,
    AVG(TotalRevenue) AS AverageRevenue
FROM CustomerDetails;
--how does this becomes the answer for,
--Which customers have both a high number of completed orders AND high total revenue?yes its actually the progression for the final ans
WITH CustomerDetails AS
(
    SELECT
        C.customer_id,
        COUNT(DISTINCT O.order_id) AS TotalOrders,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Customers C
    JOIN Orders O
        ON C.customer_id = O.customer_id
    JOIN OrderItems OI
        ON OI.order_id = O.order_id
    WHERE O.status = 'Completed'
    GROUP BY C.customer_id
)

SELECT
    customer_id,
    TotalOrders,
    TotalRevenue,
    CAST(
        TotalRevenue * 1.0 / TotalOrders
        AS DECIMAL(10,2)
    ) AS AOV
FROM CustomerDetails
WHERE TotalOrders >
      (
          SELECT AVG(TotalOrders)
          FROM CustomerDetails
      )
  AND TotalRevenue >
      (
          SELECT AVG(TotalRevenue)
          FROM CustomerDetails
      )
ORDER BY TotalRevenue DESC;

--ANALYSIS 32 — Repeat Customers vs One-Time Customers
--Do repeat customers generate a larger share of our completed revenue than one-time customers?

select *
from OrderItems;

with CustomerType as(
    select 
        O.customer_id,
        sum(OI.quantity * OI.price) Rvenue,
        CASE
             WHEN COUNT(O.order_id) = 1 THEN 'One-Time'
             ELSE 'Repeat'
        END AS CustomerType
    from Orders O
    join OrderItems OI
        on O.order_id = OI.order_id
    where status = 'Completed'
    group by O.customer_id
)
select 
    CustomerType,
    sum(Rvenue)
from CustomerType
group by CustomerType;
--polished version
WITH CustomerType AS
(
    SELECT
        O.customer_id,
        CASE
            WHEN COUNT(O.order_id) = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS CustomerType
    FROM Orders O
    GROUP BY O.customer_id
),
RevenueByType AS
(
    SELECT
        CT.CustomerType,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM CustomerType CT
    JOIN Orders O
        ON CT.customer_id = O.customer_id
    JOIN OrderItems OI
        ON O.order_id = OI.order_id
    WHERE O.status = 'Completed'
    GROUP BY CT.CustomerType
)
SELECT
    CustomerType,
    TotalRevenue,
    CAST(
        TotalRevenue * 100.0 /
        SUM(TotalRevenue) OVER()
        AS decimal(6,2)
    ) AS RevenuePercentage
FROM RevenueByType
ORDER BY TotalRevenue DESC;

--Analysis 33 — Do repeat customers make up most of our customer base?
--What percentage of customers are repeat customers versus one-time customers?
WITH CustomerOrders AS
(
    SELECT
        customer_id,
        COUNT(order_id) AS TotalOrders
    FROM Orders
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN TotalOrders = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END AS CustomerType,
    COUNT(*) AS CustomerCount,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS decimal(6,2)
    ) AS CustomerPercentage
FROM CustomerOrders
GROUP BY
    CASE
        WHEN TotalOrders = 1 THEN 'One-Time'
        ELSE 'Repeat'
    END
ORDER BY CustomerCount DESC;

--Analysis 34 — Which customer has the highest AOV?
--Which customer generates the highest Average Order Value among completed orders?
SELECT TOP 1
    O.customer_id,
    COUNT(DISTINCT O.order_id) AS TotalOrders,
    SUM(OI.quantity * OI.price) AS TotalRevenue,
    CAST(
        SUM(OI.quantity * OI.price) * 1.0
        / COUNT(DISTINCT O.order_id)
        AS decimal(10,2)
    ) AS AOV
FROM Orders O
JOIN OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY O.customer_id
ORDER BY AOV DESC;

--Analysis 35 — Which product generates the most revenue?
--Which product generates the highest completed-order revenue?
SELECT TOP 1
    P.product_id,
    P.product_name,
    P.category,
    SUM(OI.quantity) AS UnitsSold,
    SUM(OI.quantity * OI.price) AS Revenue
FROM Products P
JOIN OrderItems OI
    ON P.product_id = OI.product_id
JOIN Orders O
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY
    P.product_id,
    P.product_name,
    P.category
ORDER BY Revenue DESC;

--Analysis 36 — Which country generates the most revenue?
--Which country generates the highest total completed-order revenue?
SELECT
    C.country,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM Customers C
JOIN Orders O
    ON C.customer_id = O.customer_id
JOIN OrderItems OI
    ON O.order_id = OI.order_id
WHERE O.status = 'Completed'
GROUP BY C.country
ORDER BY TotalRevenue DESC;

--Analysis 37 — Which category generates the most revenue?
--Which product category generates the highest completed-order revenue?
SELECT
    P.category,
    SUM(OI.quantity * OI.price) AS TotalRevenue
FROM Orders O
JOIN OrderItems OI
    ON O.order_id = OI.order_id
JOIN Products P
    ON OI.product_id = P.product_id
WHERE O.status = 'Completed'
GROUP BY P.category
ORDER BY TotalRevenue DESC;

--Analysis 38 — What's the overall order completion rate?
--What percentage of all orders are successfully completed?
SELECT
    COUNT(order_id) AS TotalOrders,

    SUM(
        CASE
            WHEN status = 'Completed' THEN 1
            ELSE 0
        END
    ) AS CompletedOrders,

    CAST(
        SUM(
            CASE
                WHEN status = 'Completed' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id)
        AS decimal(6,2)
    ) AS CompletionRate
FROM Orders;

--Analysis 39 — Final customer revenue concentration
--What percentage of completed revenue comes from the top 10 customers?
WITH CustomerRevenue AS
(
    SELECT
        O.customer_id,
        SUM(OI.quantity * OI.price) AS TotalRevenue
    FROM Orders O
    JOIN OrderItems OI
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
            ORDER BY TotalRevenue DESC
        ) AS RevenueRank
    FROM CustomerRevenue
)
SELECT
    SUM(
        CASE
            WHEN RevenueRank <= 10
            THEN TotalRevenue
            ELSE 0
        END
    ) AS Top10Revenue,

    SUM(TotalRevenue) AS TotalRevenue,

    CAST(
        SUM(
            CASE
                WHEN RevenueRank <= 10
                THEN TotalRevenue
                ELSE 0
            END
        ) * 100.0 / SUM(TotalRevenue)
        AS decimal(6,2)
    ) AS Top10RevenuePercentage
FROM RankedCustomers;

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
