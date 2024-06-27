create table retail_orders (
[order_id] int primary key,
[order_date] date,
[ship_mode] varchar(20),
[segment] varchar(20),
[country] varchar(20),
[city] varchar(20),
[state] varchar(20),
[postal_code] varchar(20),
[region] varchar(20),
[category] varchar(20),
[sub_category] varchar(20),
[product_id] varchar(50),
[quantity] int,
[discount] decimal(7,2),
[sale_price] decimal(7,2),
[profit] decimal(7,2)
);

select *
from retail_orders;

--find top 10 highest reveue generating products 

select top 10 product_id, sum(sale_price*quantity) as revenue
from retail_orders
group by product_id
order by 2 desc;

--find top 5 highest selling products in each region

select region, product_id, revenue
from (
	select region, product_id, sum(sale_price*quantity) as revenue, ROW_NUMBER() over(partition by region order by sum(sale_price*quantity) desc) as rnk
	from retail_orders
	group by region, product_id
	) as orders
where rnk <= 5;

--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023

with cte as (
select YEAR(order_date) as order_year, MONTH(order_date) as order_month, SUM(quantity*sale_price) as revenue
from retail_orders
group by YEAR(order_date), MONTH(order_date))
select order_month, sum(case when order_year=2022 then revenue else 0 end) as revenue_2022, sum(case when order_year=2023 then revenue else 0 end) as revenue_2023
from cte
group by order_month
order by order_month

--for each category which month had highest sales

select category, order_month, revenue
from (
	select category, format(order_date, 'yyyyMM') as order_month, sum(quantity*sale_price) as revenue,
			ROW_NUMBER() over(partition by category order by sum(quantity*sale_price) desc) as rnk
	from retail_orders
	group by category, format(order_date, 'yyyyMM')
	) as category_revenue
where rnk = 1;

--which sub category had highest growth by profit in 2023 compare to 2022

with cte1 as (
	select sub_category, YEAR(order_date) as order_year, SUM(quantity*profit) as profit
	from retail_orders
	group by sub_category, YEAR(order_date)
	),
cte2 as (
	select sub_category, sum(case when order_year=2022 then profit else 0 end) as profit_2022, sum(case when order_year=2023 then profit else 0 end) as profit_2023,
	(sum(case when order_year=2023 then profit else 0 end) - sum(case when order_year=2022 then profit else 0 end))as profit_difference, 
	ROW_NUMBER() over(order by (sum(case when order_year=2022 then profit else 0 end) - sum(case when order_year=2023 then profit else 0 end))) as rnk
	from cte1
	group by sub_category
)
select sub_category, profit_2022, profit_2023, profit_difference
from cte2
where rnk = 1;


with cte as (
	select sub_category, year(order_date) as order_year, sum(quantity*profit) as profit
	from retail_orders
	group by sub_category, year(order_date)
	),
cte1 as (
	select sub_category, sum(case when order_year=2022 then profit else 0 end) as profit_2022, sum(case when order_year=2023 then profit else 0 end) as profit_2023
	from cte 
	group by sub_category
	)
select top 1 *,(profit_2023 - profit_2022) as profit_difference
from  cte1
order by 4 desc;
