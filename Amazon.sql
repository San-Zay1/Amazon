use amazon;
show tables;
-- ---------------------------
-- 18 Advanced Business Problems
-- ---------------------------

/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/
select p.product_name,
sum(oi.quantity) as 'Total_quantity_sold',
sum(oi.quantity*oi.price_per_unit) as 'Total_sales_value' 
from order_items oi 
join products p 
on p.product_id=oi.product_id 
group by oi.product_id
limit 10;

/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
*/
select c.category_name,sum(oi.total_sale) as 'Total_revenue',
sum(oi.total_sale)/(select sum(total_sale) from order_items)*100 as 'percent_contribution'
from category c join products p 
on c.category_id=p.category_id
join order_items oi on p.product_id=oi.product_id
group by c.category_name
order by percent_contribution desc;


/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/
select c.customer_id,
concat(c.first_name,' ',c.last_name) as 'Customer_name',
avg(oi.total_sale),
Count(o.order_id) as total_orders  
from orders o
join order_items oi 
on oi.order_id=o.order_id
join customers c 
on c.customer_id=o.customer_id 
group by c.customer_id,Customer_name 
having total_orders>5;

/*
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/


With past_year_sale as (
select Year(o.order_date) as 'Year_name',
month(o.order_date) as 'Month_name',
sum(oi.total_sale) as 'Total_monthly_sale'
from orders o
join order_items oi 
on o.order_id=oi.order_id 
where o.order_date>=date_sub(now(),interval 1 year) 
group by Month_name,Year_name
)
select *,
lag(Total_monthly_sale,1) over(order by Month_name asc) as 'last_month_sale' 
from past_year_sale;



/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/

select * 
from customers c 
where c.customer_id 
not in (select o.customer_id from orders o);

/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*/


With least_seeling_category as (
select cu.state,
c.category_name,
p.product_name,
sum(oi.total_sale) as 'total_sale',
row_number() over(partition by cu.state order by sum(oi.total_sale) asc) as 'ranking' 
from category c join products p 
on c.category_id=p.category_id 
join order_items oi 
on oi.product_id=p.product_id 
join orders o 
on o.order_id=oi.order_id 
join customers cu
on cu.customer_id=o.customer_id 
group by c.category_name,
p.product_name,
cu.state
)
select * 
from least_seeling_category 
where ranking=1;


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/
select c.customer_id,concat(c.first_name,' ',c.last_name) as 'Customer_name',
sum(oi.total_sale) as 'CLTV',
dense_rank() over(order by sum(oi.total_sale) desc) as 'ranking' 
from customers c 
join orders o 
on c.customer_id=o.customer_id
join order_items oi 
on oi.order_id=o.order_id
group by c.customer_id,Customer_name
;

/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/

select p.product_id,
p.product_name,
i.stock,
i.last_stock_date,
i.warehouse_id 
from inventory i 
join products p 
on p.product_id=i.product_id 
where stock<10;



/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/
select * from orders;

select c.*,
o.*,
s.shipping_providers,
s.shipping_date-o.order_date as 'shipping_days' 
from shippings s 
join orders o 
on o.order_id=s.order_id
join customers c 
on o.customer_id=c.customer_id
where s.shipping_date-o.order_date >3;

/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/

select payment_status,
count(order_id) as 'total_transaction_num',
count(order_id)/(select count(order_id) from payments)*100 as 'Percent_contribution' 
from payments 
group by payment_status;

/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/
select distinct order_status from orders;
With Top_seller as (

select s.seller_id,
s.seller_name,
sum(oi.total_sale) as 'Total_sales',
count(o.order_id) as 'total_orders',
SUM(CASE WHEN order_status = 'completed' THEN 1  END) AS total_success_orders,
SUM(CASE WHEN order_status = 'cancelled' THEN 1 END) AS total_failed_orders
from sellers s
join orders o
on o.seller_id=s.seller_id
join order_items oi 
on oi.order_id=o.order_id
where o.order_status in ('completed','cancelled')
group by s.seller_id,s.seller_name
order by Total_sales desc
limit 5
)
select *,total_success_orders/total_orders*100 as 'successful_order_percent' from Top_seller;

-- OR

With Top_seller as (
select s.seller_id,
s.seller_name,
sum(oi.total_sale) as 'Total_sales'
from sellers s
join orders o
on o.seller_id=s.seller_id
join order_items oi 
on oi.order_id=o.order_id
group by s.seller_id,s.seller_name
order by Total_sales desc
limit 5
),
seller_reports as(
select o.seller_id,
ts.seller_name,
count(*) as 'Total_orders',
sum(case when o.order_status='completed' then 1 end) as 'Total_successfull_orders',
sum(case when o.order_status='cancelled' then 1 end) as 'Total_failed_orders'
from orders o
join Top_seller ts
on ts.seller_id=o.seller_id
where o.order_status in ('completed','cancelled')
group by o.seller_id,ts.seller_name
)
select sr.seller_id,
sr.seller_name,
sr.Total_orders,
sr.Total_successfull_orders,
sr.Total_failed_orders,
sr.Total_successfull_orders/sr. Total_orders*100 as 'successful_order_percent'
from seller_reports sr;

