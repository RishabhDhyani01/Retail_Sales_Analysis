-- =============================================
-- Retail_Sales_Raw Data Cleaning 
-- Database: Retail_Sales_Analytics
-- Source Table: Retail_Sales_Raw
-- =============================================

-- =============================================
-- Step 1 : Data Exploration
-- =============================================

-- Select the database
USE Retail_Sales_Analytics;

-- 1. Check the total number of records
SELECT COUNT(*) AS Total_Rows
FROM Retail_Sales_Raw;

-- 2. Check the total number of columns
SELECT COUNT(*) AS Total_Columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Retail_Sales_Raw';

-- 3. Check the date range of the dataset
SELECT
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM Retail_Sales_Raw;

-- 4. View a sample of 10 records
SELECT TOP 10 *
FROM Retail_Sales_Raw;


-- =============================================
-- STEP 2: DATA QUALITY ASSESSMENT
-- =============================================

-- 2.1 Check NULL values in important ID columns

SELECT
    COUNT(*) - COUNT(Transaction_ID) AS Null_Transaction_ID,
    COUNT(*) - COUNT(Order_ID) AS Null_Order_ID,
    COUNT(*) - COUNT(Customer_ID) AS Null_Customer_ID,
    COUNT(*) - COUNT(Store_ID) AS Null_Store_ID,
    COUNT(*) - COUNT(Product_ID) AS Null_Product_ID
FROM Retail_Sales_Raw;

-- 2.2 Check NULL values in the remaining 31 columns

SELECT
    COUNT(*) - COUNT(Customer_Name) AS Null_Customer_Name,
    COUNT(*) - COUNT(Customer_Age) AS Null_Customer_Age,
    COUNT(*) - COUNT(Customer_Gender) AS Null_Customer_Gender,
    COUNT(*) - COUNT(Customer_Segment) AS Null_Customer_Segment,
    COUNT(*) - COUNT(Order_Date) AS Null_Order_Date,
    COUNT(*) - COUNT(Order_Time) AS Null_Order_Time,
    COUNT(*) - COUNT(Sales_Channel) AS Null_Sales_Channel,
    COUNT(*) - COUNT(Store_Name) AS Null_Store_Name,
    COUNT(*) - COUNT(Country) AS Null_Country,
    COUNT(*) - COUNT(Region) AS Null_Region,
    COUNT(*) - COUNT(City) AS Null_City,
    COUNT(*) - COUNT(Product_Name) AS Null_Product_Name,
    COUNT(*) - COUNT(Product_Category) AS Null_Product_Category,
    COUNT(*) - COUNT(Product_Subcategory) AS Null_Product_Subcategory,
    COUNT(*) - COUNT(Quantity) AS Null_Quantity,
    COUNT(*) - COUNT(Unit_Price) AS Null_Unit_Price,
    COUNT(*) - COUNT(Discount_Percentage) AS Null_Discount_Percentage,
    COUNT(*) - COUNT(Sales_Amount) AS Null_Sales_Amount,
    COUNT(*) - COUNT(Cost_Amount) AS Null_Cost_Amount,
    COUNT(*) - COUNT(Profit) AS Null_Profit,
    COUNT(*) - COUNT(Payment_Method) AS Null_Payment_Method,
    COUNT(*) - COUNT(Order_Status) AS Null_Order_Status,
    COUNT(*) - COUNT(Shipping_Method) AS Null_Shipping_Method,
    COUNT(*) - COUNT(Delivery_Days) AS Null_Delivery_Days,
    COUNT(*) - COUNT(Return_Flag) AS Null_Return_Flag,
    COUNT(*) - COUNT(Return_Reason) AS Null_Return_Reason,
    COUNT(*) - COUNT(Sales_Representative) AS Null_Sales_Representative,
    COUNT(*) - COUNT(Promotion_Code) AS Null_Promotion_Code,
    COUNT(*) - COUNT(Customer_Rating) AS Null_Customer_Rating,
    COUNT(*) - COUNT(Inventory_Level) AS Null_Inventory_Level,
    COUNT(*) - COUNT(Order_Year) AS Null_Order_Year
FROM Retail_Sales_Raw;

