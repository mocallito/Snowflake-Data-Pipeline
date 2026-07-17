ALTER SESSION SET TIMEZONE = 'Asia/Kolkata';
select current_timestamp();


-- changing the context
use warehouse compute_wh;
use schema legacy_db.consumption;

create or replace stream legacy_db.consumption.order_clean_stream_to_fact
on table legacy_db.clean.order_clean;

create or replace stream legacy_db.consumption.customer_clean_stream_to_fact
on table legacy_db.clean.customer_clean;

create or replace stream legacy_db.consumption.cus_stream_to_fact
on table legacy_db.consumption.dim_customer;

create or replace stream legacy_db.consumption.date_stream_to_fact
on table legacy_db.consumption.dim_date;

create or replace stream legacy_db.consumption.mkt_stream_to_fact
on table legacy_db.consumption.dim_mkt;

create or replace stream legacy_db.consumption.prio_stream_to_fact
on table legacy_db.consumption.dim_priority;

-- Create the fact_order table
create or replace table legacy_db.consumption.fact_order (
    order_sg_key int primary key autoincrement,
    order_key number,
    cust_sg_key int,
    date_sg_key int,
    priority_sg_key int,
    total_price number,
    mkt_sg_key int
);
	
create or replace task legacy_db.raw.populate_fact_order_task
    warehouse = compute_wh
    after legacy_db.raw.populate_dim_priority_task
    , legacy_db.raw.populate_dim_customer_task
, legacy_db.raw.populate_dim_date_task 
, legacy_db.raw.populate_dim_mkt_task
    when system$stream_has_data('legacy_db.consumption.cus_stream_to_fact') 
and system$stream_has_data('legacy_db.consumption.order_clean_stream_to_fact')
and system$stream_has_data('legacy_db.consumption.date_stream_to_fact') 
and system$stream_has_data('legacy_db.consumption.mkt_stream_to_fact') 
and system$stream_has_data('legacy_db.consumption.prio_stream_to_fact')
and system$stream_has_data('legacy_db.consumption.customer_clean_stream_to_fact')
as
insert into legacy_db.consumption.fact_order (
    order_key, cust_sg_key, date_sg_key, priority_sg_key, total_price, mkt_sg_key
)
select 
       oc.order_key,
       cd.cust_sg_key,
       dd.date_sg_key,
       pd.priority_sg_key,
       oc.total_price,
       md.mkt_sg_key
from legacy_db.consumption.order_clean_stream_to_fact oc
left join legacy_db.consumption.cus_stream_to_fact cd 
       on cd.cust_key = oc.cust_key
left join consumption.customer_clean_stream_to_fact cc
       on cc.cust_key = oc.cust_key
left join legacy_db.consumption.date_stream_to_fact dd 
       on dd.order_date = oc.order_date
left join legacy_db.consumption.prio_stream_to_fact pd 
       on pd.order_priority = oc.order_priority
left join legacy_db.consumption.mkt_stream_to_fact md 
      on md.mkt_segment = cc.mkt_segment;