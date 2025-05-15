-- Redaing all the tables from the Database. 

SELECT * FROM bike_sales.tbl_stg_customers;
SELECT * FROM bike_sales.tbl_stg_prd;
SELECT * FROM bike_sales.tbl_stg_prdcat;
SELECT * FROM bike_sales.tbl_stg_prdsubcat;
SELECT * FROM bike_sales.tbl_stg_sales_2015;
SELECT * FROM bike_sales.tbl_stg_sales_2016;
SELECT * FROM bike_sales.tbl_stg_sales_2017;
SELECT * FROM bike_sales.tbl_stg_territory;


/*Overall Sales Analysis:*/

-- o Which year has the maximum number of orders (2015, 2016, 2017)?

with sales as
(select * from tbl_stg_sales_2015
union
select * from tbl_stg_sales_2016
union
select * from tbl_stg_sales_2017)
select year(OrderDate) as yearly_sales, sum(OrderQuantity) as total_orders
from sales
group by year(OrderDate)
order by sum(OrderQuantity) desc;

-- From 2015 to 2017 the number of orders have increased substantially. 
-- 2017	45314
-- 2016	36230
-- 2015	2630


-- o What are the total sales for each year (2015, 2016, 2017)?

create view Sales_15_16_17
as (Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity
from tbl_stg_sales_2015
union
Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity
from tbl_stg_sales_2016
union
Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity
from tbl_stg_sales_2017);

select * from Sales_15_16_17;

-- Created a table for all the sales from 2015-2017 for convenience

create view Com_Profit 
as (select ProductSubcategoryKey, CustomerKey, ProductName, ModelName, ProductColor, ProductSize, ProductStyle, ProductPrice, ProductCost, OrderQuantity,  (ProductPrice*OrderQuantity) as Total_SP, (ProductCost*OrderQuantity) as Total_CP, round((ProductPrice - ProductCost)*OrderQuantity, 4) as Total_Profit
from sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey);

select * from Com_Profit;

-- We are also creating a Profit table with Order Quantities taken into account for accurate Revenue/Sales calculation

select year(OrderDate) as Sales_Year, round(sum(Total_SP), 2) as Sales_Each_Year
from Sales_15_16_17 s inner join Com_Profit p
on s.CustomerKey = p.CustomerKey
group by year(OrderDate)
order by round(sum(Total_SP), 2) desc;

-- From this we can see that sales is the most in 2017>2016>2015

-- o How has the sales trend changed over the years?

-- To figure out the sales trend we must check sales for each year on a monthly basis. 

select month(OrderDate) as Monthly_Sales, year(OrderDate) as Sales_Year, round(sum(Total_SP), 2) as Sales_Each_Month_Per_Year,
row_number() over(partition by year(OrderDate) order by round(sum(Total_SP), 2) desc) as Monthly_Sales_Trend
from Sales_15_16_17 s inner join Com_Profit p
on s.CustomerKey = p.CustomerKey
group by month(OrderDate), year(OrderDate); 

-- o What is the average sales per year?

select year(OrderDate) as Sales_Year, round(avg(Total_SP), 2) as Average_Sales_per_Year
from Sales_15_16_17 s inner join Com_Profit p
on s.CustomerKey = p.CustomerKey
group by year(OrderDate)
order by round(avg(Total_SP), 2) desc;

-- Average Sales is the highest in the year 2015
-- 2015 > 2016 > 2017

/*Sales by Product Category*/

-- o What are the total sales by product category?

select CategoryName, round(sum(Total_SP), 3) as Most_Sales_by_Product_Category
from tbl_stg_prdcat c inner join tbl_stg_prdsubcat s on c.ProductCategoryKey = s.ProductCategoryKey
inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
group by CategoryName
order by round(sum(Total_SP), 3) desc;

-- Total sales by product category: Bike > Accessories > Clothing

-- o Which product category contributed the most to the sales in each year?

select year(OrderDate) as Sales_Year, CategoryName, round(sum(Total_SP), 3) as Most_Sales_by_Product_Category, 
row_number() over(partition by year(OrderDate) order by round(sum(Total_SP), 3) desc) as PCategory_Highest_Sales_Per_Year
from tbl_stg_prdcat c inner join tbl_stg_prdsubcat s on c.ProductCategoryKey = s.ProductCategoryKey
inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
inner join Sales_15_16_17 a on  p.CustomerKey = a.CustomerKey
group by year(OrderDate), CategoryName;