-- 2.3 Check duplicate Transaction IDs

SELECT
    Transaction_ID,
    COUNT(*) AS Duplicate_Count
FROM Retail_Sales_Raw
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- 2.4 Check duplicate Order IDs
-- An order can contain multiple products, so repetition may be valid

SELECT
    Order_ID,
    COUNT(*) AS Transaction_Count
FROM Retail_Sales_Raw
GROUP BY Order_ID
HAVING COUNT(*) > 1;

-- 2.5 Check repeated Order ID and Product ID combinations

SELECT
    Order_ID,
    Product_ID,
    COUNT(*) AS Duplicate_Count
FROM Retail_Sales_Raw
GROUP BY Order_ID, Product_ID
HAVING COUNT(*) > 1;

-- 2.6 Check invalid or unusual numerical values

-- Check invalid numerical values

SELECT *
FROM Retail_Sales_Raw
WHERE Sales_Amount <= 0
   OR Quantity <= 0
   OR Discount_Percentage < 0
   OR Customer_Age <= 0;

-- 2.7 Check categorical inconsistencies

SELECT DISTINCT Customer_Gender FROM Retail_Sales_Raw;
SELECT DISTINCT Customer_Segment FROM Retail_Sales_Raw;
SELECT DISTINCT Sales_Channel FROM Retail_Sales_Raw;
SELECT DISTINCT Country FROM Retail_Sales_Raw;
SELECT DISTINCT Region FROM Retail_Sales_Raw;
SELECT DISTINCT Product_Category FROM Retail_Sales_Raw;
SELECT DISTINCT Product_SubCategory FROM Retail_Sales_Raw;
SELECT DISTINCT Payment_Method FROM Retail_Sales_Raw;
SELECT DISTINCT Shipping_Method FROM Retail_Sales_Raw;
SELECT DISTINCT Order_Status FROM Retail_Sales_Raw;
SELECT DISTINCT Return_Reason FROM Retail_Sales_Raw;
SELECT DISTINCT Promotion_Code FROM Retail_Sales_Raw;
SELECT DISTINCT Sales_Representative FROM Retail_Sales_Raw;

-- 2.8 Check Product ID and Product Name consistency

SELECT
    Product_ID,
    COUNT(DISTINCT Product_Name) AS Product_Name_Count
FROM Retail_Sales_Raw
WHERE Product_Name IS NOT NULL
GROUP BY Product_ID
HAVING COUNT(DISTINCT Product_Name) > 1;

-- 2.9 Check missing return reasons

SELECT
    Return_Flag,
    COUNT(*) AS Missing_Return_Reasons
FROM Retail_Sales_Raw
WHERE Return_Reason IS NULL
GROUP BY Return_Flag;



-- =============================================
-- STEP 3: DATA CLEANING
-- =============================================

GO

CREATE OR ALTER PROCEDURE Clean_Retail_Sales
AS
BEGIN

-- 3.1 Create a fresh cleaned table
-- Refresh it with the latest raw data

DROP TABLE IF EXISTS Retail_Sales_Cleaned;
SELECT * INTO Retail_Sales_Cleaned
FROM Retail_Sales_Raw;

-- 3.2 Remove duplicate Transaction_ID records
-- Keep one record per Transaction_ID

WITH duplicate_transaction_ids AS(
    SELECT *,ROW_NUMBER() OVER (
            PARTITION BY Transaction_ID
            ORDER BY Transaction_ID) AS rn
    FROM Retail_Sales_Cleaned)
DELETE FROM duplicate_transaction_ids
WHERE rn > 1;

-- 3.3 Remove duplicate Order_ID + Product_ID combinations
-- Keep one record per combination

WITH duplicate_order_ids AS(
    SELECT *,ROW_NUMBER() OVER (
            PARTITION BY Order_ID, Product_ID
            ORDER BY Order_ID) AS rn
    FROM Retail_Sales_Cleaned)
DELETE FROM duplicate_order_ids
WHERE rn > 1;

-- Remove records with zero or negative quantities
DELETE FROM Retail_Sales_Cleaned
WHERE Quantity <= 0;

