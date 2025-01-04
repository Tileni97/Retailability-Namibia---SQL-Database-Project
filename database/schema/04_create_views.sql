/*
 * Retailability Namibia - Inventory Management System
 * Database Views
 * 
 * Description: Creates all views for reporting and analysis
 * Author: Tileni
 * Created: 04 January 2024
 * 
 * Prerequisites: 
 * - 01_create_tables.sql must be executed first
 * 
 * Views created:
 * - vw_ProductPerformance: Product sales and stock analysis
 * - vw_StorePerformance: Store performance metrics
 * - vw_CategoryPerformance: Category analysis
 * - vw_LowStockItems: Low stock monitoring
 * - vw_DailySalesSummary: Daily sales overview
 */

USE RetailabilityNamibia;

/*
 * View: vw_ProductPerformance
 * Comprehensive product performance analysis
 */
CREATE OR REPLACE VIEW vw_ProductPerformance AS
SELECT 
    sc.ChainName,
    s.StoreName,
    p.SKU,
    p.ProductName,
    c.CategoryName,
    SUM(CASE WHEN sm.MovementType = 'SALES' THEN sm.Quantity ELSE 0 END) as TotalUnitsSold,
    SUM(CASE WHEN sm.MovementType = 'SALES' THEN sm.Quantity * sp.UnitPrice ELSE 0 END) as TotalRevenue,
    AVG(i.Quantity) as AverageStock,
    sp.ReorderLevel
FROM Products p
JOIN StoreProducts sp ON p.ProductID = sp.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
JOIN StoreChains sc ON s.ChainID = sc.ChainID
JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN StockMovements sm ON sp.StoreProductID = sm.StoreProductID
JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
GROUP BY sc.ChainName, s.StoreName, p.SKU, p.ProductName, c.CategoryName, sp.ReorderLevel;

/*
 * View: vw_StorePerformance
 * Store performance metrics
 */
CREATE OR REPLACE VIEW vw_StorePerformance AS
SELECT 
    sc.ChainName,
    s.StoreName,
    s.Region,
    COUNT(DISTINCT sm.MovementID) as TotalTransactions,
    SUM(CASE WHEN sm.MovementType = 'SALES' THEN sm.Quantity ELSE 0 END) as TotalUnitsSold,
    SUM(CASE WHEN sm.MovementType = 'SALES' THEN sm.Quantity * sp.UnitPrice ELSE 0 END) as TotalRevenue,
    COUNT(DISTINCT p.ProductID) as UniqueProducts,
    SUM(i.Quantity) as TotalCurrentStock
FROM Stores s
JOIN StoreChains sc ON s.ChainID = sc.ChainID
LEFT JOIN StoreProducts sp ON s.StoreID = sp.StoreID
LEFT JOIN Products p ON sp.ProductID = p.ProductID
LEFT JOIN StockMovements sm ON sp.StoreProductID = sm.StoreProductID
LEFT JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
GROUP BY sc.ChainName, s.StoreName, s.Region;

/*
 * View: vw_LowStockItems
 * Monitors items needing reorder
 */
CREATE OR REPLACE VIEW vw_LowStockItems AS
SELECT 
    sc.ChainName,
    s.StoreName,
    p.SKU,
    p.ProductName,
    i.Quantity as CurrentStock,
    sp.ReorderLevel,
    sp.UnitPrice,
    c.CategoryName
FROM Inventory i
JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
JOIN Products p ON sp.ProductID = p.ProductID
JOIN Stores s ON sp.StoreID = s.StoreID
JOIN StoreChains sc ON s.ChainID = sc.ChainID
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE i.Quantity <= sp.ReorderLevel;

/* Add more views as needed... */