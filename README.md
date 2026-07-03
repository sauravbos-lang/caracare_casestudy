# Caracare Case Study - dbt Project

## Overview
This dbt project transforms flat source data from the Caracare system into a clean dimensional model (star schema) suitable for analytics.

## Project Structure

```
caracare_casestudy/
├── dbt_project.yml          # dbt project configuration
├── models/
│   ├── sources.yml          # Source table definitions
│   ├── schema.yml           # Model documentation and tests
│   ├── dimensions/          # Dimension tables
│   │   ├── dim_patient.sql
│   │   ├── dim_doctor.sql
│   │   └── dim_insurance.sql
│   └── facts/               # Fact tables
│       ├── fact_prescription.sql
│       └── fact_touchpoint.sql
└── README.md
```

## Data Model

### Star Schema Design

#### Dimension Tables
1. **dim_patient** - Patient demographics
   - Primary Key: `patient_id`
   - Contains: email, date of birth

2. **dim_doctor** - Doctor profiles
   - Primary Key: `doctor_id` (MD5 hash)
   - Contains: name, specialty, city

3. **dim_insurance** - Insurance providers
   - Primary Key: `insurance_id` (MD5 hash)
   - Contains: provider name, plan type

#### Fact Tables
1. **fact_prescription** - Prescription transactions
   - Primary Key: `prescription_id`
   - Foreign Keys: `patient_id`, `doctor_id`, `insurance_id`
   - Measures: dates, status, represcription flag

2. **fact_touchpoint** - Patient interaction events
   - Primary Key: `touchpoint_id` (MD5 hash)
   - Foreign Key: `prescription_id`
   - Measures: date, type, channel, outcome

### Relationships
```
dim_patient ──┐
              │
              ├──> fact_prescription ──> fact_touchpoint
              │
dim_doctor ───┤
              │
dim_insurance ┘
```

## Key Transformations

1. **Surrogate Keys**: MD5 hashing for composite business keys (doctor, insurance, touchpoint)
2. **Boolean Conversion**: German text ('ja'/'nein') → TRUE/FALSE
3. **Date Standardization**: All dates cast to DATE type
4. **Deduplication**: DISTINCT on dimension tables

## Running the Project

### Prerequisites
- dbt-databricks adapter installed
- Access to `caracare_casestudy.caracare_raw.caracare_raw` source table
- Databricks workspace configured

### Commands

```bash
# Test source connection
dbt source freshness

# Build all models
dbt build

# Run only dimension tables
dbt run --select dimensions.*

# Run only fact tables
dbt run --select facts.*

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Data Quality Tests

The schema includes built-in tests:
- **Uniqueness**: Primary keys
- **Not Null**: Required fields
- **Relationships**: Foreign key integrity

Run tests with: `dbt test`

## Target Schema

All models materialize to: `caracare_casestudy.00_bronze`

## Notes

- Source data contains German text values that are transformed to English boolean/standard formats
- Surrogate keys use MD5 hashing for deterministic, reproducible IDs
- Models are configured as **tables** (not views) for performance
- The dimensional model supports efficient analytical queries and reporting