-- 3.4 Clean information
-- Replace missing customer names
UPDATE Retail_Sales_Cleaned
SET Customer_Name = 'Unknown'
WHERE Customer_Name IS NULL;

-- Set invalid age text to NULL
UPDATE Retail_Sales_Cleaned
SET Customer_Age = NULL
WHERE Customer_Age LIKE '%[^0-9]%';

-- Replace missing gender
UPDATE Retail_Sales_Cleaned
SET Customer_Gender = 'Unknown'
WHERE Customer_Gender IS NULL;

-- Standardize gender values
UPDATE Retail_Sales_Cleaned
SET Customer_Gender = 'Non-binary'
WHERE Customer_Gender = 'Non Binary';

-- Standardize Region Names
UPDATE Retail_Sales_Cleaned
SET Region = CASE
    WHEN Region IN ('North east', 'Northeast') THEN 'Northeast'
    WHEN Region = 'NRW' THEN 'North Rhine-Westphalia'
    ELSE Region
END;

-- 3.5 Remove unnecessary spaces from categorical columns
UPDATE Retail_Sales_Cleaned
SET
    Customer_Segment = LTRIM(RTRIM(Customer_Segment)),
    Sales_Channel = LTRIM(RTRIM(Sales_Channel)),
    Store_Name = LTRIM(RTRIM(Store_Name)),
    Country = LTRIM(RTRIM(Country)),
    Region = LTRIM(RTRIM(Region)),
    City = LTRIM(RTRIM(City)),
    Product_Name = LTRIM(RTRIM(Product_Name)),
    Product_Category = LTRIM(RTRIM(Product_Category)),
    Product_Subcategory = LTRIM(RTRIM(Product_Subcategory)),
    Payment_Method = LTRIM(RTRIM(Payment_Method)),
    Order_Status = LTRIM(RTRIM(Order_Status)),
    Shipping_Method = LTRIM(RTRIM(Shipping_Method)),
    Sales_Representative = LTRIM(RTRIM(Sales_Representative)),
    Promotion_Code = LTRIM(RTRIM(Promotion_Code));

-- 3.6 Recover missing product names using Product_ID
UPDATE Retail_Sales_Cleaned
SET Product_Name = (
    SELECT MAX(Product_Name)
    FROM Retail_Sales_Raw
    WHERE Product_ID = Retail_Sales_Cleaned.Product_ID
)
WHERE Product_Name IS NULL;

-- 3.7 Replace missing categorical values with Unknown
UPDATE Retail_Sales_Cleaned SET Customer_Segment = 'Unknown' WHERE Customer_Segment IS NULL;
UPDATE Retail_Sales_Cleaned SET Sales_Channel = 'Unknown' WHERE Sales_Channel IS NULL;
UPDATE Retail_Sales_Cleaned SET Store_Name = 'Unknown' WHERE Store_Name IS NULL;
UPDATE Retail_Sales_Cleaned SET Country = 'Unknown' WHERE Country IS NULL;
UPDATE Retail_Sales_Cleaned SET Region = 'Unknown' WHERE Region IS NULL;
UPDATE Retail_Sales_Cleaned SET City = 'Unknown' WHERE City IS NULL;
UPDATE Retail_Sales_Cleaned SET Product_Name = 'Unknown' WHERE Product_Name IS NULL;
UPDATE Retail_Sales_Cleaned SET Product_Category = 'Unknown' WHERE Product_Category IS NULL;
UPDATE Retail_Sales_Cleaned SET Product_Subcategory = 'Unknown' WHERE Product_Subcategory IS NULL;
UPDATE Retail_Sales_Cleaned SET Payment_Method = 'Unknown' WHERE Payment_Method IS NULL;
UPDATE Retail_Sales_Cleaned SET Order_Status = 'Unknown' WHERE Order_Status IS NULL;
UPDATE Retail_Sales_Cleaned SET Shipping_Method = 'Unknown' WHERE Shipping_Method IS NULL;
UPDATE Retail_Sales_Cleaned SET Sales_Representative = 'Unknown' WHERE Sales_Representative IS NULL;
UPDATE Retail_Sales_Cleaned SET Promotion_Code = 'Unknown' WHERE Promotion_Code IS NULL;

