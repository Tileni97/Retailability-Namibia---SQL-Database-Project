/*
 * Common Inventory Operations Queries
 * These queries handle daily inventory operations
 */

-- Check Current Stock Levels
SELECT 
    s.StoreName,
    p.SKU,
    p.ProductName,
    i.Quantity as CurrentStock,
    sp.ReorderLevel,
    CASE 
        WHEN i.Quantity <= sp.ReorderLevel THEN 'Reorder Required'
        WHEN i.Quantity = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END as StockStatus
FROM Inventory i
JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
ORDER BY s.StoreName, StockStatus, p.ProductName;

-- Find Products Below Reorder Level
SELECT 
    s.StoreName,
    p.SKU,
    p.ProductName,
    i.Quantity as CurrentStock,
    sp.ReorderLevel,
    (sp.ReorderLevel - i.Quantity) as QuantityNeeded
FROM Inventory i
JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
WHERE i.Quantity <= sp.ReorderLevel
ORDER BY (sp.ReorderLevel - i.Quantity) DESC;

-- Track Stock Movement History
SELECT 
    sm.MovementDate,
    s_from.StoreName as FromStore,
    s_to.StoreName as ToStore,
    p.SKU,
    p.ProductName,
    sm.Quantity,
    sm.MovementType,
    sm.Reference
FROM StockMovements sm
JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
LEFT JOIN Stores s_from ON sm.FromStoreID = s_from.StoreID
LEFT JOIN Stores s_to ON sm.ToStoreID = s_to.StoreID
ORDER BY sm.MovementDate DESC;

-- Calculate Stock Value
SELECT 
    s.StoreName,
    SUM(i.Quantity * sp.UnitPrice) as TotalStockValue,
    COUNT(DISTINCT p.ProductID) as UniqueProducts,
    SUM(i.Quantity) as TotalUnits
FROM Inventory i
JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
GROUP BY s.StoreName
ORDER BY TotalStockValue DESC;