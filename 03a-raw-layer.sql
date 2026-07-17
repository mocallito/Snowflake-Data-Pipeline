ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

use warehouse compute_wh;
use schema legacy_db.raw;


-- create tables inside the raw layer
-- ----------------------------------
create or replace table legacy_db.raw.customer_raw (
    cust_key number,
    name text,
    address text,
    nation_name text,
    phone text,
    acct_bal number,
    mkt_segment text,
    load_ts timestamp,
    load_row_number number,
    load_file_name text 
);


-- creating stream on customer_raw to track the changes
create or replace stream legacy_db.raw.customer_raw_stream 
    on table legacy_db.raw.customer_raw
    append_only = true;


-- creating order table with 11 columns
create or replace table legacy_db.raw.order_raw (
    order_key number,
    cust_key number,
    order_status text(1),
    total_price number,
    order_date date,
    order_priority text,
    clerk text,
    ship_priority number(1),
    load_ts timestamp,
    load_row_number number,
    load_file_name text 
);


-- creating stream
create or replace stream legacy_db.raw.order_raw_stream 
    on table legacy_db.raw.order_raw
    append_only = true;



-- run copy command and check data set
 create or replace task legacy_db.raw.root_task
	warehouse=compute_wh
	schedule='1 minute'
	as select current_role();

    

    create or replace task legacy_db.raw.copy_to_customer_raw_task
    warehouse = compute_wh
    after legacy_db.raw.root_task
    as
    copy into legacy_db.raw.customer_raw from 
    (
    select 
        t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,
        current_timestamp(),
        metadata$file_row_number,
        metadata$filename
    from @legacy_db.source.my_stage/customer/ (FILE_FORMAT => 'legacy_db.source.my_csv_format') as t
    );

    -- order data
    create or replace task legacy_db.raw.copy_to_order_raw_task
    warehouse = compute_wh
    after legacy_db.raw.root_task
    as
    copy into legacy_db.raw.order_raw from 
    (
    select 
        t.$1,t.$2,t.$3,t.$4,t.$5,t.$6,t.$7,t.$8,
        current_timestamp(),
        metadata$file_row_number,
        metadata$filename
    from @legacy_db.source.my_stage/order/ (FILE_FORMAT => 'legacy_db.source.my_csv_format') as t
    );

-- visit the catalog and validate the objects were just created