-- 3.8 Replace Return_Flag values

ALTER TABLE Retail_Sales_Cleaned
ALTER COLUMN Return_Flag VARCHAR(20);

UPDATE Retail_Sales_Cleaned
SET Return_Flag =
    CASE
        WHEN Return_Flag = '1' THEN 'Returned'
        WHEN Return_Flag = '0' THEN 'Not Returned'
        ELSE 'Unknown' END;

-- 3.9 Replace missing return reasons for returned records
UPDATE Retail_Sales_Cleaned
SET Return_Reason = 'Unknown'
WHERE Return_Flag = 'Returned'
AND Return_Reason IS NULL;

-- 3.10 Set monetary columns to 2 decimal places

ALTER TABLE Retail_Sales_Cleaned
ALTER COLUMN Unit_Price DECIMAL(18,2);
ALTER TABLE Retail_Sales_Cleaned
ALTER COLUMN Sales_Amount DECIMAL(18,2);
ALTER TABLE Retail_Sales_Cleaned
ALTER COLUMN Cost_Amount DECIMAL(18,2);
ALTER TABLE Retail_Sales_Cleaned
ALTER COLUMN Profit DECIMAL(18,2);

END;

GO

EXEC Clean_Retail_Sales;


-- =============================================
-- STEP 4: DATA VALIDATION
-- =============================================

-- 4.1 Compare raw and cleaned row counts
SELECT
    (SELECT COUNT(*) FROM Retail_Sales_Raw) AS Raw_Rows,
    (SELECT COUNT(*) FROM Retail_Sales_Cleaned) AS Cleaned_Rows;

-- 4.2 Check duplicate Transaction_ID records
SELECT Transaction_ID, COUNT(*) AS Duplicate_Count
FROM Retail_Sales_Cleaned
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- 4.3 Check duplicate Order_ID + Product_ID combinations
SELECT Order_ID, Product_ID, COUNT(*) AS Duplicate_Count
FROM Retail_Sales_Cleaned
GROUP BY Order_ID, Product_ID
HAVING COUNT(*) > 1;

-- 4.4 Check NULL values in important ID columns
SELECT
    SUM(CASE WHEN Transaction_ID IS NULL THEN 1 ELSE 0 END) AS Transaction_ID_Nulls,
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS Order_ID_Nulls,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Customer_ID_Nulls,
    SUM(CASE WHEN Store_ID IS NULL THEN 1 ELSE 0 END) AS Store_ID_Nulls,
    SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS Product_ID_Nulls
FROM Retail_Sales_Cleaned;

-- 4.5 Check Return_Flag values
SELECT Return_Flag, COUNT(*) AS Record_Count
FROM Retail_Sales_Cleaned
GROUP BY Return_Flag;

-- 4.6 Check invalid numeric values
SELECT *
FROM Retail_Sales_Cleaned
WHERE Customer_Age < 0
   OR Quantity <= 0
   OR Unit_Price < 0
   OR Sales_Amount < 0
   OR Cost_Amount < 0;

-- 4.7 Check date range
SELECT
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM Retail_Sales_Cleaned;



-- =========================================================================================================================
-- Data cleaning and validation completed successfully. The dataset is ready for analysis.
-- =========================================================================================================================


-- =============================================
-- STEP 5: BUSINESS ANALYSIS & REPORTING
-- =============================================

-- =============================================
-- OVERALL BUSINESS KPIs
-- =============================================

-- 5.1 Overall Business Performance (Key Performance Indicators)
SELECT
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Cost_Amount) AS Total_Cost,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    SUM(Quantity) AS Total_Quantity_Sold
FROM Retail_Sales_Cleaned;

-- =============================================
-- TIME-BASED SALES & PROFIT ANALYSIS
-- =============================================

-- 5.2 Yearly Sales and Profit Performance
SELECT
    Order_Year,
    SUM(Sales_Amount) AS Yearly_Sales,
    SUM(Profit) AS Yearly_Profit
FROM Retail_Sales_Cleaned
GROUP BY Order_Year
ORDER BY Order_Year;