/*
12. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/

With most_returned_products as (
select p.product_id,
p.product_name,
sum(oi.quantity) as 'total_orders',
sum(case when o.order_status='returned' then 1 end) as 'Number_of_returns'
from orders o
join order_items oi
on o.order_id=oi.order_id
join products p
on p.product_id=oi.product_id
group by p.product_id, p.product_name
order by Number_of_returns desc
limit 10
)
select *,Number_of_returns/total_orders*100 as 'return_rate_percentage' from most_returned_products;


/*
13. Orders Pending Shipment
Find orders that have been paid but are still pending shipment.
Challenge: Include order details, payment date, and customer information.
*/
select c.*,o.order_id,o.order_date,o.seller_id,p.payment_date from payments p
join orders o on o.order_id=p.order_id
join shippings s
on s.order_id=o.order_id
join customers c
on c.customer_id=o.customer_id
where p.payment_status='Payment Successed'
and s.delivery_status='shipped';


/*
14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/
With inactive_seller as (
select o.seller_id,s.seller_name,sum(oi.total_sale) as 'Total_sales'
from orders o join sellers s
on s.seller_id=o.seller_id
join order_items oi 
on oi.order_id=o.order_id
where o.seller_id not in (select distinct seller_id from orders where order_date>=date_sub(curdate(),interval 7 month))
group by o.seller_id,s.seller_name
)
select distinct ise.seller_id,ise.seller_name,ise.Total_sales,first_value(o.order_date) over(partition by ise.seller_name order by o.order_date desc) as 'last_sale_date'
from inactive_seller ise join orders o
on o.seller_id=ise.seller_id;

/*
15. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/

With customer_details as (
select o.customer_id,
concat(c.first_name,' ',c.last_name) as 'Customer_name',
count(o.order_id) as 'Total_orders',
sum(case when o.order_status='returned' then 1 else 0 end) as 'total_returns'
from orders o 
join customers c
on c.customer_id=o.customer_id
group by o.customer_id,Customer_name
)
select cd.customer_id,
cd.Customer_name,
cd.Total_orders,
cd.total_returns,if(cd.total_returns>5,'returning','new') as 'Category' 
from customer_details cd;

/*
16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/

With highestorder_cus as (
select o.customer_id,
concat(c.first_name,' ',c.last_name) as 'Customer_name',
c.state,
count(o.order_id) as 'total_orders',
sum(oi.total_sale) as 'Total_sales',
row_number() over(partition by c.state order by count(oi.order_id) desc) as 'ranking'
from order_items oi 
join orders o
on o.order_id=oi.order_id
join customers c 
on c.customer_id=o.customer_id
group by o.customer_id,Customer_name,c.state
)
select * from highestorder_cus where ranking<=5;

/*
17. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
*/
-- total_revenue, total_orders, average_delivery_time

select s.shipping_providers,
avg(s.shipping_date-o.order_date) as 'Days of delivery' ,
count(s.order_id) as 'total_orders',
sum(oi.total_sale) as 'Total_revenue_handled'
from shippings s
join orders o
on s.order_id=o.order_id
join order_items oi
on oi.order_id=o.order_id
group by s.shipping_providers;

/*
18. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result

Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/
With last_year_sale as (
select p.product_id,
p.product_name,
sum(oi.total_sale) as 'last_year_revenue'
from products p
join order_items oi
on oi.product_id=p.product_id
join orders o
on o.order_id=oi.order_id
where year(o.order_date)=2022
group by p.product_id,p.product_name
),
current_year_sale as (
select p.product_id,
p.product_name,
sum(oi.total_sale) as 'current_year_revenue'
from products p
join order_items oi
on oi.product_id=p.product_id
join orders o
on o.order_id=oi.order_id
where year(o.order_date)=2023
group by p.product_id,p.product_name
)
select cs.product_id,
cs.product_name,
ls.last_year_revenue,
cs.current_year_revenue,
round((cs.current_year_revenue-ls.last_year_revenue)/ls.last_year_revenue*100,2) as 'decrease_ratio'
from last_year_sale ls
join current_year_sale cs
on ls.product_id=cs.product_id
where ls.last_year_revenue>cs.current_year_revenue
order by decrease_ratio desc
limit 10;







