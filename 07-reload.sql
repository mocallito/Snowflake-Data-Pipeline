ALTER SESSION SET TIMEZONE = 'Asia/Ho_Chi_Minh';

use warehouse compute_wh;
use schema legacy_db.raw;

-- ad-hoc file reload feature
COPY INTO legacy_db.raw.order_raw
FROM (
    SELECT 
        t.$1,
        t.$2,
        t.$3,
        t.$4,
        t.$5,
        t.$6,
        t.$7,
        t.$8,
        CURRENT_TIMESTAMP(),
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILENAME
    FROM @legacy_db.source.my_stage/order/
    (FILE_FORMAT => 'legacy_db.source.my_csv_format') AS t
)
FILES = ('order-germany-110-rows.csv')
FORCE = TRUE;

COPY INTO legacy_db.raw.customer_raw
FROM (
    SELECT 
        t.$1,
        t.$2,
        t.$3,
        t.$4,
        t.$5,
        t.$6,
        t.$7,
        CURRENT_TIMESTAMP(),
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILENAME
    FROM @legacy_db.source.my_stage/customer/
    (FILE_FORMAT => 'legacy_db.source.my_csv_format') AS t
)
FILES = ('customer-germany-10-rows.csv')
FORCE = TRUE;