-- 5.3 Monthly Sales & Profit Trends
SELECT
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    SUM(Sales_Amount) AS Monthly_Sales,
    SUM(Profit) AS Monthly_Profit
FROM Retail_Sales_Cleaned
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_Year, Order_Month;

-- 5.4 Quarterly Sales & Profit Performance
SELECT
    YEAR(Order_Date) AS Order_Year,
    DATEPART(QUARTER, Order_Date) AS Order_Quarter,
    SUM(Sales_Amount) AS Quarterly_Sales,
    SUM(Profit) AS Quarterly_Profit
FROM Retail_Sales_Cleaned
GROUP BY YEAR(Order_Date), DATEPART(QUARTER, Order_Date)
ORDER BY Order_Year, Order_Quarter;

-- =============================================
-- REGIONAL PERFORMANCE ANALYSIS
-- =============================================

-- 5.5 Regional Sales & Profitability
SELECT
    Region,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Cost_Amount) AS Total_Cost,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Region
ORDER BY Total_Sales DESC;

-- 5.6 Regional Sales & Profit Contribution
SELECT
    Region,
    CONCAT(CAST(S * 100.0 / SUM(S) OVER() AS DECIMAL(10,2)), '%') AS Sales_Contribution,
    CONCAT(CAST(P * 100.0 / SUM(P) OVER() AS DECIMAL(10,2)), '%') AS Profit_Contribution
FROM (SELECT Region,
        SUM(Sales_Amount) AS S,
        SUM(Profit) AS P
    FROM Retail_Sales_Cleaned
    GROUP BY Region)t
ORDER BY S DESC;

-- 5.7 Regional Year-over-Year Growth
-- Compare yearly sales and profit growth across different regions.
SELECT *,
    CASE
        WHEN Prev_Sales IS NULL OR Prev_Sales = 0 THEN NULL
        ELSE CONCAT(CAST((Sales - Prev_Sales) * 100.0 / Prev_Sales AS DECIMAL(10,2)), '%')
    END AS Sales_Growth,
    CASE
        WHEN Prev_Profit IS NULL OR Prev_Profit = 0 THEN NULL
        ELSE CONCAT(CAST((Profit - Prev_Profit) * 100.0 / Prev_Profit AS DECIMAL(10,2)), '%')
    END AS Profit_Growth
FROM (SELECT
        Order_Year,
        Region,
        SUM(Sales_Amount) AS Sales,
        LAG(SUM(Sales_Amount)) OVER (PARTITION BY Region ORDER BY Order_Year) AS Prev_Sales,
        SUM(Profit) AS Profit,
        LAG(SUM(Profit)) OVER (PARTITION BY Region ORDER BY Order_Year) AS Prev_Profit
    FROM Retail_Sales_Cleaned
    GROUP BY Order_Year, Region)t
ORDER BY Region, Order_Year;

-- 5.8 Regional Order & Customer Performance
SELECT
    Region,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    SUM(Sales_Amount) / COUNT(DISTINCT Order_ID) AS Average_Order_Value,
    SUM(Sales_Amount) / COUNT(DISTINCT Customer_ID) AS Average_Sales_Per_Customer
FROM Retail_Sales_Cleaned
GROUP BY Region
ORDER BY Total_Orders DESC;

-- 5.9 Regional Return Analysis
SELECT
    Region,
    COUNT(DISTINCT CASE WHEN Return_Flag = 'Returned' THEN Order_ID END) AS Returned_Orders,
    CONCAT(CAST(COUNT(DISTINCT CASE WHEN Return_Flag = 'Returned' THEN Order_ID END) * 100.0 /
    COUNT(DISTINCT Order_ID) AS DECIMAL(10,2)), '%') AS Return_Rate,
    SUM(CASE WHEN Return_Flag = 'Returned' THEN Sales_Amount ELSE 0 END) AS Returned_Sales
FROM Retail_Sales_Cleaned
GROUP BY Region
ORDER BY Return_Rate DESC;

-- 5.10 Regional Product Category Performance
SELECT
    Region,
    Product_Category,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Region, Product_Category
ORDER BY Region, Total_Sales DESC;


-- =============================================
-- PRODUCT & CATEGORY ANALYSIS
-- =============================================

