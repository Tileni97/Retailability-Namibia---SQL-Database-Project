/*
 * Retailability Namibia - Inventory Management System
 * Table Creation Script
 * 
 * Description: Creates the core database tables for the inventory management system
 * Author: [Your Name]
 * Created: January 2024
 * 
 * This script should be run first in the database setup process.
 * Prerequisites: None
 * 
 * Tables created:
 * - StoreChains: Master table for retail brands
 * - Stores: Individual store locations
 * - Categories: Product categorization
 * - Products: Product master list
 * - StoreProducts: Store-specific product details
 * - Inventory: Current stock levels
 * - StockMovements: Stock transaction history
 * - InventoryAudit: Audit trail for inventory changes
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
 * Stores information about each retail brand operated by Retailability in Namibia
 */
CREATE TABLE StoreChains (
    ChainID INT PRIMARY KEY AUTO_INCREMENT,
    ChainName VARCHAR(50) NOT NULL UNIQUE COMMENT 'Unique brand name',
    Description TEXT COMMENT 'Brand description and positioning',
    HeadOfficeLocation VARCHAR(100) COMMENT 'Location of chain headquarters',
    ContactEmail VARCHAR(100) COMMENT 'Primary contact email',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Master table for retail chains';

/*
 * Stores Table
 * Individual store locations for each retail chain
 */
CREATE TABLE Stores (
    StoreID INT PRIMARY KEY AUTO_INCREMENT,
    ChainID INT NOT NULL COMMENT 'Reference to parent chain',
    StoreName VARCHAR(100) NOT NULL COMMENT 'Official store name',
    Location VARCHAR(100) NOT NULL COMMENT 'Physical address',
    Region VARCHAR(50) COMMENT 'Geographic region in Namibia',
    ContactPerson VARCHAR(100) COMMENT 'Store manager or primary contact',
    ContactEmail VARCHAR(100) COMMENT 'Store contact email',
    ContactPhone VARCHAR(20) COMMENT 'Store contact number',
    IsActive BOOLEAN DEFAULT TRUE COMMENT 'Store operational status',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ChainID) REFERENCES StoreChains(ChainID)
) COMMENT 'Store locations and details';

/*
 * Categories Table
 * Product category hierarchy
 */
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    CategoryName VARCHAR(50) NOT NULL COMMENT 'Category name',
    ParentCategoryID INT COMMENT 'Parent category for hierarchical structure',
    Description TEXT COMMENT 'Category description',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ParentCategoryID) REFERENCES Categories(CategoryID)
) COMMENT 'Product categorization hierarchy';

/*
 * Products Table
 * Master product list
 */
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    SKU VARCHAR(50) UNIQUE NOT NULL COMMENT 'Unique product identifier',
    ProductName VARCHAR(100) NOT NULL COMMENT 'Product name',
    CategoryID INT COMMENT 'Product category',
    Description TEXT COMMENT 'Product description',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
) COMMENT 'Master product catalog';

/*
 * StoreProducts Table
 * Store-specific product details including pricing
 */
CREATE TABLE StoreProducts (
    StoreProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductID INT NOT NULL COMMENT 'Reference to master product',
    StoreID INT NOT NULL COMMENT 'Store carrying the product',
    UnitPrice DECIMAL(10,2) NOT NULL COMMENT 'Store-specific price',
    ReorderLevel INT DEFAULT 10 COMMENT 'Minimum stock level before reorder',
    IsActive BOOLEAN DEFAULT TRUE COMMENT 'Product availability in store',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ModifiedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    UNIQUE KEY unique_store_product (StoreID, ProductID)
) COMMENT 'Store-specific product details';

/*
 * Inventory Table
 * Current stock levels
 */
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY AUTO_INCREMENT,
    StoreProductID INT NOT NULL COMMENT 'Reference to store product',
    Quantity INT DEFAULT 0 COMMENT 'Current stock quantity',
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (StoreProductID) REFERENCES StoreProducts(StoreProductID)
) COMMENT 'Current inventory levels';

/*
 * StockMovements Table
 * Records all inventory transactions
 */
CREATE TABLE StockMovements (
    MovementID INT PRIMARY KEY AUTO_INCREMENT,
    FromStoreID INT COMMENT 'Source store for transfers',
    ToStoreID INT COMMENT 'Destination store for transfers',
    StoreProductID INT NOT NULL COMMENT 'Product being moved',
    Quantity INT NOT NULL COMMENT 'Quantity moved',
    MovementType ENUM('TRANSFER', 'RECEIVING', 'SALES', 'RETURN', 'ADJUSTMENT') NOT NULL COMMENT 'Type of movement',
    MovementDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Reference VARCHAR(50) COMMENT 'Transaction reference number',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (FromStoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (ToStoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (StoreProductID) REFERENCES StoreProducts(StoreProductID)
) COMMENT 'Stock movement history';

/*
 * InventoryAudit Table
 * Audit trail for inventory changes
 */
CREATE TABLE InventoryAudit (
    AuditID INT PRIMARY KEY AUTO_INCREMENT,
    InventoryID INT NOT NULL COMMENT 'Reference to inventory record',
    StoreProductID INT NOT NULL COMMENT 'Product affected',
    StoreID INT NOT NULL COMMENT 'Store location',
    OldQuantity INT COMMENT 'Previous quantity',
    NewQuantity INT COMMENT 'New quantity',
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ChangeType VARCHAR(50) COMMENT 'Type of change',
    ChangedBy VARCHAR(100) COMMENT 'User who made the change',
    FOREIGN KEY (InventoryID) REFERENCES Inventory(InventoryID),
    FOREIGN KEY (StoreProductID) REFERENCES StoreProducts(StoreProductID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID)
) COMMENT 'Audit trail for inventory changes';