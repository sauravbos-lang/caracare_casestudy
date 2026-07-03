{{{
  config(
    materialized='table',
    schema='00_bronze'
  )
}}}

-- Touchpoint Fact Table
-- Contains patient touchpoint events linked to prescriptions
-- Grain: One row per touchpoint event

SELECT
    md5(concat_ws('|', prescription_id, CAST(touchpoint_date AS STRING), touchpoint_type, touchpoint_channel)) AS touchpoint_id,
    prescription_id,
    CAST(touchpoint_date AS DATE) AS touchpoint_date,
    touchpoint_type,
    touchpoint_channel,
    touchpoint_outcome
FROM {{ source('caracare_raw', 'caracare_raw') }}