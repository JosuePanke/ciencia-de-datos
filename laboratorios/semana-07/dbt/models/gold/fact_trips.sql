-- Tabla de hechos: un registro por viaje.

select
    -- PK
    trip_id,

    -- FKs a las dimensiones
    to_number(to_char(pickup_datetime, 'YYYYMMDD'))  as pickup_date_key,
    vendor_id,
    pickup_location_id                               as pickup_zone_id,
    dropoff_location_id                              as dropoff_zone_id,
    payment_type_id,
    rate_code_id,

    -- atributos del viaje
    pickup_datetime,
    dropoff_datetime,
    hour(pickup_datetime)                            as pickup_hour,
    is_store_and_forward,

    -- métricas
    passenger_count,
    trip_distance_miles,
    trip_duration_minutes,
    fare_amount,
    extra_amount,
    mta_tax_amount,
    tip_amount,
    tolls_amount,
    improvement_surcharge_amount,
    congestion_surcharge_amount,
    airport_fee_amount,
    cbd_congestion_fee_amount,
    total_amount

from {{ ref('slv_yellow_trips') }}
