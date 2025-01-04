/*
 * Retailability Namibia - Security Setup
 * Author: Tileni
 * Created: 4 January 2024
 * 
 * This script sets up:
 * - Database users and roles
 * - Access permissions
 * - Security procedures
 */

USE RetailabilityNamibia;
DELIMITER //

-- Create application roles with specific permissions
CREATE ROLE 'store_manager',
           'store_staff',
           'inventory_manager',
           'finance_admin',
           'system_admin';

-- Grant permissions for Store Manager
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.* TO 'store_manager';
GRANT EXECUTE ON PROCEDURE sp_ProcessDamagedStock TO 'store_manager';
GRANT EXECUTE ON PROCEDURE sp_CheckStockLevels TO 'store_manager';
GRANT EXECUTE ON PROCEDURE sp_CancelLayby TO 'store_manager';
GRANT EXECUTE ON PROCEDURE sp_StoreDashboard TO 'store_manager';

-- Grant permissions for Store Staff
GRANT SELECT ON RetailabilityNamibia.Products TO 'store_staff';
GRANT SELECT ON RetailabilityNamibia.StoreProducts TO 'store_staff';
GRANT SELECT ON RetailabilityNamibia.Inventory TO 'store_staff';
GRANT SELECT, INSERT ON RetailabilityNamibia.LaybyTransactions TO 'store_staff';
GRANT EXECUTE ON PROCEDURE sp_CheckStockLevels TO 'store_staff';

-- Grant permissions for Inventory Manager
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.Products TO 'inventory_manager';
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.StoreProducts TO 'inventory_manager';
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.Inventory TO 'inventory_manager';
GRANT EXECUTE ON PROCEDURE sp_ProcessDamagedStock TO 'inventory_manager';
GRANT EXECUTE ON PROCEDURE sp_ManageReorderLevels TO 'inventory_manager';

-- Create security procedures

-- User Authentication
CREATE PROCEDURE sp_AuthenticateUser(
    IN p_username VARCHAR(50),
    IN p_password_hash VARCHAR(255),
    OUT p_is_authenticated BOOLEAN,
    OUT p_user_role VARCHAR(50)
)
BEGIN
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_role_name VARCHAR(50);
    
    -- Check credentials
    SELECT 
        e.EmployeeID IS NOT NULL,
        r.RoleName
    INTO p_is_authenticated, p_user_role
    FROM Employees e
    JOIN EmployeeRoles r ON e.RoleID = r.RoleID
    WHERE e.Email = p_username 
    AND e.IsActive = TRUE
    LIMIT 1;
    
    -- Log authentication attempt
    INSERT INTO SystemAuditLog (
        EntityType,
        EntityID,
        Action,
        Details,
        Severity,
        IPAddress
    )
    VALUES (
        'AUTH',
        NULL,
        CASE WHEN p_is_authenticated THEN 'LOGIN_SUCCESS' ELSE 'LOGIN_FAILURE' END,
        CONCAT('Login attempt for user: ', p_username),
        CASE WHEN p_is_authenticated THEN 'INFO' ELSE 'WARNING' END,
        CONNECTION_ID()
    );
END //

-- Check User Permission
CREATE PROCEDURE sp_CheckUserPermission(
    IN p_employee_id INT,
    IN p_permission_name VARCHAR(50),
    OUT p_has_permission BOOLEAN
)
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM Employees e
        JOIN EmployeeRoles r ON e.RoleID = r.RoleID
        WHERE e.EmployeeID = p_employee_id
        AND e.IsActive = TRUE
        AND (
            (p_permission_name = 'APPROVE_LAYBY' AND r.CanApproveLayby = TRUE) OR
            (p_permission_name = 'APPROVE_CREDIT' AND r.CanApproveCreditAccounts = TRUE) OR
            (r.AccessLevel >= 
                CASE p_permission_name
                    WHEN 'VIEW_REPORTS' THEN 2
                    WHEN 'MANAGE_INVENTORY' THEN 3
                    WHEN 'MANAGE_USERS' THEN 4
                    ELSE 1
                END
            )
        )
    ) INTO p_has_permission;
END //

-- Create Application User
CREATE PROCEDURE sp_CreateApplicationUser(
    IN p_employee_id INT,
    IN p_username VARCHAR(50),
    IN p_password_hash VARCHAR(255),
    IN p_created_by INT
)
BEGIN
    DECLARE v_can_manage_users BOOLEAN;
    
    -- Check if creator has permission
    CALL sp_CheckUserPermission(p_created_by, 'MANAGE_USERS', v_can_manage_users);
    
    IF NOT v_can_manage_users THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Unauthorized to create users';
    END IF;
    
    -- Create user and grant role
    SET @sql = CONCAT(
        'CREATE USER ''', p_username, '''@''localhost'' ',
        'IDENTIFIED BY ''', p_password_hash, ''''
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Log user creation
    INSERT INTO SystemAuditLog (
        EntityType,
        EntityID,
        UserID,
        Action,
        Details,
        Severity
    )
    VALUES (
        'USER',
        p_employee_id,
        p_created_by,
        'USER_CREATED',
        CONCAT('Created application user for employee: ', p_employee_id),
        'INFO'
    );
END //

-- Password Reset Procedure
CREATE PROCEDURE sp_ResetUserPassword(
    IN p_employee_id INT,
    IN p_new_password_hash VARCHAR(255),
    IN p_reset_by INT
)
BEGIN
    DECLARE v_can_manage_users BOOLEAN;
    DECLARE v_username VARCHAR(50);
    
    -- Check permissions
    CALL sp_CheckUserPermission(p_reset_by, 'MANAGE_USERS', v_can_manage_users);
    
    IF NOT v_can_manage_users THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Unauthorized to reset passwords';
    END IF;
    
    -- Get username
    SELECT Email INTO v_username
    FROM Employees
    WHERE EmployeeID = p_employee_id;
    
    -- Reset password
    SET @sql = CONCAT(
        'ALTER USER ''', v_username, '''@''localhost'' ',
        'IDENTIFIED BY ''', p_new_password_hash, ''''
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Log password reset
    INSERT INTO SystemAuditLog (
        EntityType,
        EntityID,
        UserID,
        Action,
        Details,
        Severity
    )
    VALUES (
        'USER',
        p_employee_id,
        p_reset_by,
        'PASSWORD_RESET',
        'Password reset performed',
        'WARNING'
    );
END //

DELIMITER ;

-- Create default admin user
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'temporaryPassword123!';
GRANT 'system_admin' TO 'admin'@'localhost';