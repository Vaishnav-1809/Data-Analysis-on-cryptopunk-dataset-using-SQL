USE cryptopunk;
SELECT*FROM pricedata;

-- 1.How many sales occurred during this time period? 
SELECT COUNT(*) AS total_sales 
FROM pricedata;

-- 2.Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date.
SELECT name,eth_price,usd_price,event_date 
FROM pricedata
ORDER BY usd_price DESC
LIMIT 5;

-- 3.Return a table with a row for each transaction with an event column, a USD price column, and a moving average of USD price that averages the last 50 transactions.
SELECT event_date AS event,usd_price,AVG(usd_price) 
OVER(ORDER BY event_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS 'moving avg of USD price'
FROM pricedata;

-- 4.Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.
SELECT name,AVG(usd_price) AS average_price
FROM pricedata 
GROUP BY name
ORDER BY average_price DESC;

-- 5.Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. 
-- Order by the count of transactions in ascending order.
SELECT DAYNAME(event_date) AS day,
COUNT(*) AS sales, 
AVG(eth_price)AS "average price in ETH"
FROM pricedata
GROUP BY day 
ORDER BY sales;

-- 6.Construct a column that describes each sale and is called summary. 
-- The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.
SELECT CONCAT
(
name," ","was sold for",ROUND(usd_price,-3)," ","to"," ",buyer_address," ","from"," ",seller_address," ","on"," ",event_date
)AS summary
FROM pricedata;

-- 7.Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
CREATE VIEW 1919_purchases AS
SELECT*FROM pricedata
WHERE buyer_address="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

-- 8.Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT ROUND(eth_price,-2) AS eth_price_range,
COUNT(*) AS total_count,
RPAD('',COUNT(*),'*') AS histogram
FROM pricedata
GROUP BY eth_price_range ORDER BY eth_price_range;

-- 9.Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”.
-- The table should have a name column, a price column called price, and a status column. Order the result set by the name of the NFT, and the status, in ascending order. 
CREATE VIEW max_selling_price AS
SELECT name,MAX(usd_price) AS price,
CASE
WHEN "price"IN("price") THEN "Highest"
END AS status
FROM pricedata
GROUP BY name ORDER BY name;

CREATE VIEW min_selling_price AS
SELECT name,MIN(usd_price) AS price,
CASE
WHEN "price"IN("price") THEN "Lowest"
END AS status
FROM pricedata
GROUP BY name ORDER BY name;

SELECT*FROM max_selling_price
UNION
SELECT*FROM min_selling_price ORDER BY name,status;

-- 10.What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format. 
SELECT 
name,
usd_price,
sale_month,
sale_year,
sale_count,
sale_rank
FROM (SELECT 
name,
MAX(usd_price) AS usd_price,
MONTH(event_date) AS sale_month,
YEAR(event_date) AS sale_year,
COUNT(usd_price) AS sale_count,
DENSE_RANK() OVER(
PARTITION BY YEAR(event_date),MONTH(event_date) ORDER BY COUNT(usd_price) DESC
) AS sale_rank
FROM
pricedata
GROUP BY name, YEAR(event_date), MONTH(event_date)
)AS sale_data
WHERE sale_rank=1;

-- 11.Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).
SELECT
MONTH(event_date) AS sale_month,YEAR(event_date) AS sale_year,ROUND(SUM(usd_price),-2) AS total_sales_volume
FROM pricedata
GROUP BY YEAR(event_date),MONTH(event_date) ORDER BY YEAR(event_date),MONTH(event_date);

-- 12.Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.
SELECT COUNT(*) AS total_transactions FROM pricedata
WHERE `buyer_address`="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"
OR `seller_address`="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

-- 13.Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 -- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 -- Take the daily average of remaining transactions
 
 -- a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function.
 -- Save it as a temporary table.
CREATE TEMPORARY TABLE daily_avg_price_table AS
SELECT event_date,usd_price,
AVG(usd_price)OVER(PARTITION BY DATE(event_date)) AS avg_usd_price_per_day
FROM pricedata;

 -- b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data

SELECT*,AVG(usd_price)OVER(PARTITION BY DATE(event_date)) AS new_avg_usd_price_per_day
FROM daily_avg_price_table
WHERE usd_price>(0.9*avg_usd_price_per_day);

-- 14.Give a complete list ordered by wallet profitability (whether people have made or lost money)
SELECT 
personID, SUM(total_trade) AS profitability
FROM
(SELECT 
buyer_address AS personID, (usd_price * -1) AS total_trade
FROM
pricedata 
UNION 
SELECT 
seller_address AS personID, usd_price AS total_trade
FROM
pricedata) AS total_transactions
GROUP BY personID
ORDER BY SUM(total_trade) DESC;