-- o How have sales in each category changed over the years?

select year(OrderDate) as Sales_Year, CategoryName, round(sum(Total_SP), 3) as Most_Sales_by_Product_Category, 
row_number() over(partition by CategoryName order by round(sum(Total_SP), 3) desc) as PCategory_Highest_Sales_Per_Year
from tbl_stg_prdcat c inner join tbl_stg_prdsubcat s on c.ProductCategoryKey = s.ProductCategoryKey
inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
inner join Sales_15_16_17 a on  p.CustomerKey = a.CustomerKey
group by year(OrderDate), CategoryName;


/* Sales by Product Sub-category */

-- o What are the top 5 total sales by product sub-category?

with Top_5_Prd_SubCategory as 
(select SubcategoryName, round(sum(Total_SP), 3) as Most_Sales_by_Product_Sub_Category,
row_number() over(order by round(sum(Total_SP), 3) desc) as Top_5_Highest_Sales_Rank
from tbl_stg_prdsubcat c inner join Com_Profit p on c.ProductSubcategoryKey = p.ProductSubcategoryKey
group by SubcategoryName)
select *
from Top_5_Prd_SubCategory
where Top_5_Highest_Sales_Rank <= 5;

-- o Which product sub-category had the highest sales for each year?

with Highest_Sales as
(select year(OrderDate) as Sales_Year, SubcategoryName, round(sum(Total_SP), 3) as Highest_Sales_by_Product_SubCategory_Per_Year,
row_number() over(partition by year(OrderDate) order by round(sum(Total_SP), 3) desc) as PSubCategory_Highest_Sales_Rank
from tbl_stg_prdsubcat c inner join Com_Profit p on c.ProductSubcategoryKey = p.ProductSubcategoryKey
inner join Sales_15_16_17 a on  p.CustomerKey = a.CustomerKey
group by year(OrderDate), SubcategoryName)
select *
from Highest_Sales
where PSubCategory_Highest_Sales_Rank = 1;

-- 2015	Road Bikes	
-- 2016	Road Bikes	
-- 2017	Mountain Bikes

/* Sales by Region */

-- o What are the total sales by region?

-- Since, there is no common column to connect on therefore we will convert the SalesTerritoryKey into TerritoryKey for joining.

create view tbl_stg_region
as (select SalesTerritoryKey as TerritoryKey, Region, Country, Continent
from tbl_stg_territory);

select *
from tbl_stg_region;

with sales as
(select * from tbl_stg_sales_2015
union
select * from tbl_stg_sales_2016
union
select * from tbl_stg_sales_2017)
select Region, round(sum(Total_SP), 3) as Most_Sales_by_Region
from sales s inner join Com_Profit p on s.CustomerKey = p.CustomerKey
inner join tbl_stg_region r on s.TerritoryKey = r.TerritoryKey
group by Region
order by round(sum(Total_SP), 3) desc;

-- o Which region contributed the most to the sales for each year?

with Region_with_most_sales as
(with sales as
(select * from tbl_stg_sales_2015
union
select * from tbl_stg_sales_2016
union
select * from tbl_stg_sales_2017)
select year(OrderDate) as Sales_Year, Region, round(sum(Total_SP), 3) as Most_Sales_by_Region,
row_number() over(partition by year(OrderDate) order by round(sum(Total_SP), 3) desc) as Region_Highest_Sales_per_year_Rank
from sales s inner join Com_Profit p on s.CustomerKey = p.CustomerKey
inner join tbl_stg_region r on s.TerritoryKey = r.TerritoryKey
group by year(OrderDate), Region)
select *
from Region_with_most_sales
where Region_Highest_Sales_per_year_Rank = 1;

-- 2015	Australia	
-- 2016	Australia	     Insights: Every year Australia ranked No. 1 in sales
-- 2017	Australia	


/* Customer Analysis */

-- o Which top 3 customers made the highest number of orders in each year?

select * from Sales_15_16_17;
SELECT * FROM bike_sales.tbl_stg_customers;
SELECT * FROM bike_sales.tbl_stg_prd;

