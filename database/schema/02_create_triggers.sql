/*
 * Retailability Namibia - Inventory Management System
 * Database Triggers
 * 
 * Description: Creates all triggers for automated inventory management
 * Author: [Your Name]
 * Created: January 2024
 * 
 * Prerequisites: 
 * - 01_create_tables.sql must be executed first
 * 
 * Triggers created:
 * - after_stock_movement: Updates inventory after stock movements
 * - check_stock_level: Monitors and alerts on low stock
 * - inventory_audit_trigger: Maintains audit trail of inventory changes
 */

USE RetailabilityNamibia;

DELIMITER //

/*
 * Trigger: after_stock_movement
 * Automatically updates inventory levels after any stock movement
 * Handles: Sales, Transfers, Receiving, Returns
 */
CREATE TRIGGER after_stock_movement
AFTER INSERT ON StockMovements
FOR EACH ROW
BEGIN
    -- For transfers between stores
    IF NEW.MovementType = 'TRANSFER' THEN
        -- Reduce stock from source store
        UPDATE Inventory i
        JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
        SET i.Quantity = i.Quantity - NEW.Quantity
        WHERE sp.StoreID = NEW.FromStoreID 
        AND sp.ProductID = (SELECT ProductID FROM StoreProducts WHERE StoreProductID = NEW.StoreProductID);
        
        -- Add stock to destination store
        UPDATE Inventory i
        JOIN StoreProducts sp ON i.StoreProductID = sp.StoreProductID
        SET i.Quantity = i.Quantity + NEW.Quantity
        WHERE sp.StoreID = NEW.ToStoreID
        AND sp.ProductID = (SELECT ProductID FROM StoreProducts WHERE StoreProductID = NEW.StoreProductID);
    
    -- For sales transactions
    ELSEIF NEW.MovementType = 'SALES' THEN
        UPDATE Inventory i
        SET i.Quantity = i.Quantity - NEW.Quantity
        WHERE i.StoreProductID = NEW.StoreProductID;
    
    -- For receiving new stock
    ELSEIF NEW.MovementType = 'RECEIVING' THEN
        UPDATE Inventory i
        SET i.Quantity = i.Quantity + NEW.Quantity
        WHERE i.StoreProductID = NEW.StoreProductID;
    
    -- For returns
    ELSEIF NEW.MovementType = 'RETURN' THEN
        UPDATE Inventory i
        SET i.Quantity = i.Quantity + NEW.Quantity
        WHERE i.StoreProductID = NEW.StoreProductID;
    END IF;
END//

/*
 * Trigger: check_stock_level
 * Monitors inventory levels and creates alerts for low stock
 */
CREATE TRIGGER check_stock_level
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    DECLARE v_reorder_level INT;
    DECLARE v_store_id INT;
    DECLARE v_product_id INT;
    
    -- Get relevant information
    SELECT sp.ReorderLevel, sp.StoreID, sp.ProductID
    INTO v_reorder_level, v_store_id, v_product_id
    FROM StoreProducts sp
    WHERE sp.StoreProductID = NEW.StoreProductID;
    
    -- Create alert if stock is at or below reorder level
    IF NEW.Quantity <= v_reorder_level THEN
        INSERT INTO LowStockAlerts (
            StoreID,
            ProductID,
            CurrentQuantity,
            ReorderLevel,
            AlertDate
        ) VALUES (
            v_store_id,
            v_product_id,
            NEW.Quantity,
            v_reorder_level,
            NOW()
        );
    END IF;
END//

/*
 * Trigger: inventory_audit_trigger
 * Maintains an audit trail of all inventory changes
 */
CREATE TRIGGER inventory_audit_trigger
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    INSERT INTO InventoryAudit (
        InventoryID,
        StoreProductID,
        StoreID,
        OldQuantity,
        NewQuantity,
        ChangeType,
        ChangedBy
    )
    SELECT
        NEW.InventoryID,
        NEW.StoreProductID,
        sp.StoreID,
        OLD.Quantity,
        NEW.Quantity,
        CASE
            WHEN NEW.Quantity > OLD.Quantity THEN 'INCREASE'
            ELSE 'DECREASE'
        END,
        CURRENT_USER()
    FROM StoreProducts sp
    WHERE sp.StoreProductID = NEW.StoreProductID;
END//

DELIMITER ;