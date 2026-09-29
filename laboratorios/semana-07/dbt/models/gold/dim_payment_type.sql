select
    cast(payment_type_id as integer)  as payment_type_id,
    payment_type_name
from {{ ref('ref_payment_type') }}