with Cust_ord_q as
(select concat(FirstName, ' ', LastName) as Full_Name, year(OrderDate) as Sales_Year, sum(OrderQuantity) as Most_Orders,
row_number() over (partition by year(OrderDate) order by sum(OrderQuantity) desc) as Ranked_Highest_orders_each_year
from tbl_stg_customers c inner join Sales_15_16_17 s
on c.CustomerKey = s.CustomerKey
group by year(OrderDate), Full_Name)
select * 
from Cust_ord_q
where Ranked_Highest_orders_each_year <= 3;


-- RAFAEL XU	    2015	2	1
-- ANDY VAZQUEZ	    2015	1	2     Top 3 customers with most number of orders in 2015
-- MARIAH BARNES	2015	1	3

-- SAMANTHA JENKINS	2016	62	1
-- MASON ROBERTS	2016	55	2     Top 3 customers with most number of orders in 2016
-- APRIL SHAN	    2016	54	3

-- JENNIFER SIMMONS	2017	74	1
-- FERNANDO BARNES	2017	74	2     Top 3 customers with most number of orders in 2017
-- ASHLEY HENDERSON	2017	72	3


-- o Which are the top 10 customers with the most sales?

with Top_10_Customers_with_Highest_sales as
(select concat(FirstName, ' ', LastName) as Full_Name, round(sum(Total_SP), 3) as Customers_with_Highest_sales, 
Row_number() over(order by round(sum(Total_SP), 3) desc) as Ranked_Top_10_Customers
from tbl_stg_customers c inner join Com_Profit p on c.CustomerKey = p.CustomerKey
group by Full_Name)
select * 
from Top_10_Customers_with_Highest_sales
where Ranked_Top_10_Customers <= 10;


-- o What are the top 10 customers with highest annual income, and are they coming under the top 10 list of customers with most sales?

with Ranked as
(select concat(FirstName, ' ', LastName) as Full_Name, Gender, AnnualIncome as Top_10_Customers_with_Highest_Annual_Income,
row_number() over (order by AnnualIncome) as Ranked_Top_10_Customers
from tbl_stg_customers)
select *
from Ranked
where Ranked_Top_10_Customers <= 10;

-- Insight: None of the top ten customers with highest annual income are in the list of top ten contributers in sales. 

-- o How does the customer base compare across different regions?

select *
from tbl_stg_region;
SELECT * FROM bike_sales.tbl_stg_customers;
SELECT * FROM bike_sales.tbl_stg_sales_2015;
SELECT * FROM bike_sales.tbl_stg_sales_2016;
SELECT * FROM bike_sales.tbl_stg_sales_2017;


with sales_table as
(select * from tbl_stg_sales_2015
union
select * from tbl_stg_sales_2016
union
select * from tbl_stg_sales_2017)
select Region, count(FirstName) as Number_of_Customers_based_on_region,  
row_number() over(order by count(FirstName) desc) as Ranked_Highest_customerbase
from tbl_stg_region r inner join sales_table s on r.TerritoryKey = s.TerritoryKey
inner join  tbl_stg_customers c on s.CustomerKey = c.CustomerKey
group by Region;

-- We can see that Australia Ranks number 1 in the largest customer base. 

-- Australia	    12409	1
-- Southwest     	11463	2
-- Northwest	    8267	3
-- Canada	        6875	4
-- United Kingdom	6423	5
-- Germany	        5289	6
-- France	        5239	7
-- Southeast     	34	    8
-- Northeast     	27	    9
-- Central	        20	    10

/* Time-Based Sales Analysis */

-- o What is the sales performance in each quarter of the year?

select year(OrderDate) as Sales_Year, quarter(OrderDate) as Quarterly_Sales, round(sum(Total_SP), 3) as Sales_Each_Year,
row_number() over(partition by year(OrderDate) order by round(sum(Total_SP), 3) desc) as Year_Partition
from Sales_15_16_17 s inner join Com_Profit p
on s.CustomerKey = p.CustomerKey
group by year(OrderDate), quarter(OrderDate);


/* Product Performance */

-- o What are the top 10 products that are performing best in terms of quantity sold?

select * from Sales_15_16_17;
SELECT * FROM bike_sales.tbl_stg_prd;

with Top_10 as
(select ProductName, sum(OrderQuantity) as Total_Number_of_orders,
row_number() over(order by sum(OrderQuantity) desc) as Ranked_top_10
from Sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey
group by ProductName)
select * 
from Top_10
where Ranked_top_10 <= 10;

-- Top 10 list of products with most quantities sold:

