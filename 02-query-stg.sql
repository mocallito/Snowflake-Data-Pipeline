ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

use warehouse compute_wh;
use schema legacy_db.source;

-- Create file format.
-- --------------------------
drop file format if exists legacy_db.source.my_csv_format;

create or replace file format legacy_db.source.my_csv_format
    type = 'csv' 
    compression = 'auto' 
    field_delimiter = ',' 
    record_delimiter = '\n'  
    field_optionally_enclosed_by = '\042' 
    skip_header = 1;