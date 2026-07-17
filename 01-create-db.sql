ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

-- Create database and schema.
-- ----------------------------------
create or replace database legacy_db
comment = 'this is legacy_db database for stream & task demo';

use database legacy_db;

create or replace schema source
comment = 'this is stage schema in legacy_db database';
create or replace schema raw
comment = 'this is raw schema in legacy_db database';
create or replace schema clean
comment = 'this is clean schema in legacy_db database';
create or replace schema consumption
comment = 'this is consumption schema in legacy_db database';

-- change context
use schema legacy_db.source;



-- Create an external stage location
-- -----------------------------------------
drop stage if exists legacy_db.source.my_stage;


create stage legacy_db.source.my_stage 
URL = 's3://quangpublicbucket/snowflakefiles/pipeline/'
CREDENTIALS = (
    AWS_KEY_ID = 'XXXXXXXXXXXXXXXXXXXX'
    AWS_SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
)
DIRECTORY = ( ENABLE = true AUTO_REFRESH = true );
