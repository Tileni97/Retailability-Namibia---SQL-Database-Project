# Retailability Namibia Database Project 🏪

A comprehensive SQL database implementation demonstrating advanced database design and SQL proficiency for Retailability's operations in Namibia.

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Database Design](#database-design)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Documentation](#documentation)

## Project Overview 🎯

This project showcases a robust SQL database design for managing inventory across multiple retail chains including Beaver Canoe, Legit, Style, Edgars, and Swagga in Namibia. It demonstrates proficiency in:

- Advanced SQL features
- Complex database design
- Performance optimization
- Business logic implementation

## Features ✨

### Core SQL Features
- [x] Stored Procedures
- [x] Triggers
- [x] Views
- [x] Complex Joins
- [x] Transaction Management
- [x] Window Functions
- [x] CTEs (Common Table Expressions)

### Business Functions
- [x] Multi-store inventory tracking
- [x] Stock movement management
- [x] Automated reorder alerts
- [x] Price history tracking
- [x] Performance analytics

## Database Design 🗄️

```plaintext
RetailabilityInventorySystem/
├── database/
│   ├── schema/
│   │   ├── 01_create_tables.sql
│   │   ├── 02_create_triggers.sql
│   │   ├── 03_create_procedures.sql
│   │   └── 04_create_views.sql
│   ├── data/
│   │   └── 01_initial_data.sql
│   └── security/
│       └── 01_user_management.sql
└── queries/
    ├── reporting/
    └── operations/
```

## Installation 💻

1. Clone the repository:
```bash
git clone https://github.com/yourusername/retailability-namibia-db.git
cd retailability-namibia-db
```

2. Create the database:
```sql
SOURCE database/schema/01_create_tables.sql
```

3. Set up triggers and procedures:
```sql
SOURCE database/schema/02_create_triggers.sql
SOURCE database/schema/03_create_procedures.sql
SOURCE database/schema/04_create_views.sql
```

4. Load sample data:
```sql
SOURCE database/data/01_initial_data.sql
```

## Usage Examples 📋

### Stock Movement Analysis
```sql
-- Track stock movements with running totals
SELECT 
    sm.ProductID,
    p.ProductName,
    sm.MovementType,
    sm.Quantity,
    sm.MovementDate,
    SUM(CASE 
        WHEN sm.MovementType IN ('RECEIVING', 'RETURN') THEN sm.Quantity
        ELSE -sm.Quantity 
    END) OVER (
        PARTITION BY sm.ProductID 
        ORDER BY sm.MovementDate
    ) as RunningStock
FROM StockMovements sm
JOIN Products p ON sm.ProductID = p.ProductID;
```

### Sales Analysis
```sql
-- Category performance analysis
WITH CategorySales AS (
    SELECT 
        c.CategoryID,
        c.CategoryName,
        COUNT(DISTINCT sm.ProductID) as UniqueProducts,
        SUM(sm.Quantity * sp.UnitPrice) as TotalSales
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN StockMovements sm ON p.ProductID = sm.ProductID
    JOIN StoreProducts sp ON sm.StoreProductID = sp.StoreProductID
    WHERE sm.MovementType = 'SALES'
    GROUP BY c.CategoryID, c.CategoryName
)
SELECT 
    CategoryName,
    UniqueProducts,
    TotalSales,
    RANK() OVER (ORDER BY TotalSales DESC) as SalesRank
FROM CategorySales;
```

## Documentation 📚

- [Database Schema](docs/schema.md)
- [Stored Procedures](docs/procedures.md)
- [Query Examples](docs/queries.md)

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📝

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author ✍️

Tileni

---
⭐️ From [Tileni97](https://github.com/Tileni97)
