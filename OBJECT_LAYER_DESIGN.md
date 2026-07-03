# Task 1 - Object Layer Design

## Clean Object-Layer Model from Flat Table

This document describes the dimensional model design derived from the flat `caracare_raw` source table.

---

## Table Structures

### 1. dim_patient
**Patient Dimension Table**

| Column | Data Type | Description | Constraints |
|--------|-----------|-------------|-------------|
| patient_id | STRING | Unique patient identifier | PRIMARY KEY |
| patient_email | STRING | Patient email address | |
| date_of_birth | DATE | Patient's date of birth | NOT NULL |

**Primary Key:** `patient_id`

**dbt Model:** `models/dimensions/dim_patient.sql`

---

### 2. dim_doctor
**Doctor Dimension Table**

| Column | Data Type | Description | Constraints |
|--------|-----------|-------------|-------------|
| doctor_id | STRING | MD5 hash of doctor attributes | PRIMARY KEY |
| prescribing_doctor | STRING | Doctor's name | NOT NULL |
| doctor_specialty | STRING | Medical specialty | |
| doctor_city | STRING | Practice location | |

**Primary Key:** `doctor_id`
- Generated as: `md5(concat_ws('|', prescribing_doctor, doctor_specialty, doctor_city))`
- Surrogate key ensures uniqueness across name-specialty-city combinations

**dbt Model:** `models/dimensions/dim_doctor.sql`

---

### 3. dim_insurance
**Insurance Provider Dimension Table**

| Column | Data Type | Description | Constraints |
|--------|-----------|-------------|-------------|
| insurance_id | STRING | MD5 hash of insurance attributes | PRIMARY KEY |
| insurance_name | STRING | Insurance provider name | NOT NULL |
| insurance_type | STRING | Type of insurance plan | |

**Primary Key:** `insurance_id`
- Generated as: `md5(concat_ws('|', insurance_name, insurance_type))`
- Surrogate key for name-type combinations

**dbt Model:** `models/dimensions/dim_insurance.sql`

---

### 4. fact_prescription
**Prescription Transactions Fact Table**

| Column | Data Type | Description | Constraints |
|--------|-----------|-------------|-------------|
| prescription_id | STRING | Unique prescription identifier | PRIMARY KEY |
| patient_id | STRING | Reference to patient | FOREIGN KEY → dim_patient.patient_id |
| doctor_id | STRING | Reference to doctor | FOREIGN KEY → dim_doctor.doctor_id |
| insurance_id | STRING | Reference to insurance | FOREIGN KEY → dim_insurance.insurance_id |
| prescription_start | DATE | Prescription start date | NOT NULL |
| prescription_end | DATE | Prescription end date | |
| prescription_status | STRING | Current prescription status | |
| represcription | BOOLEAN | Whether this is a represcription | |
| represcription_date | DATE | Date of represcription (if applicable) | |

**Primary Key:** `prescription_id`

**Foreign Keys:**
- `patient_id` → `dim_patient.patient_id`
- `doctor_id` → `dim_doctor.doctor_id`
- `insurance_id` → `dim_insurance.insurance_id`

**dbt Model:** `models/facts/fact_prescription.sql`

**Special Transformations:**
- `represcription`: German text ('ja'/'nein') converted to BOOLEAN (TRUE/FALSE)

---

### 5. fact_touchpoint
**Patient Touchpoint Events Fact Table**

| Column | Data Type | Description | Constraints |
|--------|-----------|-------------|-------------|
| touchpoint_id | STRING | MD5 hash of touchpoint attributes | PRIMARY KEY |
| prescription_id | STRING | Reference to prescription | FOREIGN KEY → fact_prescription.prescription_id |
| touchpoint_date | DATE | Date of touchpoint event | NOT NULL |
| touchpoint_type | STRING | Type of interaction | |
| touchpoint_channel | STRING | Communication channel used | |
| touchpoint_outcome | STRING | Outcome of the touchpoint | |

**Primary Key:** `touchpoint_id`
- Generated as: `md5(concat_ws('|', prescription_id, touchpoint_date, touchpoint_type, touchpoint_channel))`
- Composite surrogate key ensures unique touchpoint identification

