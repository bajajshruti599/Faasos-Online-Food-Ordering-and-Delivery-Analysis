
--Dates on which Drivers onboarded on the Fasoos Platform
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');

--Ingridients Table
drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

--Rolls table, here we are considering only 2 types of Rolls
drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

--Rolls Receipe Table: What all ingredients are present in Rolls?
drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');


--Driver Orders
drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);

--Customer Orders
drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


A. Roll Metrics
B. Driver and Customer Experience
C. Ingridient Optimisation
D. Pricing and Ratings


A. Roll Metrics
1. How many roles were ordered?

SELECT COUNT(roll_id)Total_rolls_ordered FROM customer_orders

2. How many unique customers orders were made?

SELECT COUNT(DISTINCT customer_id)Total_Cust FROM customer_orders;

3. How many successful orders were delivered by each driver?

select driver_id, sum(New_Cancellation)cnt from
(select driver_id,case when cancellation in ('cancellation','customer cancellation') then 0 else 1 end as New_Cancellation
from driver_order)a
group by driver_id


select * from driver_order

4. How many of each type of rolls delivered?

SELECT roll_id,COUNT(roll_id)cnt FROM customer_orders WHERE order_id IN 
(SELECT order_id FROM
(SELECT *, CASE WHEN cancellation IN ('cancellation','customer cancellation') THEN 'c' ELSE 'nc' 
END AS order_cancel_details FROM driver_order) d
WHERE order_cancel_details = 'nc')
GROUP BY roll_id

5. How many veg and Non veg rolls are ordered by each customer?

(select a.customer_id, count(b.roll_id)cnt,b.roll_name from customer_orders a inner join rolls b
on a.roll_id = b.roll_id
group by customer_id,roll_name)


6. What was the maximum no of rolls delievered in a single order?

SELECT * FROM
(SELECT *,rank() over(order by cnt desc)rnk from 
(SELECT order_id, count(roll_id)cnt from
(SELECT * from customer_orders where order_id in
(SELECT order_id from
(SELECT *, case when cancellation in ('cancellation','customer cancellation') then 'c' else 'nc' 
end as order_cancel_details from driver_order) d
where order_cancel_details = 'nc'))e
group by order_id)f)g
where rnk=1;


---Data Cleaning

select * from customer_orders

--Here in Customer_orders table, we have many blank values and NULL values, so to rectify this issue, need to create a Temp table
with temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
 select order_id, customer_id,roll_id,
 case when not_include_items is NULL or not_include_items = ' ' then '0' else not_include_items end as New_not_include_items,
 case when extra_items_included is NULL or extra_items_included = ' ' or extra_items_included= 'NaN' or extra_items_included = 'Null' then '0' else extra_items_included end as New_extra_items_included,
 order_date from customer_orders
 )
 select * from temp_customer_orders;


--Here in Driver_order table, we have many blank values and NULL values, so to rectify this issue, need to create a Temp table

SELECT * FROM driver_order
WITH temp_driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) as
(
  SELECT order_id,driver_id,
  case when pickup_time is NULL then 0 else pickup_time end as New_pickup_time ,
  case when distance is NULL then '0' else distance end as New_distance,
  case when duration is NULL then '0' else duration end as New_duration,
  case when cancellation is NULL or cancellation = ' ' or cancellation = 'NaN' then 0 else 1 end as New_cancellation
  from driver_order
  )
select * from temp_driver_order



7. For each customer How many delivered rolls had atleast 1 change and How many had no changes?


WITH temp_driver_order(order_id,driver_id,pickup_time,distance,duration,New_cancellation) as
(
  SELECT order_id,driver_id,
  case when pickup_time is NULL then 0 else pickup_time end as New_pickup_time ,
  case when distance is NULL then '0' else distance end as New_distance,
  case when duration is NULL then '0' else duration end as New_duration,
  case when cancellation is NULL or cancellation = ' ' or cancellation = 'NaN' then 0 else 1 end as New_cancellation
  from driver_order
  )
select * from temp_driver_order




--joining both temp_customer_orders and temp_driver_order

with temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
 select order_id, customer_id,roll_id,
 case when not_include_items is NULL or not_include_items = ' ' then '0' else not_include_items end as New_not_include_items,
 case when extra_items_included is NULL or extra_items_included = ' ' or extra_items_included= 'NaN' or extra_items_included = 'Null' then '0' else extra_items_included end as New_extra_items_included,
 order_date from customer_orders
 )
,
 temp_driver_order(order_id,driver_id,pickup_time,distance,duration,New_cancellation) as
(
  SELECT order_id,driver_id,
  case when pickup_time is NULL then 0 else pickup_time end as New_pickup_time ,
  case when distance is NULL then '0' else distance end as New_distance,
  case when duration is NULL then '0' else duration end as New_duration,
  case when cancellation is NULL or cancellation = ' ' or cancellation = 'NaN' then '0' else '1' end as New_cancellation
  from driver_order
  )

