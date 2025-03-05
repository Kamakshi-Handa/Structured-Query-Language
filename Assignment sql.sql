use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/		
SELECT DATE_FORMAT(o.Order_Date, '%Y-%m') AS Month, 
       SUM(ord.Quantity) AS Quantities_Sold,
       SUM(ord.Sales) AS Sales
FROM orders AS o
LEFT JOIN ordered_items AS ord 
    ON o.Order_Id = ord.Order_Id
LEFT JOIN product_info AS p 
    ON ord.Item_Id = p.Product_Id
WHERE LOWER(p.Product_Name) LIKE '%nike%'
GROUP BY DATE_FORMAT(o.Order_Date, '%Y-%m')
ORDER BY DATE_FORMAT(o.Order_Date, '%Y-%m') ;




-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.


*/
SELECT p.Product_Id, p.Product_Name, c.Name AS Category_Name, d.Name AS Department_Name, p.Product_Price
FROM department AS d
LEFT JOIN product_info AS p ON d.Id = p.Department_Id
LEFT JOIN category AS c ON p.Category_Id = c.Id
ORDER BY p.Product_Price DESC
LIMIT 5;

-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.


*/
select p.Product_Name, sum(ord.Sales) as total_sales , count(distinct(o.Order_Id)) as Order_Count
from orders as o
left join ordered_items as ord
on o.Order_Id=ord. Order_Id 
left join product_info as p
on ord.Item_id=p.Product_id
where o.type='CASH'
group by p.Product_Name
order by Order_count desc, total_sales desc
limit 10;

-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/

select * from orders as o
inner join customer_info as c
on o.Customer_Id=c.Id
WHERE c.State = 'TX'
  AND c.Street LIKE '%Plaza%'
  AND c.Street NOT LIKE '%Mountain%'
order by o.Order_id;
-- select State from customer_info;

-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/
select count(o.Order_Id) as Order_Count, SUM(ord.Quantity*p.Product_Price) as total_amount
 from orders as o
inner join customer_info as c
on o.Customer_Id=c.Id
inner join ordered_items as ord
on o.Order_Id=ord.Order_Id
inner join product_info as p 
on Ord.Item_Id=p.Product_Id
inner join department as d
on d.Id=p.Department_Id
where c.Segment ='Home Office'
and d.Name in ('apparel' , 'outdoors');

-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/
with customertable as(
select count(o.Order_Id) as Order_Count,
	   o.Order_State as Order_State,
	   o.Order_City as Order_City
 from orders as o
inner join customer_info as c
on o.Customer_Id=c.Id
inner join ordered_items as ord
on o.Order_Id=ord.Order_Id
inner join product_info as p 
on Ord.Item_Id=p.Product_Id
inner join department as d
on d.Id=p.Department_Id
where c.Segment ='Home Office'
and d.Name in ('apparel' , 'outdoors')
group by Order_state,
Order_City
)
select Order_State,
    Order_City,
    Order_Count,
	DENSE_RANK() OVER (PARTITION BY Order_State ORDER BY Order_Count desc, Order_City ASC) AS City_Rank
    From customertable
    ORDER BY Order_State ASC, City_rank;
 -- at the ned order by ensures that the states are displayed in alphabetical order.
 -- in orderby clause of dense_rank, aggregate function and alias cannot be directly used.
 -- or it can be done as   
 
-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.


*/

-- **********************************************************************************************************************************

SELECT 
    o.Shipping_Mode AS Shipping_Mode,
    COUNT(o.Order_Id) AS Shipping_Underestimated_Order_Count,
    ROW_NUMBER() OVER (
        PARTITION BY YEAR(o.Order_Date) 
        ORDER BY COUNT(o.Order_Id) DESC, o.Shipping_Mode ASC
    ) AS Shipping_Mode_Rank
FROM orders AS o
INNER JOIN customer_info AS c
    ON o.Customer_Id = c.Id
WHERE o.Scheduled_Shipping_Days < o.Real_Shipping_Days
    AND o.Order_Status IN ('Complete', 'Closed')
    AND c.Segment = 'Consumer'
GROUP BY o.Shipping_Mode, YEAR(o.Order_Date)
ORDER BY YEAR(o.Order_Date), Shipping_Mode_Rank;



/* Question : Golf related products

List all products in categories related to golf. Display the Product_Id, Product_Name in the output. Sort the output in the order of product id.
Hint: You can identify a Golf category by the name of the category that contains golf.

*/


SELECT p.Product_Name, p.Product_Id FROM
product_info AS p
INNER JOIN category AS c 
ON p.Category_id = c.Id 
WHERE c.Name LIKE '%GOLF%' 
ORDER BY p.Product_Id; 




/*
Question : Most sold golf products

Find the top 10 most sold products (based on sales) in categories related to golf. Display the Product_Name and Sales column in the output. Sort the output in the descending order of sales.
Hint: You can identify a Golf category by the name of the category that contains golf.

HINT:
Use orders, ordered_items, product_info, and category tables from the Supply chain dataset.


*/
Select sum(o.Sales) as Sales , p.Product_Name
from ordered_items as o 
inner join product_info as p
on o.Item_Id= p.Product_Id 
inner join category as c
on p.Category_Id = c.Id
WHERE c.Name LIKE '%GOLF%' 
group by p.Product_Name
order by Sales desc
limit 10;



/*
Question: Segment wise orders
Find the number of orders by each customer segment for orders. Sort the result from the highest to the lowest 
number of orders.The output table should have the following information:
-Customer_segment
-Orders
*/

select c.Segment as customer_Segment, Count(o.Order_Id) as Orders
from customer_info as c 
inner join orders as o
on c.Id= o.Customer_Id
group by c.Segment
order by Orders desc ;





/*
Question : Percentage of order split
Description: Find the percentage of split of orders by each customer segment for orders that took six days 
to ship (based on Real_Shipping_Days). Sort the result from the highest to the lowest percentage of split orders,
rounding off to one decimal place. The output table should have the following information:
-Customer_segment
-Percentage_order_split
HINT:
Use the orders and customer_info tables from the Supply chain dataset.
*/
-- **********************************************************************************************************************************
SELECT 
    c.Segment,
    ROUND((COUNT(o.Order_ID) * 100.0) / (SELECT COUNT(*) 
    FROM orders WHERE Real_Shipping_Days = 6), 1) AS Percentage_order_split
FROM 
    orders o
JOIN 
    customer_info c ON o.Customer_ID = c.ID
WHERE 
    o.Real_Shipping_Days = 6
GROUP BY 
    c.Segment
ORDER BY 
    Percentage_order_split DESC;


