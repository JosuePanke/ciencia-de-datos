-- Silver: viajes de NYC Yellow Taxi limpios y estandarizados.
-- Grano: un registro por viaje válido.

with bronze as (

    select * from {{ source('bronze', 'yellow_trips') }}

),

-- 1) NOMBRES Y TIPOS: snake_case y tipos correctos
tipado as (

    select
        cast(vendorid as integer)                   as vendor_id,
        tpep_pickup_datetime                        as pickup_datetime,
        tpep_dropoff_datetime                       as dropoff_datetime,
        cast(passenger_count as integer)            as passenger_count_raw,
        cast(trip_distance as number(10, 2))        as trip_distance_miles,
        cast(ratecodeid as integer)                 as rate_code_id_raw,
        upper(trim(store_and_fwd_flag))             as store_and_fwd_flag_raw,
        cast(pulocationid as integer)               as pickup_location_id,
        cast(dolocationid as integer)               as dropoff_location_id,
        cast(payment_type as integer)               as payment_type_id,
        cast(fare_amount as number(10, 2))          as fare_amount,
        cast(extra as number(10, 2))                as extra_amount,
        cast(mta_tax as number(10, 2))              as mta_tax_amount,
        cast(tip_amount as number(10, 2))           as tip_amount,
        cast(tolls_amount as number(10, 2))         as tolls_amount,
        cast(improvement_surcharge as number(10, 2)) as improvement_surcharge_amount,
        cast(congestion_surcharge as number(10, 2)) as congestion_surcharge_amount,
        cast(airport_fee as number(10, 2))          as airport_fee_amount,
        cast(cbd_congestion_fee as number(10, 2))   as cbd_congestion_fee_amount,
        cast(total_amount as number(10, 2))         as total_amount,
        source_file,
        to_date(regexp_substr(source_file, '\\d{4}-\\d{2}') || '-01') as source_period,
        loaded_at
    from bronze

),

-- 2) NULOS Y VALORES INVÁLIDOS CORREGIBLES
nulos as (

    select
        *,
        case when passenger_count_raw between 1 and 6
             then passenger_count_raw end           as passenger_count,
        coalesce(rate_code_id_raw, 99)              as rate_code_id,
        case store_and_fwd_flag_raw
             when 'Y' then true
             when 'N' then false end                as is_store_and_forward
    from tipado

),

-- 3) REGISTROS INVÁLIDOS: se descartan
validos as (

    select *
    from nulos
    where dropoff_datetime > pickup_datetime
      and datediff('minute', pickup_datetime, dropoff_datetime) <= 24 * 60
      and date_trunc('month', pickup_datetime) = source_period
      and trip_distance_miles > 0
      and trip_distance_miles <= 200
      and total_amount >= 0
      and total_amount <= 1000

),

-- 4) DUPLICADOS: uno por viaje (se queda con la carga más reciente)
deduplicado as (

    select *
    from validos
    qualify row_number() over (
        partition by vendor_id, pickup_datetime, dropoff_datetime,
                     pickup_location_id, dropoff_location_id,
                     trip_distance_miles, total_amount
        order by loaded_at desc, source_file
    ) = 1

)

select
    md5(concat_ws('|',
        coalesce(to_varchar(vendor_id), ''),
        to_varchar(pickup_datetime),
        to_varchar(dropoff_datetime),
        coalesce(to_varchar(pickup_location_id), ''),
        coalesce(to_varchar(dropoff_location_id), ''),
        to_varchar(trip_distance_miles),
        to_varchar(total_amount)
    ))                                                          as trip_id,
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    round(datediff('second', pickup_datetime, dropoff_datetime) / 60, 2) as trip_duration_minutes,
    passenger_count,
    trip_distance_miles,
    rate_code_id,
    is_store_and_forward,
    pickup_location_id,
    dropoff_location_id,
    payment_type_id,
    fare_amount,
    extra_amount,
    mta_tax_amount,
    tip_amount,
    tolls_amount,
    improvement_surcharge_amount,
    congestion_surcharge_amount,
    airport_fee_amount,
    cbd_congestion_fee_amount,
    total_amount,
    source_file,
    source_period,
    loaded_at
from deduplicado
