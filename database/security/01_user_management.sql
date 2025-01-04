/*
 * Security Setup for Retailability Inventory System
 * This script creates roles and permissions for database users
 */

USE RetailabilityNamibia;

-- Create Roles
CREATE TABLE IF NOT EXISTS Roles (
    RoleID INT PRIMARY KEY AUTO_INCREMENT,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) COMMENT 'User roles definitions';

-- Create Role Permissions
CREATE TABLE IF NOT EXISTS RolePermissions (
    PermissionID INT PRIMARY KEY AUTO_INCREMENT,
    RoleID INT,
    PermissionName VARCHAR(100) NOT NULL,
    Description TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
) COMMENT 'Permissions associated with roles';

-- Create User Sessions Table
CREATE TABLE IF NOT EXISTS UserSessions (
    SessionID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT,
    Token VARCHAR(255) NOT NULL,
    LoginTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ExpiryTime TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    IPAddress VARCHAR(45),
    UserAgent VARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
) COMMENT 'User session tracking';

-- Insert Default Roles
INSERT INTO Roles (RoleName, Description) VALUES
('SuperAdmin', 'Full system access with all privileges'),
('StoreManager', 'Manage store inventory and staff'),
('StoreStaff', 'Handle daily store operations'),
('Auditor', 'View reports and audit trails');

-- Create Database Users and Grant Permissions
-- Store Manager Role
CREATE USER IF NOT EXISTS 'store_manager'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.Products TO 'store_manager'@'localhost';
GRANT SELECT, INSERT, UPDATE ON RetailabilityNamibia.Inventory TO 'store_manager'@'localhost';
GRANT SELECT, INSERT ON RetailabilityNamibia.StockMovements TO 'store_manager'@'localhost';

-- Store Staff Role
CREATE USER IF NOT EXISTS 'store_staff'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT SELECT ON RetailabilityNamibia.Products TO 'store_staff'@'localhost';
GRANT SELECT ON RetailabilityNamibia.Inventory TO 'store_staff'@'localhost';
GRANT INSERT ON RetailabilityNamibia.StockMovements TO 'store_staff'@'localhost';

-- Auditor Role
CREATE USER IF NOT EXISTS 'auditor'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT SELECT ON RetailabilityNamibia.* TO 'auditor'@'localhost';

-- Create Security Procedures
DELIMITER //

-- Procedure to add new user role
CREATE PROCEDURE sp_AddUserRole(
    IN p_user_id INT,
    IN p_role_id INT
)
BEGIN
    INSERT INTO UserRoles (UserID, RoleID)
    VALUES (p_user_id, p_role_id);
END//

-- Procedure to check user permissions
CREATE PROCEDURE sp_CheckUserPermission(
    IN p_user_id INT,
    IN p_permission_name VARCHAR(100),
    OUT p_has_permission BOOLEAN
)
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM Users u
        JOIN UserRoles ur ON u.UserID = ur.UserID
        JOIN RolePermissions rp ON ur.RoleID = rp.RoleID
        WHERE u.UserID = p_user_id
        AND rp.PermissionName = p_permission_name
    ) INTO p_has_permission;
END//

DELIMITER ;