-- Water Bottle - 30 oz.	Bottles and Cages	7967	1
-- Patch Kit/8 Patches	     Tires and Tubes	5898	2
-- Mountain Tire Tube	     Tires and Tubes	5678	3
-- Road Tire Tube	         Tires and Tubes	4327	4
-- AWC Logo Cap	                        Caps	4151	5
-- Fender Set - Mountain	         Fenders	3960	6
-- Mountain Bottle Cage	    Bottles and Cages	3810	7
-- Road Bottle Cage	        Bottles and Cages	3329	8
-- Touring Tire Tube	     Tires and Tubes	2740	9
-- ML Mountain Tire	         Tires and Tubes	2119	10

-- o What is average Sales for each product category?

select CategoryName, round(avg(Total_SP), 3) as Average_Price_Per_Category
from tbl_stg_prdcat c inner join tbl_stg_prdsubcat s on c.ProductCategoryKey = s.ProductCategoryKey
inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
group by CategoryName
order by round(avg(Total_SP), 3) desc;


-- o What is Average sales price for each product Subcategory?

select SubcategoryName, round(avg(Total_SP), 3) as Average_Price_Per_Category
from tbl_stg_prdsubcat s inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
group by SubcategoryName
order by round(avg(Total_SP), 3) desc;


-- o What are the top 5 products with highest sales?

select ProductName, round(sum(Total_SP), 3) as Highest_Sales
from Com_Profit
group by ProductName
order by round(sum(Total_SP), 3) desc
limit 5;

/* Sales Comparison */

-- o What is the year-over-year growth rate for sales?

select year(OrderDate) as Sales_Year, round(sum(Total_SP), 3) as Total_Revenue
from Sales_15_16_17 s inner join Com_Profit p on s.CustomerKey = p.CustomerKey
group by year(OrderDate)
order by Sales_Year;

SELECT YEAR(OrderDate) AS Sales_Year, ROUND(SUM(Total_SP), 3) AS Total_Revenue,
ROUND(((SUM(Total_SP) - LAG(SUM(Total_SP)) OVER (ORDER BY YEAR(OrderDate))) / LAG(SUM(Total_SP)) OVER (ORDER BY YEAR(OrderDate))) * 100, 2) AS YoY_Growth_Rate
FROM Sales_15_16_17 s INNER JOIN Com_Profit p ON s.CustomerKey = p.CustomerKey
GROUP BY YEAR(OrderDate)
ORDER BY Sales_Year;

-- o How has the sales performance been trending over the last 3 months?

select * from Sales_15_16_17;
select * from tbl_stg_prd;

with Trend as
(select year(OrderDate) as Order_Year, month(OrderDate) as Orders_Month, round(sum(Total_SP)) as Monthly_Sum,
row_number() over (partition by year(OrderDate) order by month(OrderDate)) as Ranked
from sales_15_16_17 s inner join Com_Profit p on s.CustomerKey = p.CustomerKey
group by year(OrderDate), month(OrderDate)
)
select *, 
avg(Monthly_Sum) over (partition by Order_Year order by Orders_Month rows between 2 preceding and current row) as Sales_Trend_Moving_avg
from Trend;

-- o What is the change in sales on a monthly basis?

with Change_in_Monthly_Sales as
(select year(OrderDate) as Sales_year, month(OrderDate) as Sales_month, round(sum(Total_SP)) as Monthly_Total_Sales,
row_number() over (partition by year(OrderDate) order by month(OrderDate)) as Ranked
from sales_15_16_17 s inner join Com_Profit p on s.CustomerKey = p.CustomerKey
group by year(OrderDate), month(OrderDate)
)
select Sales_year, Sales_month, Monthly_Total_Sales,
Monthly_Total_Sales - lag(Monthly_Total_Sales, 1) over (order by Sales_year, Sales_month) as Change_of_sales
from Change_in_Monthly_Sales;


/* Profitability Analysis */

-- Let us create a new table with the profit column for convenience.

create view TotalProfit
as(select ProductSubcategoryKey, CustomerKey, ProductName, ModelName, ProductColor, ProductSize, ProductStyle, ProductPrice, ProductCost, OrderQuantity, round((ProductPrice - ProductCost)*OrderQuantity, 4) as Total_Profit
from sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey);

select * from TotalProfit;

-- o What are the top 5 Products that has generated the highest profit?

