/*
 * Retailability Namibia - Inventory Management System
 * Table Creation Script
 * 
 * Description: Creates the core database tables for the inventory management system
 * Author: Tileni
 * Created: 4 January 2024
 * 
 * This script should be run first in the database setup process.
 * Prerequisites: None
 * 
 * Tables created:
 * - StoreChains: Retail brand management
 * - EmployeeRoles: Role and permission definitions
 * - Stores: Store locations and details
 * - Employees: Employee management
 * - Categories: Product categorization
 * - Suppliers: Supplier management
 * - Products: Product catalog
 * - StoreProducts: Store-specific product details
 * - Inventory: Stock management
 */

-- Create Database with proper character set
CREATE DATABASE IF NOT EXISTS RetailabilityNamibia
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE RetailabilityNamibia;

-- Enable strict mode for better error handling
SET SQL_MODE = 'STRICT_ALL_TABLES';

/*
 * StoreChains Table
 */
CREATE TABLE StoreChains (
    ChainID INT PRIMARY KEY AUTO_INCREMENT,
    ChainName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    HeadOfficeLocation VARCHAR(255),
    ContactEmail VARCHAR(100),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Retail chains';

/*
 * EmployeeRoles Table
 */
CREATE TABLE EmployeeRoles (
    RoleID INT PRIMARY KEY AUTO_INCREMENT,
    RoleName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    AccessLevel INT NOT NULL,
    HierarchyLevel INT NOT NULL,
    CanApproveLayby BOOLEAN DEFAULT FALSE,
    CanApproveCreditAccounts BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Employee roles and permissions';

/*
 * Stores Table
 */
CREATE TABLE Stores (
    StoreID INT PRIMARY KEY AUTO_INCREMENT,
    ChainID INT NOT NULL,
    StoreName VARCHAR(100) NOT NULL,
    Location VARCHAR(255) NOT NULL,
    Region VARCHAR(50),
    ContactPerson VARCHAR(100),
    ContactEmail VARCHAR(100),
    ContactPhone VARCHAR(20),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ChainID) REFERENCES StoreChains(ChainID)
) COMMENT 'Store locations and details';

/*
 * Employees Table
 */
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
    StoreID INT NOT NULL,
    RoleID INT NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    ContactNumber VARCHAR(20),
    Email VARCHAR(100) UNIQUE,
    IsActive BOOLEAN DEFAULT TRUE,
    HireDate DATE NOT NULL,
    EmployeeNumber VARCHAR(20) UNIQUE NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (RoleID) REFERENCES EmployeeRoles(RoleID)
) COMMENT 'Employee management';

/*
 * Categories Table
 */
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    ParentCategoryID INT,
    CategoryName VARCHAR(100) NOT NULL,
    Description TEXT,
    CategoryCode VARCHAR(20) UNIQUE NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ParentCategoryID) REFERENCES Categories(CategoryID)
) COMMENT 'Product categorization';

/*
 * Suppliers Table
 */
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY AUTO_INCREMENT,
    SupplierName VARCHAR(100) NOT NULL,
    ContactPerson VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20),
    Address TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    SupplierCode VARCHAR(20) UNIQUE NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Supplier management';

/*
 * Products Table
 */
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    SupplierID INT NOT NULL,
    CategoryID INT NOT NULL,
    SKU VARCHAR(50) UNIQUE NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    Description TEXT,
    Brand VARCHAR(100),
    Barcode VARCHAR(50) UNIQUE,
    IsLaybyEligible BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    INDEX idx_product_name (ProductName),
    INDEX idx_brand (Brand)
) COMMENT 'Product catalog';

/*
 * StoreProducts Table
 */
CREATE TABLE StoreProducts (
    StoreProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductID INT NOT NULL,
    StoreID INT NOT NULL,
    RegularPrice DECIMAL(10,2) NOT NULL,
    CurrentPrice DECIMAL(10,2) NOT NULL,
    ReorderLevel INT NOT NULL DEFAULT 10,
    ReorderQuantity INT NOT NULL DEFAULT 20,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    UNIQUE KEY unique_store_product (StoreID, ProductID)
) COMMENT 'Store-specific product details';

/*
 * Inventory Table
 */
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY AUTO_INCREMENT,
    StoreProductID INT NOT NULL,
    AvailableStock INT NOT NULL DEFAULT 0,
    ReservedStock INT NOT NULL DEFAULT 0,
    DamagedStock INT NOT NULL DEFAULT 0,
    OrderedStock INT NOT NULL DEFAULT 0,
    MinimumStockLevel INT NOT NULL DEFAULT 5,
    LastStockCheck TIMESTAMP NULL,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (StoreProductID) REFERENCES StoreProducts(StoreProductID)
) COMMENT 'Stock management';

/*
 * Customers Table
 */
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    IDNumber VARCHAR(20) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    Email VARCHAR(100) UNIQUE,
    Address TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    IsCreditWorthy BOOLEAN DEFAULT FALSE,
    RegisteredDate DATETIME NOT NULL,
    LastPurchaseDate DATETIME,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_name (LastName, FirstName)
) COMMENT 'Customer management';

/*
 * CreditAccounts Table
 */
CREATE TABLE CreditAccounts (
    AccountID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    CreditLimit DECIMAL(10,2) NOT NULL,
    CurrentBalance DECIMAL(10,2) NOT NULL DEFAULT 0,
    AccountStatus ENUM('ACTIVE', 'SUSPENDED', 'CLOSED') NOT NULL DEFAULT 'ACTIVE',
    LastPaymentDate DATETIME,
    LastPaymentAmount DECIMAL(10,2),
    NextPaymentDueDate DATETIME,
    MissedPayments INT DEFAULT 0,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
) ENGINE=InnoDB;

/*
 * LaybyTransactions Table
 */
CREATE TABLE LaybyTransactions (
    LaybyID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    StoreProductID INT NOT NULL,
    EmployeeID INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    DepositPaid DECIMAL(10,2) NOT NULL,
    BalanceDue DECIMAL(10,2) NOT NULL,
    DepositPercentage DECIMAL(5,2) NOT NULL,
    StartDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    CancelledDate DATETIME,
    CancellationReason TEXT,
    Status ENUM('ACTIVE', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (StoreProductID) REFERENCES StoreProducts(StoreProductID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
) COMMENT 'Layby transaction management';

/*
 * SystemAuditLog Table
 */
CREATE TABLE SystemAuditLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    EntityType VARCHAR(50) NOT NULL,
    EntityID INT NOT NULL,
    UserID INT NOT NULL,
    Action VARCHAR(50) NOT NULL,
    Details TEXT,
    Severity ENUM('INFO', 'WARNING', 'CRITICAL') NOT NULL DEFAULT 'INFO',
    IPAddress VARCHAR(45),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES Employees(EmployeeID)
) COMMENT 'System audit logging';
