with 

-- =========================
-- STAGING
-- =========================

stg_salesorderheader as (
    select
        salesorderid,
        customerid,
        creditcardid,
        shiptoaddressid,
        status as order_status,
        cast(orderdate as date) as orderdate
    from {{ ref('salesorderheader') }}
),

stg_salesorderheader_2012_2017 as (
    select
        salesorderid,
        customerid,
        creditcardid,
        shiptoaddressid,
        status as order_status,
        cast(orderdate as date) as orderdate
    from {{ ref('salesorderheader_2012_2017') }}
),

stg_salesorderdetail as (
    select
        salesorderid,
        salesorderdetailid,
        productid,
        orderqty,
        unitprice,
        unitprice * orderqty as revenue
    from {{ ref('salesorderdetail') }}
),

stg_salesorderdetail_2012_2017 as (
    select
        salesorderid,
        salesorderdetailid,
        productid,
        orderqty,
        unitprice,
        unitprice * orderqty as revenue
    from {{ ref('salesorderdetail_2012_2017') }}
),

-- =========================
-- UNION (fusion verticale)
-- =========================

all_salesorderheader as (
    select * from stg_salesorderheader
    union all
    select * from stg_salesorderheader_2012_2017
),

all_salesorderdetail as (
    select * from stg_salesorderdetail
    union all
    select * from stg_salesorderdetail_2012_2017
),

-- =========================
-- FACT TABLE
-- =========================

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['d.salesorderid', 'd.salesorderdetailid']) }} as sales_key,
        {{ dbt_utils.generate_surrogate_key(['d.productid']) }} as product_key,
        {{ dbt_utils.generate_surrogate_key(['h.customerid']) }} as customer_key,
        {{ dbt_utils.generate_surrogate_key(['h.creditcardid']) }} as creditcard_key,
        {{ dbt_utils.generate_surrogate_key(['h.shiptoaddressid']) }} as ship_address_key,
        {{ dbt_utils.generate_surrogate_key(['h.order_status']) }} as order_status_key,
        {{ dbt_utils.generate_surrogate_key(['h.orderdate']) }} as order_date_key,

        d.salesorderid,
        d.salesorderdetailid,
        d.productid,
        d.unitprice,
        d.orderqty,
        d.revenue,
        h.customerid,
        h.creditcardid,
        h.shiptoaddressid,
        h.order_status,
        h.orderdate

    from all_salesorderdetail d
    left join all_salesorderheader h
        on d.salesorderid = h.salesorderid
)

select * from final