with Top_5_HP_Products as
(select ProductName, sum(Total_Profit) as Highest_Profit,
row_number() over(order by sum(Total_Profit) desc) Ranked_HP
from TotalProfit
group by ProductName
)
select * 
from Top_5_HP_Products
where Ranked_HP <= 5;

select * from TotalProfit;

-- o What are the profits based on product category?

select * from TotalProfit;
select * from Sales_15_16_17;
SELECT * FROM bike_sales.tbl_stg_prd;
SELECT * FROM bike_sales.tbl_stg_prdcat;
SELECT * FROM bike_sales.tbl_stg_prdsubcat;

select CategoryName, round(sum(Total_Profit), 3) as Highest_Profit_Based_on_Category,
row_number() over (order by round(sum(Total_Profit), 3) desc) as Ranked_Profit
from TotalProfit t inner join tbl_stg_prdsubcat s on t.ProductSubcategoryKey = s.ProductSubcategoryKey
inner join tbl_stg_prdcat c on s.ProductCategoryKey = c.ProductCategoryKey
group by CategoryName; 

-- o What are the profits based on product sub category?

select CategoryName, SubcategoryName, round(sum(Total_Profit), 3) as Highest_Profit_Based_on_SubCategory,
row_number() over (partition by CategoryName order by round(sum(Total_Profit), 3) desc) as Ranked_Profit
from TotalProfit t inner join tbl_stg_prdsubcat s on t.ProductSubcategoryKey = s.ProductSubcategoryKey
inner join tbl_stg_prdcat c on s.ProductCategoryKey = c.ProductCategoryKey
group by CategoryName, SubcategoryName;

-- o How have Profit in each category changed over the years?

select year(OrderDate) as Sales_Year, CategoryName, round(sum(Total_Profit), 3) as Most_Profit_by_Product_Category, 
row_number() over(partition by CategoryName order by round(sum(Total_Profit), 3) desc) as PCategory_Highest_Profit_Per_Year
from tbl_stg_prdcat c inner join tbl_stg_prdsubcat s on c.ProductCategoryKey = s.ProductCategoryKey
inner join Com_Profit p on s.ProductSubcategoryKey = p.ProductSubcategoryKey
inner join Sales_15_16_17 a on  p.CustomerKey = a.CustomerKey
group by year(OrderDate), CategoryName; 

-- o What is the Average Profit?

Select avg(Total_Profit) as Average_Profit
from TotalProfit;


select ProductName, Total_Profit, Average_Profit, 
case when Total_Profit > Average_Profit then "Above Average"
else "Below Average"
end Above_Or_Below_Avg_Profit from (
select ProductName, Total_Profit,
avg(Total_Profit) over (order by Total_Profit desc rows between unbounded preceding and unbounded following) as Average_Profit
from TotalProfit ) as Avg_Table;

with Count_Table 
as (select ProductName, Total_Profit, Average_Profit, 
case when Total_Profit > Average_Profit then "Above Average"
else "Below Average"
end Above_Or_Below_Avg_Profit from (
select ProductName, Total_Profit,
avg(Total_Profit) over (order by Total_Profit desc rows between unbounded preceding and unbounded following) as Average_Profit
from TotalProfit ) as Avg_Table
)
select Above_Or_Below_Avg_Profit, count(ProductName) as Abv_Below_Avg_Count
from Count_Table
group by Above_Or_Below_Avg_Profit
order by count(ProductName) desc;

select * from TotalProfit;
select * from Sales_15_16_17;

-- o What is the Profit% per product?

with Profit_Percent
as (select ProductSubcategoryKey, CustomerKey, ProductName, ModelName, ProductColor, ProductSize, ProductStyle, ProductPrice, ProductCost, OrderQuantity,  (ProductPrice*OrderQuantity) as Total_SP, (ProductCost*OrderQuantity) as Total_CP, round((ProductPrice - ProductCost)*OrderQuantity, 4) as Total_Profit
from sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey)
select ProductName, Total_SP, Total_CP, Total_Profit, round((Total_Profit/Total_CP)*100,2) as Profit_Percentage
from Profit_Percent
order by round((Total_Profit/Total_CP)*100,2) desc;

create view Com_Profit 
as (select ProductSubcategoryKey, CustomerKey, ProductName, ModelName, ProductColor, ProductSize, ProductStyle, ProductPrice, ProductCost, OrderQuantity,  (ProductPrice*OrderQuantity) as Total_SP, (ProductCost*OrderQuantity) as Total_CP, round((ProductPrice - ProductCost)*OrderQuantity, 4) as Total_Profit
from sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey);

