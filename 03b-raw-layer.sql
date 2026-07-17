ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

use warehouse compute_wh;
use schema legacy_db.raw;


-- create tables inside the raw layer
-- ----------------------------------
create or replace table legacy_db.raw.file_ingestion_tracking (
    ingestion_id int primary key autoincrement,
    file_name text,
    ingestion_ts timestamp default current_timestamp(),
    row_count number,
    status text,
    comments text
);


-- creating stream on customer_raw to track the changes
create or replace stream legacy_db.raw.customer_raw_stream_tracking 
    on table legacy_db.raw.customer_raw
    append_only = true;

create or replace stream legacy_db.raw.order_raw_stream_tracking 
    on table legacy_db.raw.order_raw
    append_only = true;


-- Task for customer_raw stream ingestion tracking
create or replace task legacy_db.raw.customer_ingestion_tracking_task
    warehouse = compute_wh
    after legacy_db.raw.root_task
    as
    insert into legacy_db.raw.file_ingestion_tracking (
        file_name,
        ingestion_ts,
        row_count,
        status,
        comments
    )
    select 
    load_file_name as file_name,
        current_timestamp() as ingestion_ts,
        count(*) over() as row_count,
        'INGESTED' as status,
        concat('Stream action: ', metadata$action, ', Row ID: ', metadata$row_id) as comments
from legacy_db.raw.customer_raw_stream_tracking;


-- Task for order_raw stream ingestion tracking
create or replace task legacy_db.raw.order_ingestion_tracking_task
    warehouse = compute_wh
    after legacy_db.raw.root_task
    as
    insert into legacy_db.raw.file_ingestion_tracking (
    file_name,
    ingestion_ts,
    row_count,
    status,
    comments
)
select 
    load_file_name as file_name,
    current_timestamp() as ingestion_ts,
    count(*) over() as row_count,
    'INGESTED' as status,
    concat('Stream action: ', metadata$action, ', Row ID: ', metadata$row_id) as comments
from legacy_db.raw.order_raw_stream_tracking;
