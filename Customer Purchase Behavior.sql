SELECT TOP (1000) [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [SQL CIRVEE PROJECT].[dbo].['Online Retail$']

  -- customer segmentation

	WITH CustomerOrders AS (
  SELECT 
    customerid, 
    COUNT(*) AS orderNo 
  FROM 
    ['Online Retail$'] 
  GROUP BY 
    customerid
)
SELECT 
  customerid, 
  CASE 
    WHEN orderNo = 1 THEN 'One-time Buyer' 
    WHEN orderNo BETWEEN 2 AND 4 THEN 'Repeat Buyer' 
    ELSE 'High-Frequency Buyer' 
  END AS customer_segment
FROM 
  CustomerOrders;


  -- revenue is generated from each segment 

  WITH CustomerSegments AS (
  SELECT
    customerid,
    COUNT(*) AS order_count,
    SUM(quantity * unitprice) AS total_revenue
  FROM ['Online Retail$']
  GROUP BY customerid
)
SELECT
  customer_segment,
  SUM(total_revenue) AS total_segment_revenue
FROM (
  SELECT
    customerid,
    CASE
      WHEN order_count = 1 THEN 'One-time Buyer'
      WHEN order_count BETWEEN 2 AND 4 THEN 'Repeat Buyer'
      ELSE 'High-Frequency Buyer'
    END AS customer_segment,
    total_revenue
  FROM CustomerSegments
) AS SegmentedCustomers
GROUP BY customer_segment;

-- Top 10 Most Purchased Products

WITH TopProducts AS (
  SELECT TOP 10
    stockcode,
    description,
    SUM(quantity) AS total_quantity_sold
  FROM
   ['Online Retail$']
  GROUP BY
    stockcode, description
  ORDER BY
    total_quantity_sold DESC
)
SELECT TOP 10
  stockcode,
  description,
 country,
  SUM(quantity) AS quantity_sold_by_country
FROM
  ['Online Retail$']
GROUP BY
stockcode, description, country
ORDER BY
  quantity_sold_by_country DESC;
	
-- Revenue Analysis by Country

WITH CountrySales AS (
  SELECT
   country,
    SUM(quantity * unitprice) AS total_revenue
  FROM
     ['Online Retail$']
  GROUP BY
   country
)
SELECT TOP 5
    country,
    total_revenue
FROM
    CountrySales
ORDER BY
    total_revenue DESC;

-- Monthly Sales Performance

 WITH MonthlySales AS (
  SELECT
    DATEADD(month, DATEDIFF(month, 0, invoicedate), 0) AS month_start,
    SUM(quantity * unitprice) AS total_sales
  FROM
    ['Online Retail$']
  GROUP BY
    DATEADD(month, DATEDIFF(month, 0, invoicedate), 0)
)
SELECT
  month_start,
  total_sales,
  LAG(total_sales) OVER (ORDER BY month_start) AS previous_month_sales,
  (total_sales - LAG(total_sales) OVER (ORDER BY month_start)) / LAG(total_sales) OVER (ORDER BY month_start) * 100 AS month_over_month_growth
FROM
  MonthlySales
ORDER BY
  month_start;


  -- Customer Lifetime Value (CLV) Analysis
 
  WITH CustomerRevenue AS (
  SELECT
    customerid,
    SUM(quantity * unitprice) AS total_revenue,
    COUNT(*) AS order_count
  FROM
    ['Online Retail$']
  GROUP BY
    customerid
)
SELECT TOP 5
  customerid,
  total_revenue,
  order_count,
  total_revenue / order_count AS average_order_value
FROM
  CustomerRevenue
ORDER BY
  total_revenue DESC;

 

  -- Product Performance Analysis by Category


  WITH ProductCategories AS (
    SELECT
        Description,
        CASE
            WHEN Description LIKE 'A%' THEN 'Category A'
            WHEN Description LIKE 'B%' THEN 'Category B'
            ELSE 'Other'
        END AS product_category
    FROM
        ['Online Retail$']
)
SELECT
    pc.product_category,
    o.Description,
    SUM(o.quantity * o.unitprice) AS product_revenue
FROM
    ProductCategories pc
INNER JOIN ['Online Retail$'] o
ON pc.Description = o.Description
GROUP BY
    pc.product_category, o.Description
ORDER BY
    pc.product_category, product_revenue DESC;

	

	-- Analyzing Sales Trends Over Time
	WITH ProductCategories AS (
    SELECT
        Description,
        CASE
            WHEN Description LIKE 'A%' THEN 'Category A'
            WHEN Description LIKE 'B%' THEN 'Category B'
            ELSE 'Other'
        END AS product_category
    FROM
        ['Online Retail$']
)
SELECT
    pc.product_category,
    DATEPART(YEAR, o.InvoiceDate) AS Year,
    DATEPART(QUARTER, o.InvoiceDate) AS Quarter,
    SUM(o.quantity * o.unitprice) AS quarterly_revenue
FROM
    ProductCategories pc
INNER JOIN ['Online Retail$']
o ON pc.Description = o.Description
GROUP BY
    pc.product_category, DATEPART(YEAR, o.InvoiceDate), DATEPART(QUARTER, o.InvoiceDate)
ORDER BY
    pc.product_category, DATEPART(YEAR, o.InvoiceDate), DATEPART(QUARTER, o.InvoiceDate);

	-- Identifying Cross-Selling Opportunities

	WITH FrequentPairs AS (
    SELECT TOP 5
        o1.Description AS product1,
        o2.Description AS product2,
        COUNT(*) AS frequency
    FROM
        ['Online Retail$']	o1
    JOIN ['Online Retail$']	o2 ON o1.InvoiceNo = o2.InvoiceNo AND o1.Description < o2.Description
    GROUP BY
        o1.Description, o2.Description
    HAVING COUNT(*) > 10
    ORDER BY
        frequency DESC
)
SELECT * FROM FrequentPairs;
