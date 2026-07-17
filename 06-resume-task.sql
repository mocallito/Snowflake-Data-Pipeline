use role sysadmin;
use warehouse compute_wh;
use schema legacy_db.raw;

use role accountadmin;
grant execute task, execute managed task on account to role sysadmin;
use role sysadmin;

alter task legacy_db.raw.root_task suspend;

alter task legacy_db.raw.copy_to_customer_raw_task resume;
alter task legacy_db.raw.copy_to_order_raw_task resume;

alter task legacy_db.raw.customer_ingestion_tracking_task resume;
alter task legacy_db.raw.order_ingestion_tracking_task resume;

alter task legacy_db.raw.populate_clean_customer_task resume;
alter task legacy_db.raw.populate_clean_order_task resume;

alter task legacy_db.raw.populate_dim_customer_task resume;
alter task legacy_db.raw.populate_dim_date_task resume;
alter task legacy_db.raw.populate_dim_priority_task resume;
alter task legacy_db.raw.populate_dim_mkt_task resume;

alter task legacy_db.raw.populate_fact_order_task resume;

alter task legacy_db.raw.root_task resume;
-- wait 1 min
-- alter task legacy_db.raw.root_task suspend;

-- monitoring task
select *
  from table(information_schema.task_history())
  order by scheduled_time desc;

show tasks in schema legacy_db.raw;