select a.customer_id,a.change_nochange, count(a.order_id)Atleast_one_change from 
(select *, case when not_include_items='0' and extra_items_included='0' then 'No change' else 'change' end as change_nochange	
from temp_customer_orders where order_id in (
select order_id from temp_driver_order where New_cancellation=0))a
group by customer_id,change_nochange;


8. How many rolls were delivered that had extras and exclusions both?

with temp_customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
 select order_id, customer_id,roll_id,
 case when not_include_items is NULL or not_include_items = ' ' then '0' else not_include_items end as New_not_include_items,
 case when extra_items_included is NULL or extra_items_included = ' ' or extra_items_included= 'NaN' or extra_items_included = 'Null' then '0' else extra_items_included end as New_extra_items_included,
 order_date from customer_orders
 )
,
  temp_driver_order(order_id,driver_id,pickup_time,distance,duration,New_cancellation) as
(
  SELECT order_id,driver_id,
  case when pickup_time is NULL then 0 else pickup_time end as New_pickup_time ,
  case when distance is NULL then '0' else distance end as New_distance,
  case when duration is NULL then '0' else duration end as New_duration,
  case when cancellation is NULL or cancellation = ' ' or cancellation = 'NaN' then '0' else '1' end as New_cancellation
  from driver_order
  )
select change_nochange,count(Change_nochange)Both_Extra_Excl_items from
(select *, case when not_include_items!='0' and extra_items_included!='0' then 'Both inc Exc' else 'Either 1 inc or exc' end as change_nochange	
from temp_customer_orders where order_id in (
select order_id from temp_driver_order where New_cancellation=0))a
Group by change_nochange


9. What was the total number of rolls ordered for each hour of the day?

select hrs_bucket,count(hrs_bucket)Rolls_cnt from
(select *,
concat(cast(datepart(hour,order_date)as varchar),'-',cast(datepart(hour,order_date)+1 as varchar))	Hrs_Bucket from customer_orders)a
group by Hrs_Bucket

10. What was the total number of rolls ordered for each day of the week?

select dow, count(distinct order_id) rolls_cnt from
(select *, datename(dw,order_date)dow from customer_orders)a
group by dow

11. What was the average time in minutes to arrive at the Fasoos HQ to pickup the order?

select driver_id,sum(diff)/count(order_id)avgmins from
(select * from
(select *, row_number()over(partition by order_id order by diff )rnk from
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date, 
b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation, datediff(MINUTE,a.order_date,b.pickup_time)diff
from customer_orders a inner join driver_order b
on a.order_id = b.order_id
where b.pickup_time is not null)a)b
where rnk=1)c
group by driver_id

 
 12. Is there any relationship between the number of rolls and how long the order takes to prepare?

select order_id,count(roll_id)cnt,sum(diff)/count(roll_id)prepared_time from
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date, 
b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation, datediff(MINUTE,a.order_date,b.pickup_time)diff
from customer_orders a inner join driver_order b
on a.order_id = b.order_id
where b.pickup_time is not null)c
group by order_id;


13. What was the average distance travelled for each customer?

select customer_id, sum(distance)/count(order_id) cnt from
(select * from
(select *, row_number()over(partition by order_id order by diff )rnk from
(select a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date, 
b.driver_id,b.pickup_time,
cast(trim(replace(lower(b.distance),'km','')) as decimal(4,2))distance,
b.duration,b.cancellation, datediff(MINUTE,a.order_date,b.pickup_time)diff
from customer_orders a inner join driver_order b
on a.order_id = b.order_id
where b.pickup_time is not null)c)d
where rnk=1)e
group by customer_id;


14. What was the difference between the longest and shortest delievery times for all orders?

select max(duration) - min(duration) diff from
(select cast(case when duration like '%min%' then left(duration, CHARINDEX('m',duration)-1)else 
duration end as integer) as duration
from driver_order
where duration is not null)a


15.	what was the average speed for each driver for each delivery and do you notice any trend for these values?

select driver_id,order_id, a.Distance/a.Duration Speed from
(select order_id, driver_id,
cast(trim(replace(lower(distance),'km','')) as decimal(4,2)) distance,
cast(case when duration like '%min%' then left(duration, charindex('m',duration)-1) else duration end as integer)as Duration
from driver_order
where Distance is not null)a

--calculation for analyzing any trend for driver speed related to no of orders

select a.driver_id,a.order_id, a.Distance/a.Duration Speed,b.cnt from

(select order_id, driver_id,
cast(trim(replace(lower(distance),'km','')) as decimal(4,2)) distance,
cast(case when duration like '%min%' then left(duration, charindex('m',duration)-1) else duration end as integer)as Duration
from driver_order
where Distance is not null)a

inner join

(select order_id,count(roll_id)cnt from customer_orders
group by order_id)b

on a.order_id = b.order_id;



16. What is the succcessful delivery percentage for each driver?

--sdp = Total sum of successful delivery of each driver / count of total orders taken 

select driver_id,(sucessfully_delivered*1.0/count_driver)*100 delivery_percent from
(select driver_id, sum(cancellation_per)sucessfully_delivered, count(driver_id)count_driver from
(select driver_id, case when lower(cancellation) like '%cancel%' then 0 else 1 end as cancellation_per from driver_order)a
group by driver_id)d;