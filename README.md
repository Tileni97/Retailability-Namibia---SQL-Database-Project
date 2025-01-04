# Retailability Namibia - Inventory Management System

## Overview
A comprehensive inventory management system for Retailability's operations in Namibia, managing multiple retail chains including Beaver Canoe, Legit, Style, Edgars, and Swagga.

## Project Structure
```
RetailabilityInventorySystem/
├── database/
│   ├── schema/         # Database structure definitions
│   ├── data/           # Initial and sample data
│   └── security/       # User management and security
├── queries/
│   ├── reporting/      # Reporting queries
│   └── operations/     # Operational queries
├── docs/               # Documentation
└── tests/              # Test data and scenarios
```

## Features
- Multi-store chain management
- Inventory tracking
- Stock movement management
- Automated reorder alerts
- Performance analytics
- Security and user management

## Installation
1. Create the database:
```sql
mysql -u root -p < database/schema/01_create_tables.sql
```

2. Set up triggers and procedures:
```sql
mysql -u root -p RetailabilityNamibia < database/schema/02_create_triggers.sql
mysql -u root -p RetailabilityNamibia < database/schema/03_create_procedures.sql
```

3. Initialize data:
```sql
mysql -u root -p RetailabilityNamibia < database/data/01_initial_data.sql
```

## Documentation
- See `/docs` for detailed documentation
- Database schema details in `/docs/schema.md`
- Stored procedures documentation in `/docs/procedures.md`

## Testing
Sample test data and scenarios are available in the `/tests` directory.

## Author
[Your Name]

## License
[Choose a license]
