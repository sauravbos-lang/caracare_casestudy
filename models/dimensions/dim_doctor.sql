{{{
  config(
    materialized='table',
    schema='00_bronze'
  )
}}}

-- Doctor Dimension Table
-- Contains unique doctor records with specialty and location information
-- Uses MD5 hash to create surrogate key from business attributes

SELECT DISTINCT
    md5(concat_ws('|', prescribing_doctor, doctor_specialty, doctor_city)) AS doctor_id,
    prescribing_doctor,
    doctor_specialty,
    doctor_city
FROM {{ source('caracare_raw', 'caracare_raw') }}