select * from Com_Profit;
select * from sales_15_16_17;

-- o Total Profit each year?

select year(OrderDate) as Profit_Year, round(sum(Total_CP), 3) as TotalCP_Year, round(sum(Total_Profit), 3) as Profit_Per_year
from Com_Profit c inner join sales_15_16_17 s on c.CustomerKey = s.CustomerKey
group by year(OrderDate);

-- o Yearly Percentage of Profit?

with Yearly_PProfit
as (select year(OrderDate) as Profit_Year, round(sum(Total_CP), 3) as TotalCP_Year, round(sum(Total_Profit), 3) as Profit_Per_year
from Com_Profit c inner join sales_15_16_17 s on c.CustomerKey = s.CustomerKey
group by year(OrderDate))
select *, round((Profit_Per_year/TotalCP_Year)*100, 3) as Yearly_Profit_Percentage
from Yearly_PProfit
order by Profit_Per_year desc;

-- o Most Profitable Customers?

SELECT * FROM bike_sales.tbl_stg_customers;
select * from Com_Profit;
select * from sales_15_16_17;

select concat(FirstName, " ",LastName) as Full_Name, sum(OrderQuantity), round(sum(Total_Profit), 3) as Total_Profit_By_Customers
from Com_Profit p inner join tbl_stg_customers c on p.CustomerKey = c.CustomerKey
group by Full_Name
order by round(sum(Total_Profit), 3) desc;

/* Null values and Fraud Detection*/

-- o Customers who not placed any orders?

select c.*
from tbl_stg_customers c left join sales_15_16_17 s on c.CustomerKey = s.CustomerKey
where s.CustomerKey is null;

-- Now to Cross Verify

with O_Details
as (select concat(FirstName, " ",LastName) as Full_Name, OrderQuantity as Number_of_orders
from tbl_stg_customers c left join sales_15_16_17 s on c.CustomerKey = s.CustomerKey)
select Full_Name, Number_of_orders
from O_Details
where Number_of_orders is null;

-- Number of customers with no orders?

select count(concat(FirstName, " ",LastName)) as Count_Of_Total_Customers
from tbl_stg_customers;

with Count_Cust
as (with O_Details
as (select concat(FirstName, " ",LastName) as Full_Name, OrderQuantity as Number_of_orders
from tbl_stg_customers c left join sales_15_16_17 s on c.CustomerKey = s.CustomerKey)
select Full_Name, Number_of_orders
from O_Details
where Number_of_orders is null)
select count(Full_Name) as Number_of_Customers_with_No_Orders
from Count_Cust;


-- Number of customers with only one order?

with O_Details
as (select concat(FirstName, " ",LastName) as Full_Name, OrderQuantity as Number_of_orders
from tbl_stg_customers c left join sales_15_16_17 s on c.CustomerKey = s.CustomerKey)
select distinct Full_Name, Number_of_orders
from O_Details
where Number_of_orders = 1;

with count_of_1
as (with O_Details
as (select concat(FirstName, " ",LastName) as Full_Name, OrderQuantity as Number_of_orders
from tbl_stg_customers c left join sales_15_16_17 s on c.CustomerKey = s.CustomerKey)
select distinct Full_Name, Number_of_orders
from O_Details
where Number_of_orders = 1)
select count(Full_Name) as Count_of_customers_with_1_order
from count_of_1;

-- End--


create view New_Profit_Table 
as (select ProductSubcategoryKey, CustomerKey, ProductName, ModelName, ProductColor, ProductSize, ProductStyle, ProductPrice, ProductCost, OrderQuantity,  (ProductPrice*OrderQuantity) as Total_SP, (ProductCost*OrderQuantity) as Total_CP, round((ProductPrice - ProductCost)*OrderQuantity, 4) as Total_Profit, OrderDate
from sales_15_16_17 s inner join tbl_stg_prd p on s.ProductKey = p.ProductKey);

select * from New_Profit_Table;

create view New_Sales_15_16_17
as (Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity, TerritoryKey
from tbl_stg_sales_2015
union
Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity, TerritoryKey
from tbl_stg_sales_2016
union
Select ProductKey, CustomerKey, OrderDate, OrderNumber, OrderQuantity, TerritoryKey
from tbl_stg_sales_2017);

select * from New_Sales_15_16_17;


