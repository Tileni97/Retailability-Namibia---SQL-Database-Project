/*
 * Sales Operations Queries
 * These queries handle sales-related operations
 */

-- Daily Sales Summary
SELECT 
    s.StoreName,
    p.SKU,
    p.ProductName,
    COUNT(sm.MovementID) as NumberOfSales,
    SUM(sm.Quantity) as TotalUnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
WHERE sm.MovementType = 'SALES'
AND DATE(sm.MovementDate) = CURRENT_DATE
GROUP BY s.StoreName, p.SKU, p.ProductName
ORDER BY TotalRevenue DESC;

-- Monthly Sales Trend
SELECT 
    s.StoreName,
    DATE_FORMAT(sm.MovementDate, '%Y-%m') as Month,
    COUNT(DISTINCT sm.MovementID) as NumberOfTransactions,
    SUM(sm.Quantity) as TotalUnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue,
    AVG(sm.Quantity * sp.UnitPrice) as AverageTransactionValue
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Stores s ON sp.StoreID = s.StoreID
WHERE sm.MovementType = 'SALES'
AND sm.MovementDate >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
GROUP BY s.StoreName, Month
ORDER BY s.StoreName, Month;

-- Top Selling Products
SELECT 
    p.SKU,
    p.ProductName,
    c.CategoryName,
    SUM(sm.Quantity) as TotalUnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE sm.MovementType = 'SALES'
AND sm.MovementDate >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY p.SKU, p.ProductName, c.CategoryName
ORDER BY TotalUnitsSold DESC
LIMIT 20;

-- Sales by Category
SELECT 
    c.CategoryName,
    COUNT(DISTINCT p.ProductID) as UniqueProducts,
    SUM(sm.Quantity) as TotalUnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue,
    AVG(sp.UnitPrice) as AveragePrice
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE sm.MovementType = 'SALES'
AND sm.MovementDate >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY c.CategoryName
ORDER BY TotalRevenue DESC;

-- Store Performance Comparison
SELECT 
    s.StoreName,
    COUNT(DISTINCT sm.MovementID) as TotalTransactions,
    SUM(sm.Quantity) as TotalUnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue,
    AVG(sm.Quantity * sp.UnitPrice) as AverageTransactionValue,
    COUNT(DISTINCT p.ProductID) as UniqueProductsSold
FROM Stores s
LEFT JOIN StoreProducts sp ON s.StoreID = sp.StoreID
LEFT JOIN StockMovements sm ON sp.StoreProductID = sm.StoreProductID
LEFT JOIN Products p ON sp.ProductID = p.ProductID
WHERE sm.MovementType = 'SALES'
AND sm.MovementDate >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY s.StoreName
ORDER BY TotalRevenue DESC;
