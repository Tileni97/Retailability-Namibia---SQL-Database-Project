/*
 * Retailability Namibia - Advanced Stored Procedures
 * Author: Tileni
 * Created: 4 January 2024
 */

USE RetailabilityNamibia;
DELIMITER //

/*
 * Advanced Inventory Operations
 */

-- Process damaged stock
CREATE PROCEDURE sp_ProcessDamagedStock(
    IN p_store_product_id INT,
    IN p_quantity INT,
    IN p_employee_id INT,
    IN p_reason TEXT
)
BEGIN
    -- Move stock from available to damaged
    UPDATE Inventory
    SET AvailableStock = AvailableStock - p_quantity,
        DamagedStock = DamagedStock + p_quantity
    WHERE StoreProductID = p_store_product_id
    AND AvailableStock >= p_quantity;

    -- Log the damaged stock
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'INVENTORY',
        p_store_product_id,
        p_employee_id,
        'DAMAGED_STOCK',
        CONCAT('Marked ', p_quantity, ' units as damaged. Reason: ', p_reason),
        'WARNING'
    );
END//

-- Check stock levels across all stores
CREATE PROCEDURE sp_CheckStockLevels(
    IN p_product_id INT
)
BEGIN
    SELECT 
        s.StoreName,
        sp.RegularPrice,
        i.AvailableStock,
        i.ReservedStock,
        i.DamagedStock,
        i.OrderedStock,
        CASE 
            WHEN i.AvailableStock <= sp.ReorderLevel THEN 'REORDER REQUIRED'
            WHEN i.AvailableStock <= (sp.ReorderLevel * 1.5) THEN 'LOW STOCK'
            ELSE 'ADEQUATE'
        END as StockStatus
    FROM StoreProducts sp
    JOIN Stores s ON sp.StoreID = s.StoreID
    JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
    WHERE sp.ProductID = p_product_id
    ORDER BY s.StoreName;
END//

/*
 * Advanced Layby Operations
 */

-- Process layby cancellation with refund calculation
CREATE PROCEDURE sp_CancelLayby(
    IN p_layby_id INT,
    IN p_employee_id INT,
    IN p_cancellation_reason TEXT
)
BEGIN
    DECLARE v_store_product_id INT;
    DECLARE v_total_paid DECIMAL(10,2);
    DECLARE v_refund_amount DECIMAL(10,2);
    
    -- Get layby details
    SELECT StoreProductID, DepositPaid
    INTO v_store_product_id, v_total_paid
    FROM LaybyTransactions
    WHERE LaybyID = p_layby_id;
    
    -- Calculate refund (example: 90% refund policy)
    SET v_refund_amount = v_total_paid * 0.9;
    
    START TRANSACTION;
    
    -- Update layby status
    UPDATE LaybyTransactions
    SET Status = 'CANCELLED',
        CancelledDate = CURRENT_TIMESTAMP,
        CancellationReason = p_cancellation_reason
    WHERE LaybyID = p_layby_id;
    
    -- Release reserved stock
    UPDATE Inventory
    SET ReservedStock = ReservedStock - 1,
        AvailableStock = AvailableStock + 1
    WHERE StoreProductID = v_store_product_id;
    
    -- Log cancellation
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'LAYBY',
        p_layby_id,
        p_employee_id,
        'CANCELLED',
        CONCAT('Layby cancelled. Refund amount: ', v_refund_amount),
        'INFO'
    );
    
    COMMIT;
    
    -- Return refund information
    SELECT v_refund_amount as RefundAmount;
END//

/*
 * Complex Reports
 */

-- Product Performance Analysis
CREATE PROCEDURE sp_AnalyzeProductPerformance(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_chain_id INT
)
BEGIN
    WITH LaybyStats AS (
        SELECT 
            sp.ProductID,
            COUNT(*) as TotalLaybys,
            SUM(l.TotalAmount) as TotalLaybyValue,
            SUM(CASE WHEN l.Status = 'CANCELLED' THEN 1 ELSE 0 END) as CancelledLaybys
        FROM LaybyTransactions l
        JOIN StoreProducts sp ON l.StoreProductID = sp.StoreProductID
        WHERE l.StartDate BETWEEN p_start_date AND p_end_date
        GROUP BY sp.ProductID
    )
    SELECT 
        p.SKU,
        p.ProductName,
        c.CategoryName,
        COUNT(DISTINCT sp.StoreID) as StoresStocking,
        SUM(i.AvailableStock) as TotalAvailableStock,
        SUM(i.ReservedStock) as TotalReservedStock,
        COALESCE(ls.TotalLaybys, 0) as TotalLaybys,
        COALESCE(ls.CancelledLaybys, 0) as CancelledLaybys,
        COALESCE(ls.TotalLaybyValue, 0) as TotalLaybyValue,
        AVG(sp.CurrentPrice) as AveragePrice
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    JOIN StoreProducts sp ON p.ProductID = sp.ProductID
    JOIN Stores s ON sp.StoreID = s.StoreID
    JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
    LEFT JOIN LaybyStats ls ON p.ProductID = ls.ProductID
    WHERE s.ChainID = p_chain_id
    GROUP BY p.ProductID, p.SKU, p.ProductName, c.CategoryName
    ORDER BY TotalLaybyValue DESC;
END//

-- Store Performance Dashboard
CREATE PROCEDURE sp_StoreDashboard(
    IN p_store_id INT,
    IN p_date DATE
)
BEGIN
    -- Daily Statistics
    WITH DailyStats AS (
        SELECT 
            COUNT(*) as TotalTransactions,
            SUM(TotalAmount) as TotalValue,
            COUNT(CASE WHEN Status = 'CANCELLED' THEN 1 END) as Cancellations
        FROM LaybyTransactions l
        JOIN StoreProducts sp ON l.StoreProductID = sp.StoreProductID
        WHERE sp.StoreID = p_store_id
        AND DATE(l.StartDate) = p_date
    ),
    -- Stock Status
    StockStatus AS (
        SELECT 
            COUNT(CASE WHEN i.AvailableStock <= sp.ReorderLevel THEN 1 END) as LowStockItems,
            COUNT(CASE WHEN i.AvailableStock = 0 THEN 1 END) as OutOfStockItems
        FROM StoreProducts sp
        JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
        WHERE sp.StoreID = p_store_id
    ),
    -- Credit Account Status
    CreditStatus AS (
        SELECT 
            COUNT(*) as TotalCreditAccounts,
            SUM(CurrentBalance) as TotalCreditBalance,
            COUNT(CASE WHEN MissedPayments > 0 THEN 1 END) as AccountsInArrears
        FROM CreditAccounts ca
        JOIN Customers c ON ca.CustomerID = c.CustomerID
        WHERE ca.AccountStatus = 'ACTIVE'
    )
    -- Combine all statistics
    SELECT 
        s.StoreName,
        d.TotalTransactions,
        d.TotalValue,
        d.Cancellations,
        st.LowStockItems,
        st.OutOfStockItems,
        cr.TotalCreditAccounts,
        cr.TotalCreditBalance,
        cr.AccountsInArrears
    FROM Stores s
    CROSS JOIN DailyStats d
    CROSS JOIN StockStatus st
    CROSS JOIN CreditStatus cr
    WHERE s.StoreID = p_store_id;
END//

DELIMITER ;