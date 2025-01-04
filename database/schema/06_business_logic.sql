/*
 * Retailability Namibia - Business Logic Procedures
 * Author: Tileni
 * Created: 4 January 2024
 */

USE RetailabilityNamibia;
DELIMITER //

-- Validate and Process Layby Creation
CREATE PROCEDURE sp_ValidateAndCreateLayby(
    IN p_customer_id INT,
    IN p_store_product_id INT,
    IN p_employee_id INT,
    IN p_total_amount DECIMAL(10,2),
    IN p_deposit_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_is_credit_worthy BOOLEAN;
    DECLARE v_is_product_eligible BOOLEAN;
    DECLARE v_minimum_deposit DECIMAL(10,2);
    DECLARE v_product_price DECIMAL(10,2);
    
    -- Check if customer is eligible
    SELECT IsCreditWorthy INTO v_is_credit_worthy
    FROM Customers
    WHERE CustomerID = p_customer_id;
    
    -- Check if product is eligible for layby
    SELECT IsLaybyEligible, sp.CurrentPrice 
    INTO v_is_product_eligible, v_product_price
    FROM Products p
    JOIN StoreProducts sp ON p.ProductID = sp.ProductID
    WHERE sp.StoreProductID = p_store_product_id;
    
    -- Calculate minimum deposit (20% of total amount)
    SET v_minimum_deposit = p_total_amount * 0.20;
    
    -- Validate conditions
    IF NOT v_is_credit_worthy THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer is not eligible for layby';
    END IF;
    
    IF NOT v_is_product_eligible THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product is not eligible for layby';
    END IF;
    
    IF p_deposit_amount < v_minimum_deposit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deposit amount is below minimum requirement';
    END IF;
    
    IF p_total_amount != v_product_price THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total amount does not match product price';
    END IF;
    
    -- If all validations pass, create layby
    CALL sp_CreateLayby(
        p_customer_id,
        p_store_product_id,
        p_employee_id,
        p_total_amount,
        p_deposit_amount,
        20.00  -- Deposit percentage
    );
END //

-- Credit Account Management
CREATE PROCEDURE sp_ManageCreditLimit(
    IN p_customer_id INT,
    IN p_new_limit DECIMAL(10,2),
    IN p_employee_id INT
)
BEGIN
    DECLARE v_current_balance DECIMAL(10,2);
    DECLARE v_missed_payments INT;
    DECLARE v_can_approve BOOLEAN;
    
    -- Check if employee can approve credit
    SELECT CanApproveCreditAccounts INTO v_can_approve
    FROM Employees e
    JOIN EmployeeRoles r ON e.RoleID = r.RoleID
    WHERE e.EmployeeID = p_employee_id;
    
    IF NOT v_can_approve THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee not authorized to modify credit limits';
    END IF;
    
    -- Get current account status
    SELECT CurrentBalance, MissedPayments 
    INTO v_current_balance, v_missed_payments
    FROM CreditAccounts
    WHERE CustomerID = p_customer_id;
    
    -- Validate credit increase
    IF p_new_limit < v_current_balance THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'New credit limit cannot be less than current balance';
    END IF;
    
    IF v_missed_payments > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot increase credit limit with missed payments';
    END IF;
    
    -- Update credit limit
    UPDATE CreditAccounts
    SET CreditLimit = p_new_limit,
        ModifiedAt = CURRENT_TIMESTAMP
    WHERE CustomerID = p_customer_id;
    
    -- Log the change
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'CREDIT_ACCOUNT',
        p_customer_id,
        p_employee_id,
        'CREDIT_LIMIT_CHANGE',
        CONCAT('Credit limit updated to: ', p_new_limit),
        'INFO'
    );
END //

-- Inventory Reorder Management
CREATE PROCEDURE sp_ManageReorderLevels(
    IN p_store_product_id INT,
    IN p_new_reorder_level INT,
    IN p_new_reorder_quantity INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE v_avg_monthly_sales INT;
    DECLARE v_current_stock INT;
    
    -- Calculate average monthly sales
    SELECT COALESCE(AVG(monthly_sales), 0) INTO v_avg_monthly_sales
    FROM (
        SELECT COUNT(*) as monthly_sales
        FROM LaybyTransactions l
        WHERE l.StoreProductID = p_store_product_id
        AND l.StartDate >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
        GROUP BY YEAR(l.StartDate), MONTH(l.StartDate)
    ) sales;
    
    -- Get current stock level
    SELECT AvailableStock INTO v_current_stock
    FROM Inventory
    WHERE StoreProductID = p_store_product_id;
    
    -- Validate reorder levels
    IF p_new_reorder_level < (v_avg_monthly_sales * 0.5) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reorder level too low based on average sales';
    END IF;
    
    IF p_new_reorder_quantity < p_new_reorder_level THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Reorder quantity must be greater than reorder level';
    END IF;
    
    -- Update reorder settings
    UPDATE StoreProducts
    SET ReorderLevel = p_new_reorder_level,
        ReorderQuantity = p_new_reorder_quantity,
        ModifiedAt = CURRENT_TIMESTAMP
    WHERE StoreProductID = p_store_product_id;
    
    -- Log the change
    INSERT INTO SystemAuditLog (
        EntityType, EntityID, UserID, Action, Details, Severity
    )
    VALUES (
        'STORE_PRODUCT',
        p_store_product_id,
        p_employee_id,
        'REORDER_SETTINGS_UPDATE',
        CONCAT('Updated reorder level: ', p_new_reorder_level, 
               ', quantity: ', p_new_reorder_quantity),
        'INFO'
    );
END //

DELIMITER ;