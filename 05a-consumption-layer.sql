ALTER SESSION SET TIMEZONE = 'Asia/Kolkata';
select current_timestamp();


-- changing the context
use warehouse compute_wh;
use schema legacy_db.consumption;

create or replace stream legacy_db.clean.customer_clean_stream_to_cus 
on table legacy_db.clean.customer_clean;

create or replace stream legacy_db.clean.order_clean_stream_to_order 
on table legacy_db.clean.order_clean;

create or replace stream legacy_db.clean.customer_clean_stream_to_mkt 
on table legacy_db.clean.customer_clean;

create or replace stream legacy_db.clean.order_clean_stream_to_prio 
on table legacy_db.clean.order_clean;

create or replace table legacy_db.consumption.dim_customer (
    cust_sg_key int primary key autoincrement,
    cust_key number,
    name text,
    address text,
    phone text
    --,mkt_segment text
);

create or replace task legacy_db.raw.populate_dim_customer_task
warehouse = compute_wh
after legacy_db.raw.populate_clean_customer_task
when system$stream_has_data('legacy_db.clean.customer_clean_stream_to_cus')
as
merge into legacy_db.consumption.dim_customer target
using (
    select cust_key, name, address, phone--, mkt_segment
    from legacy_db.clean.customer_clean_stream_to_cus
) src
on target.cust_key = src.cust_key
when matched then update set
    target.name = src.name,
    target.address = src.address,
    target.phone = src.phone
    -- ,target.mkt_segment = src.mkt_segment
when not matched then insert (cust_key, name, address, phone)--, mkt_segment)
values (src.cust_key, src.name, src.address, src.phone);--, src.mkt_segment);

-- Create the date dimension table
create or replace table legacy_db.consumption.dim_date (
    date_sg_key int primary key autoincrement,
    order_date date,
    order_year int,
    order_quarter int,
    order_month int,
    order_week int,
    order_day int
);

-- Task to populate date dimension from order_clean stream
create or replace task legacy_db.raw.populate_dim_date_task
    warehouse = compute_wh
    after legacy_db.raw.populate_clean_order_task
    when system$stream_has_data('legacy_db.clean.order_clean_stream_to_order')
as
merge into legacy_db.consumption.dim_date target
using (
    select distinct
        order_date,
        year(order_date) as order_year,
        quarter(order_date) as order_quarter,
        month(order_date) as order_month,
        week(order_date) as order_week,
        dayofmonth(order_date) as order_day
    from legacy_db.clean.order_clean_stream_to_order
    where order_date is not null
) src
on target.order_date = src.order_date
when matched then update set
    target.order_year = src.order_year,
    target.order_quarter = src.order_quarter,
    target.order_month = src.order_month,
    target.order_week = src.order_week,
    target.order_day = src.order_day
when not matched then insert (order_date, order_year, order_quarter, order_month, order_week, order_day)
values (src.order_date, src.order_year, src.order_quarter, src.order_month, src.order_week, src.order_day);

-- Create the priority dimension table
create or replace table legacy_db.consumption.dim_priority (
    priority_sg_key int primary key autoincrement,
    order_priority text
);

-- Task to populate priority dimension from order_clean stream
create or replace task legacy_db.raw.populate_dim_priority_task
    warehouse = compute_wh
    after legacy_db.raw.populate_clean_order_task
    when system$stream_has_data('legacy_db.clean.order_clean_stream_to_prio')
as
merge into legacy_db.consumption.dim_priority target
using (
    select distinct order_priority
    from legacy_db.clean.order_clean_stream_to_prio
    where order_priority is not null
) src
on target.order_priority = src.order_priority
when not matched then insert (order_priority)
values (src.order_priority);

-- Create the market segment table
create or replace table legacy_db.consumption.dim_mkt (
    mkt_sg_key int primary key autoincrement,
    -- cust_key number,
    mkt_segment text
);

-- Task to populate market segment from order_clean stream
create or replace task legacy_db.raw.populate_dim_mkt_task
    warehouse = compute_wh
    after legacy_db.raw.populate_clean_customer_task
    when system$stream_has_data('legacy_db.clean.customer_clean_stream_to_mkt')
as
merge into legacy_db.consumption.dim_mkt target
using (
    select distinct mkt_segment
    from legacy_db.clean.customer_clean_stream_to_mkt
    where mkt_segment is not null
) src
on target.mkt_segment = src.mkt_segment
when not matched then insert (mkt_segment)
values (src.mkt_segment);