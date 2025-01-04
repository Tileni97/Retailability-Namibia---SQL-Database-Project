/*
 * Retailability Namibia - Inventory Management System
 * Stored Procedures
 * 
 * Description: Creates all stored procedures for business operations
 * Author: Tileni
 * Created: January 2024
 * 
 * Prerequisites: 
 * - 01_create_tables.sql must be executed first
 * - 02_create_triggers.sql must be executed first
 * 
 * Procedures created:
 * - TransferStock: Handles stock transfers between stores
 * - GetChainStockStatus: Reports on chain-wide stock levels
 * - AnalyzeProductPerformance: Product performance analytics
 * - CompareStorePerformance: Store performance comparison
 * - AnalyzeInventoryAge: Stock aging analysis
 * - AnalyzeSeasonalPerformance: Seasonal trends analysis
 */

USE RetailabilityNamibia;

DELIMITER //

/*
 * Procedure: TransferStock
 * Handles the transfer of stock between stores
 * 
 * Parameters:
 * - p_from_store_id: Source store
 * - p_to_store_id: Destination store
 * - p_product_id: Product to transfer
 * - p_quantity: Amount to transfer
 * - p_reference: Transaction reference
 */
CREATE PROCEDURE TransferStock(
    IN p_from_store_id INT,
    IN p_to_store_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_reference VARCHAR(50)
)
BEGIN
    DECLARE v_from_store_product_id INT;
    DECLARE v_to_store_product_id INT;
    DECLARE v_current_stock INT;
    
    -- Validate sufficient stock
    SELECT StoreProductID, i.Quantity 
    INTO v_from_store_product_id, v_current_stock
    FROM StoreProducts sp
    JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
    WHERE sp.StoreID = p_from_store_id 
    AND sp.ProductID = p_product_id;
    
    IF v_current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for transfer';
    END IF;
    
    -- Get destination store product ID
    SELECT StoreProductID INTO v_to_store_product_id
    FROM StoreProducts
    WHERE StoreID = p_to_store_id 
    AND ProductID = p_product_id;
    
    -- Create stock movement record
    INSERT INTO StockMovements (
        FromStoreID,
        ToStoreID,
        StoreProductID,
        Quantity,
        MovementType,
        Reference
    ) VALUES (
        p_from_store_id,
        p_to_store_id,
        v_from_store_product_id,
        p_quantity,
        'TRANSFER',
        p_reference
    );
END//

/*
 * Procedure: AnalyzeProductPerformance
 * Analyzes product performance over a specified period
 */
CREATE PROCEDURE AnalyzeProductPerformance(
    IN p_chain_id INT,
    IN p_date_from DATE,
    IN p_date_to DATE
)
BEGIN
    SELECT 
        p.ProductName,
        p.SKU,
        SUM(sm.Quantity) as TotalUnitsSold,
        SUM(sm.Quantity * sp.UnitPrice) as TotalRevenue,
        COUNT(DISTINCT sm.MovementID) as NumberOfTransactions,
        AVG(sp.UnitPrice) as AveragePrice
    FROM StockMovements sm
    JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
    JOIN Products p ON sp.ProductID = p.ProductID
    JOIN Stores s ON sp.StoreID = s.StoreID
    WHERE s.ChainID = p_chain_id
    AND sm.MovementType = 'SALES'
    AND DATE(sm.MovementDate) BETWEEN p_date_from AND p_date_to
    GROUP BY p.ProductName, p.SKU
    ORDER BY TotalRevenue DESC;
END//

/* Add more procedures here... */

DELIMITER ;