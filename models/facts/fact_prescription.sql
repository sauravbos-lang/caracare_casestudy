{{{
  config(
    materialized='table',
    schema='00_bronze'
  )
}}}

-- Prescription Fact Table
-- Contains prescription transactions with foreign keys to dimensions
-- Grain: One row per prescription

SELECT
    prescription_id,
    patient_id,
    md5(concat_ws('|', prescribing_doctor, doctor_specialty, doctor_city)) AS doctor_id,
    md5(concat_ws('|', insurance_name, insurance_type)) AS insurance_id,
    CAST(prescription_start AS DATE) AS prescription_start,
    CAST(prescription_end AS DATE) AS prescription_end,
    prescription_status,
    CASE 
        WHEN represcription = 'ja' THEN TRUE 
        WHEN represcription = 'nein' THEN FALSE 
    END AS represcription,
    CAST(represcription_date AS DATE) AS represcription_date
FROM {{ source('caracare_raw', 'caracare_raw') }}