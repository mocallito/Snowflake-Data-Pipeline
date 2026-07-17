ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

use warehouse compute_wh;
use schema legacy_db.clean;

-- creating tables in clean layer
create or replace table legacy_db.clean.customer_clean (
    c_id int primary key autoincrement,
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

-- clean order table
create or replace table legacy_db.clean.order_clean (
    o_id int primary key autoincrement,
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


-- ceating task to copy data from stream to clean customer table
create or replace task legacy_db.raw.populate_clean_customer_task
    warehouse = compute_wh
    after legacy_db.raw.copy_to_customer_raw_task
    when system$stream_has_data('legacy_db.raw.customer_raw_stream')
        as
    merge into legacy_db.clean.customer_clean target_clean 
    using (
            select
                cust_key,
                name,
                address,
                nation_name,
                phone,
                acct_bal,
                mkt_segment,
                load_ts,
                load_row_number,
                load_file_name,         
            row_number() over (partition by cust_key order by load_ts desc) as row_number
            from 
                legacy_db.raw.customer_raw_stream 
        ) source_raw on
    target_clean.cust_key = source_raw.cust_key
    when matched and row_number=1 
    then update set
        target_clean.cust_key = source_raw.cust_key,
        target_clean.name = source_raw.name,
        target_clean.address = source_raw.address,
        target_clean.nation_name = source_raw.nation_name,
        target_clean.phone = source_raw.phone,
        target_clean.acct_bal = source_raw.acct_bal,
        target_clean.mkt_segment = source_raw.mkt_segment,
        target_clean.load_ts = source_raw.load_ts,
        target_clean.load_row_number = source_raw.load_row_number,
        target_clean.load_file_name = source_raw.load_file_name
    when not matched and row_number=1 
    then insert (cust_key,name,address,nation_name,phone,acct_bal,mkt_segment,load_ts,load_row_number,load_file_name)
    values 
    (
        source_raw.cust_key,
        source_raw.name,
        source_raw.address,
        source_raw.nation_name,
        source_raw.phone,
        source_raw.acct_bal,
        source_raw.mkt_segment,
        source_raw.load_ts,
        source_raw.load_row_number,
        source_raw.load_file_name
    );


    
-- clean order task 
    create or replace task legacy_db.raw.populate_clean_order_task
    warehouse = compute_wh
    after legacy_db.raw.copy_to_order_raw_task
    when system$stream_has_data('legacy_db.raw.order_raw_stream')
        as
    merge into legacy_db.clean.order_clean target_clean 
    using (
            select
                order_key,
                cust_key,
                order_status,
                total_price,
                order_date,
                order_priority,
                clerk,
                ship_priority,
                load_ts,
                load_row_number,
                load_file_name  ,       
            row_number() over (partition by order_key order by load_ts desc) as row_number
            from 
                legacy_db.raw.order_raw_stream 
        ) source_raw on
    target_clean.cust_key = source_raw.cust_key
    when matched and row_number=1 
    then update set
            target_clean.cust_key = source_raw.cust_key,
            target_clean.order_status = source_raw.order_status,
            target_clean.total_price = source_raw.total_price,
            target_clean.order_date = source_raw.order_date,
            target_clean.order_priority = source_raw.order_priority,
            target_clean.clerk = source_raw.clerk,
            target_clean.ship_priority = source_raw.ship_priority,
            target_clean.load_ts = source_raw.load_ts,
            target_clean.load_row_number = source_raw.load_row_number,
            target_clean.load_file_name  = source_raw.load_file_name
    when not matched and row_number=1 
    then insert (order_key,cust_key,order_status,total_price,order_date,order_priority,clerk,ship_priority,load_ts,load_row_number,load_file_name  )
    values 
    (
        source_raw.order_key,
        source_raw.cust_key,
        source_raw.order_status,
        source_raw.total_price,
        source_raw.order_date,
        source_raw.order_priority,
        source_raw.clerk,
        source_raw.ship_priority,
        source_raw.load_ts,
        source_raw.load_row_number,
        source_raw.load_file_name  
    );

