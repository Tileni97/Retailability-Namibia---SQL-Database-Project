/*
 * Daily Reporting Queries
 * Common queries for daily business operations
 */

-- 1. Daily Sales Summary by Store
SELECT 
    s.StoreName,
    COUNT(DISTINCT sm.MovementID) as Transactions,
    SUM(sm.Quantity) as UnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue,
    AVG(sm.Quantity * sp.UnitPrice) as AverageTransactionValue
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Stores s ON sp.StoreID = s.StoreID
WHERE sm.MovementType = 'SALES'
AND DATE(sm.MovementDate) = CURRENT_DATE
GROUP BY s.StoreName;

-- 2. Low Stock Alert Report
SELECT 
    s.StoreName,
    p.SKU,
    p.ProductName,
    i.Quantity as CurrentStock,
    sp.ReorderLevel,
    (sp.ReorderLevel - i.Quantity) as UnitsNeeded
FROM Inventory i
JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
WHERE i.Quantity <= sp.ReorderLevel
ORDER BY s.StoreName, UnitsNeeded DESC;

-- 3. Top Selling Products Today
SELECT 
    p.ProductName,
    SUM(sm.Quantity) as UnitsSold,
    SUM(sm.Quantity * sp.UnitPrice) as Revenue
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
WHERE sm.MovementType = 'SALES'
AND DATE(sm.MovementDate) = CURRENT_DATE
GROUP BY p.ProductName
ORDER BY UnitsSold DESC
LIMIT 10;