/*
 * Retailability Namibia - Stored Procedures
 * Author: Tileni
 * Created: 4 January 2024
 *
 * This script creates stored procedures for:
 * - Inventory Management
 * - Layby Processing
 * - Credit Account Management
 * - Reporting
 */

USE RetailabilityNamibia;
DELIMITER //

/*
 * Inventory Management Procedures
 */

-- Add new stock to inventory
CREATE PROCEDURE sp_AddStock(
    IN p_store_product_id INT,
    IN p_quantity INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE current_stock INT;
    
    -- Get current stock level
    SELECT AvailableStock INTO current_stock
    FROM Inventory
    WHERE StoreProductID = p_store_product_id;
    
    -- Update inventory
    UPDATE Inventory
    SET AvailableStock = AvailableStock + p_quantity,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StoreProductID = p_store_product_id;
    
    -- Log the stock addition
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'INVENTORY',
        p_store_product_id,
        p_employee_id,
        'STOCK_ADDED',
        CONCAT('Added ', p_quantity, ' units. Previous stock: ', current_stock),
        'INFO'
    );
END//

-- Transfer stock between stores
CREATE PROCEDURE sp_TransferStock(
    IN p_from_store_id INT,
    IN p_to_store_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE v_from_store_product_id INT;
    DECLARE v_to_store_product_id INT;
    DECLARE v_available_stock INT;
    
    -- Get source store product ID and check stock
    SELECT StoreProductID, i.AvailableStock
    INTO v_from_store_product_id, v_available_stock
    FROM StoreProducts sp
    JOIN Inventory i ON sp.StoreProductID = i.StoreProductID
    WHERE sp.StoreID = p_from_store_id 
    AND sp.ProductID = p_product_id;
    
    -- Validate stock availability
    IF v_available_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock for transfer';
    END IF;
    
    -- Get destination store product ID
    SELECT StoreProductID INTO v_to_store_product_id
    FROM StoreProducts
    WHERE StoreID = p_to_store_id 
    AND ProductID = p_product_id;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Reduce stock from source
    UPDATE Inventory
    SET AvailableStock = AvailableStock - p_quantity
    WHERE StoreProductID = v_from_store_product_id;
    
    -- Add stock to destination
    UPDATE Inventory
    SET AvailableStock = AvailableStock + p_quantity
    WHERE StoreProductID = v_to_store_product_id;
    
    -- Record transfer
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'STOCK_TRANSFER',
        v_from_store_product_id,
        p_employee_id,
        'TRANSFER',
        CONCAT('Transferred ', p_quantity, ' units from Store ', p_from_store_id, ' to Store ', p_to_store_id),
        'INFO'
    );
    
    COMMIT;
END//

/*
 * Layby Management Procedures
 */

-- Create new layby
CREATE PROCEDURE sp_CreateLayby(
    IN p_customer_id INT,
    IN p_store_product_id INT,
    IN p_employee_id INT,
    IN p_total_amount DECIMAL(10,2),
    IN p_deposit_amount DECIMAL(10,2),
    IN p_deposit_percentage DECIMAL(5,2)
)
BEGIN
    DECLARE v_balance_due DECIMAL(10,2);
    
    -- Calculate balance due
    SET v_balance_due = p_total_amount - p_deposit_amount;
    
    -- Validate minimum deposit
    IF (p_deposit_amount / p_total_amount * 100) < p_deposit_percentage THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deposit amount is below required percentage';
    END IF;
    
    -- Create layby transaction
    INSERT INTO LaybyTransactions (
        CustomerID,
        StoreProductID,
        EmployeeID,
        TotalAmount,
        DepositPaid,
        BalanceDue,
        DepositPercentage,
        StartDate,
        DueDate
    )
    VALUES (
        p_customer_id,
        p_store_product_id,
        p_employee_id,
        p_total_amount,
        p_deposit_amount,
        v_balance_due,
        p_deposit_percentage,
        CURRENT_TIMESTAMP,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 6 MONTH)
    );
    
    -- Update inventory (trigger will handle stock reservation)
END//

/*
 * Credit Account Management
 */

-- Process credit account payment
CREATE PROCEDURE sp_ProcessCreditPayment(
    IN p_account_id INT,
    IN p_payment_amount DECIMAL(10,2),
    IN p_employee_id INT
)
BEGIN
    DECLARE v_current_balance DECIMAL(10,2);
    DECLARE v_new_balance DECIMAL(10,2);
    
    -- Get current balance
    SELECT CurrentBalance INTO v_current_balance
    FROM CreditAccounts
    WHERE AccountID = p_account_id;
    
    SET v_new_balance = v_current_balance - p_payment_amount;
    
    -- Update account
    UPDATE CreditAccounts
    SET CurrentBalance = v_new_balance,
        LastPaymentDate = CURRENT_TIMESTAMP,
        LastPaymentAmount = p_payment_amount,
        NextPaymentDueDate = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)
    WHERE AccountID = p_account_id;
    
    -- Log payment
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'CREDIT_ACCOUNT',
        p_account_id,
        p_employee_id,
        'PAYMENT',
        CONCAT('Payment of ', p_payment_amount, ' processed. New balance: ', v_new_balance),
        'INFO'
    );
END//

/*
 * Reporting Procedures
 */

-- Get store performance report
CREATE PROCEDURE sp_GetStorePerformance(
    IN p_store_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Add your report query here
    -- This is a placeholder for the actual implementation
    SELECT 
        s.StoreName,
        COUNT(DISTINCT l.LaybyID) as TotalLaybys,
        SUM(l.TotalAmount) as TotalLaybyAmount,
        COUNT(DISTINCT c.AccountID) as ActiveCreditAccounts,
        SUM(c.CurrentBalance) as TotalCreditBalance
    FROM Stores s
    LEFT JOIN LaybyTransactions l ON s.StoreID = 
        (SELECT StoreID FROM StoreProducts WHERE StoreProductID = l.StoreProductID)
        AND l.StartDate BETWEEN p_start_date AND p_end_date
    LEFT JOIN Customers cu ON l.CustomerID = cu.CustomerID
    LEFT JOIN CreditAccounts c ON cu.CustomerID = c.CustomerID
    WHERE s.StoreID = p_store_id
    GROUP BY s.StoreName;
END//

DELIMITER ;