**Foreign Keys:**
- `prescription_id` → `fact_prescription.prescription_id`

**dbt Model:** `models/facts/fact_touchpoint.sql`

---

## Relationships

```
┌─────────────────┐
│  dim_patient    │
│  PK: patient_id │
└────────┬────────┘
         │
         │ 1:N
         │
┌────────▼────────────────────┐
│  fact_prescription          │
│  PK: prescription_id        │
│  FK: patient_id     ────────┼──── dim_patient
│  FK: doctor_id      ────────┼──── dim_doctor
│  FK: insurance_id   ────────┼──── dim_insurance
└────────┬────────────────────┘
         │
         │ 1:N
         │
┌────────▼────────────────────┐
│  fact_touchpoint            │
│  PK: touchpoint_id          │
│  FK: prescription_id────────┼──── fact_prescription
└─────────────────────────────┘

┌─────────────────┐       ┌──────────────────┐
│  dim_doctor     │       │  dim_insurance   │
│  PK: doctor_id  │       │  PK: insurance_id│
└─────────────────┘       └──────────────────┘
```

---

## Design Decisions

### Surrogate Keys
- **Strategy:** MD5 hashing for composite business keys
- **Rationale:** 
  - Deterministic and reproducible
  - No need for external sequence generators
  - Handles composite natural keys elegantly
- **Applied to:** doctor_id, insurance_id, touchpoint_id

### Data Type Transformations
1. **Boolean Conversion:**
   - Source: German text ('ja' = yes, 'nein' = no)
   - Target: BOOLEAN (TRUE/FALSE)
   - Implementation: CASE WHEN expression

2. **Date Standardization:**
   - All date columns explicitly cast to DATE type
   - Ensures consistent date handling across queries

3. **String Normalization:**
   - All text fields remain STRING type
   - Preserves original data fidelity

### Dimensionality
- **Schema Type:** Star Schema
- **Grain:**
  - `fact_prescription`: One row per prescription
  - `fact_touchpoint`: One row per touchpoint event
- **Deduplication:** DISTINCT applied to dimension tables

### Performance Considerations
- All models materialized as **tables** (not views)
- Foreign key relationships documented but not enforced (Databricks Delta best practice)
- Indexes/constraints handled at query time via partitioning and Z-ordering (optional)

---

## Implementation Files

| Component | File Path | Purpose |
|-----------|-----------|----------|
| Project Config | `dbt_project.yml` | dbt project settings |
| Source Definition | `models/sources.yml` | Source table reference |
| Model Documentation | `models/schema.yml` | Tests and documentation |
| Patient Dimension | `models/dimensions/dim_patient.sql` | Patient model |
| Doctor Dimension | `models/dimensions/dim_doctor.sql` | Doctor model |
| Insurance Dimension | `models/dimensions/dim_insurance.sql` | Insurance model |
| Prescription Fact | `models/facts/fact_prescription.sql` | Prescription model |
| Touchpoint Fact | `models/facts/fact_touchpoint.sql` | Touchpoint model |

---

## Data Quality

### Built-in dbt Tests
1. **Uniqueness Tests:** All primary keys
2. **Not Null Tests:** Required fields
3. **Relationship Tests:** Foreign key integrity

### Test Coverage
- **dim_patient:** patient_id uniqueness and not null, date_of_birth not null
- **dim_doctor:** doctor_id uniqueness and not null, prescribing_doctor not null
- **dim_insurance:** insurance_id uniqueness and not null, insurance_name not null
- **fact_prescription:** prescription_id uniqueness, all FKs not null and valid
- **fact_touchpoint:** touchpoint_id uniqueness, prescription_id FK valid

---

## Usage

### Build All Models
```bash
dbt build
```

### Build Specific Layers
```bash
# Dimensions only
dbt run --select dimensions.*

# Facts only
dbt run --select facts.*
```

### Run Tests
```bash
dbt test
```

### Generate Documentation
```bash
dbt docs generate
dbt docs serve
```