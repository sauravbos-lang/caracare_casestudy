{{{
  config(
    materialized='table',
    schema='00_bronze'
  )
}}}

-- Patient Dimension Table
-- Contains unique patient records with demographic information

SELECT DISTINCT
    patient_id,
    patient_email,
    CAST(date_of_birth AS DATE) AS date_of_birth
FROM {{ source('caracare_raw', 'caracare_raw') }}