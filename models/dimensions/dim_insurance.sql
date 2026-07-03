{{{
  config(
    materialized='table',
    schema='00_bronze'
  )
}}}

-- Insurance Dimension Table
-- Contains unique insurance provider records
-- Uses MD5 hash to create surrogate key from business attributes

SELECT DISTINCT
    md5(concat_ws('|', insurance_name, insurance_type)) AS insurance_id,
    insurance_name,
    insurance_type
FROM {{ source('caracare_raw', 'caracare_raw') }}