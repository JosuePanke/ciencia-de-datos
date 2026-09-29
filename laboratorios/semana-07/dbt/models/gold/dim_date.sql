with dias as (

    select dateadd('day', row_number() over (order by seq4()) - 1, '2025-01-01'::date) as full_date
    from table(generator(rowcount => 730))

)

select
    to_number(to_char(full_date, 'YYYYMMDD'))   as date_key,
    full_date,
    year(full_date)                             as year,
    quarter(full_date)                          as quarter,
    month(full_date)                            as month,
    monthname(full_date)                        as month_name,
    day(full_date)                              as day_of_month,
    dayofweekiso(full_date)                     as day_of_week,
    dayname(full_date)                          as day_name,
    dayofweekiso(full_date) in (6, 7)           as is_weekend
from dias