-- 5.11 Product Category & Subcategory Performance
SELECT
    Product_Category,
    Product_Subcategory,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Product_Category, Product_Subcategory
ORDER BY Total_Profit DESC;

-- 5.12 Top 5 Products by Sales
SELECT TOP 5
    Product_ID,
    Product_Name,
    SUM(Quantity) AS Total_Quantity_Sold,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Product_ID, Product_Name
ORDER BY Total_Sales DESC;


-- =============================================
-- CUSTOMER ANALYSIS
-- =============================================

-- 5.13 Customer Segment Performance
SELECT
    Customer_Segment,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Sales_Amount) / COUNT(DISTINCT Customer_ID) AS Sales_Per_Customer
FROM Retail_Sales_Cleaned
GROUP BY Customer_Segment
ORDER BY Total_Sales DESC;

-- 5.14 Top 10 Customers by Profit
SELECT TOP 10
    Customer_ID,
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Retail_Sales_Cleaned
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Profit DESC;


-- =============================================
-- DISCOUNT & PROMOTION ANALYSIS
-- =============================================

-- 5.15 Discount Impact on Profitability
SELECT
    Discount_Percentage,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Discount_Percentage
ORDER BY Discount_Percentage;

-- 5.16 Promotion Code Performance
SELECT
    Promotion_Code,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Promotion_Code
ORDER BY Total_Profit DESC;


-- =============================================
-- SALES CHANNEL, STORE & EMPLOYEE ANALYSIS
-- =============================================

-- 5.17 Sales Channel Performance
SELECT
    Sales_Channel,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Sales_Amount) / COUNT(DISTINCT Order_ID) AS Average_Order_Value
FROM Retail_Sales_Cleaned
GROUP BY Sales_Channel
ORDER BY Total_Profit DESC;

-- 5.18 Store Performance
SELECT
    Store_ID,
    Store_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    CONCAT(CAST(SUM(Profit) * 100.0 / SUM(Sales_Amount) AS DECIMAL(10,2)), '%') AS Profit_Margin
FROM Retail_Sales_Cleaned
GROUP BY Store_ID, Store_Name
ORDER BY Total_Profit DESC;

-- 5.19 Sales Representative Performance
SELECT
    Sales_Representative,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Sales_Amount) / COUNT(DISTINCT Order_ID) AS Average_Order_Value
FROM Retail_Sales_Cleaned
GROUP BY Sales_Representative
ORDER BY Total_Profit DESC;


-- =============================================
-- RETURNS & OPERATIONAL ANALYSIS
-- =============================================

-- 5.20 Return Reason Analysis
SELECT
    Return_Reason,
    COUNT(DISTINCT Order_ID) AS Returned_Orders,
    SUM(Quantity) AS Returned_Quantity,
    SUM(Sales_Amount) AS Returned_Sales
FROM Retail_Sales_Cleaned
WHERE Return_Flag = 'Returned'
GROUP BY Return_Reason
ORDER BY Returned_Orders DESC;

-- 5.21 Shipping Method Performance
SELECT
    Shipping_Method,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    AVG(Delivery_Days) AS Average_Delivery_Days,
    COUNT(DISTINCT CASE WHEN Return_Flag = 'Returned' THEN Order_ID END) AS Returned_Orders,
    CONCAT(CAST(COUNT(DISTINCT CASE WHEN Return_Flag = 'Returned' THEN Order_ID END) * 100.0 /
    COUNT(DISTINCT Order_ID) AS DECIMAL(10,2)), '%') AS Return_Rate
FROM Retail_Sales_Cleaned
GROUP BY Shipping_Method
ORDER BY Average_Delivery_Days;

-- 5.22 Customer Rating & Delivery Performance
-- Analyse how delivery duration relates to average customer ratings.
SELECT
    Delivery_Days,
    COUNT(*) AS Total_Transactions,
    AVG(Customer_Rating) AS Average_Rating,
    SUM(Sales_Amount) AS Total_Sales
FROM Retail_Sales_Cleaned
GROUP BY Delivery_Days
ORDER BY Delivery_Days;

