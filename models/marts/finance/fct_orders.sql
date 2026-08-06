--define the model configuration for incremental materialization
{{
    config(
        materialized='incremental'
    )
}}
--CTE to select all orders from the stg_jaffle_shop__orders model
with orders as (
    select * from {{ ref('stg_jaffle_shop__orders') }}
),
--CTE to select all payments from the stg_stripe__payment model
payments as (
    select * from {{ ref('stg_stripe__payment') }}
),
--CTE to calculate the total payment amount for each order
orders_payments as (
    select
    order_id, 
    sum(case when payment_status = 'success' then payment_amount end) as amount

    from payments 
    group by 1
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        coalesce(orders_payments.amount, 0) as amount
    from orders 
    left join orders_payments using (order_id)
)
select * from final
--incremental logic to only select new records based on the order_date
{% if is_incremental() %}
where
order_date >= (select max(order_date) from {{this}})
{% endif %}