-- 5.23 Inventory & Product Demand Analysis
SELECT
    Product_ID,
    Product_Name,
    AVG(Inventory_Level) AS Average_Inventory,
    SUM(Quantity) AS Total_Quantity_Sold,
    SUM(Sales_Amount) AS Total_Sales
FROM Retail_Sales_Cleaned
GROUP BY Product_ID, Product_Name
ORDER BY Average_Inventory DESC, Total_Quantity_Sold ASC;


-- =============================================
-- PAYMENT & TIME ANALYSIS
-- =============================================

-- 5.24 Payment Method Analysis
SELECT
    Payment_Method,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Sales_Amount) / COUNT(DISTINCT Order_ID) AS Average_Order_Value
FROM Retail_Sales_Cleaned
GROUP BY Payment_Method
ORDER BY Total_Sales DESC;

-- =============================================
-- TIME-BASED BUSINESS ANALYSIS
-- =============================================

-- 5.25 Peak Sales Period & Business Seasonality
SELECT
    MONTH(Order_Date) AS Order_Month,
    DATENAME(MONTH, Order_Date) AS Month_Name,
    SUM(Sales_Amount) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM Retail_Sales_Cleaned
GROUP BY MONTH(Order_Date), DATENAME(MONTH, Order_Date)
ORDER BY Total_Sales DESC;

-- 5.26 Delivery Delay & Return Analysis
-- Analyse how delivery duration relates to transaction return rates.
SELECT
    Delivery_Days,
    COUNT(*) AS Total_Transactions,
    COUNT(CASE WHEN Return_Flag = 'Returned' THEN 1 END) AS Returned_Transactions,
    CONCAT(CAST(
        COUNT(CASE WHEN Return_Flag = 'Returned' THEN 1 END) * 100.0 /
        COUNT(*) AS DECIMAL(10,2)), '%') AS Return_Rate
FROM Retail_Sales_Cleaned
GROUP BY Delivery_Days
ORDER BY Delivery_Days;

-- 5.27 Monthly Running Sales & Profit
SELECT
    Order_Year,
    Order_Month,
    Monthly_Sales,
    Monthly_Profit,
    SUM(Monthly_Sales) OVER (PARTITION BY Order_Year ORDER BY Order_Month) AS Running_Sales,
    SUM(Monthly_Profit) OVER (PARTITION BY Order_Year ORDER BY Order_Month) AS Running_Profit
FROM (SELECT
        YEAR(Order_Date) AS Order_Year,
        MONTH(Order_Date) AS Order_Month,
        SUM(Sales_Amount) AS Monthly_Sales,
        SUM(Profit) AS Monthly_Profit
    FROM Retail_Sales_Cleaned
    GROUP BY YEAR(Order_Date), MONTH(Order_Date))t
ORDER BY Order_Year, Order_Month;

-- 5.28 Best & Worst Sales Month in Each Year
-- Identify the highest and lowest revenue-generating months for each year.
WITH Monthly_Sales AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        DATENAME(MONTH, Order_Date) AS Order_Month,
        MONTH(Order_Date) AS Month_Number,
        SUM(Sales_Amount) AS Total_Sales
    FROM Retail_Sales_Cleaned
    GROUP BY YEAR(Order_Date), DATENAME(MONTH, Order_Date), MONTH(Order_Date)
),
Sales_Ranking AS (
    SELECT
        Order_Year,
        Order_Month,
        Month_Number,
        Total_Sales,
        MAX(Total_Sales) OVER (PARTITION BY Order_Year) AS Highest_Sales,
        MIN(Total_Sales) OVER (PARTITION BY Order_Year) AS Lowest_Sales
    FROM Monthly_Sales
)
SELECT
    Order_Year,
    Order_Month,
    Total_Sales,
    CASE
        WHEN Total_Sales = Highest_Sales THEN 'Highest Sales'
        WHEN Total_Sales = Lowest_Sales THEN 'Lowest Sales'
    END AS Sales_Performance
FROM Sales_Ranking
WHERE Total_Sales = Highest_Sales
   OR Total_Sales = Lowest_Sales
ORDER BY Order_Year, Month_Number;

-- =============================================
-- END OF ANALYSIS
-- =============================================
