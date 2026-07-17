# Snowflake-Data-Pipeline

Developed as part of the NashTech Rookie program, this project demonstrates a Snowflake data warehouse pipeline with automated ingestion, incremental processing, data transformations, and dimensional modeling using a layered architecture (Source → Raw → Clean → Consumption).

## High-Level Architecture

```text
                           +----------------------+
                           |      Amazon S3       |
                           | Customer CSV Files   |
                           | Order CSV Files      |
                           +----------+-----------+
                                      |
                                      |
                           External Stage (Snowflake)
                                      |
                                      |
                           Scheduled Root Task (1 min)
                                      |
                     +----------------+----------------+
                     |                                 |
                     | COPY INTO                       | COPY INTO
                     |                                 |
             +-------v--------+               +--------v-------+
             | customer_raw   |               |   order_raw    |
             +-------+--------+               +--------+-------+
                     |                                 |
                Stream                            Stream
                     |                                 |
         +-----------+------------+       +------------+-----------+
         |                        |       |                        |
         |                        |       |                        |
         v                        v       v                        v
 Ingestion Tracking         Clean Layer Merge         Ingestion Tracking
(file_ingestion_tracking)      (MERGE)             (file_ingestion_tracking)
                                  |
                   +--------------+--------------+
                   |                             |
            customer_clean                order_clean
                   |                             |
                   +-------------+---------------+
                                 |
                            Clean Streams
                                 |
          +----------+-----------+-----------+-----------+
          |          |                       |           |
          |          |                       |           |
          v          v                       v           v
   dim_customer   dim_date          dim_priority    dim_market
          \          |                     |             /
           \         |                     |            /
            \        |                     |           /
             +-------+---------------------+----------+
                             |
                             |
                      Build Fact Table
                             |
                             v
                      +---------------+
                      |  fact_order   |
                      +---------------+
                             |
                             v
                   Analytics / BI / Reporting
```

---

# Layer Description

| Layer           | Purpose                                                                                               | Main Objects                          |
| --------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------- |
| **Source**      | Connects Snowflake to Amazon S3 using an External Stage and CSV File Format.                          | External Stage, File Format           |
| **Raw**         | Landing zone for source files. Stores data exactly as received with ingestion metadata.               | customer_raw, order_raw               |
| **Streams**     | Capture only newly inserted rows for incremental processing.                                          | customer_raw_stream, order_raw_stream |
| **Clean**       | Performs deduplication and upserts using MERGE. Maintains the latest version of each business record. | customer_clean, order_clean           |
| **Consumption** | Builds a dimensional model (star schema) for analytics.                                               | Dimensions + Fact table               |
| **Monitoring**  | Tracks file ingestion history and task execution.                                                     | file_ingestion_tracking, TASK_HISTORY |

---

# Data Flow

```text
CSV Files
      │
      ▼
External Stage
      │
      ▼
COPY INTO Tasks
      │
      ▼
Raw Tables
      │
      ▼
Streams
      │
      ▼
MERGE Tasks
      │
      ▼
Clean Tables
      │
      ▼
Streams
      │
      ▼
Dimension Tables
      │
      ▼
Fact Table
      │
      ▼
BI / Analytics
```

---

# Task Dependency Flow

```text
                    Root Task
                        │
        ┌───────────────┴────────────────┐
        │                                │
        ▼                                ▼
Copy Customer                     Copy Order
        │                                │
        ▼                                ▼
Populate Customer Clean         Populate Order Clean
        │                                │
        │               ┌────────────────┼────────────────┐
        │               │                │                │
        ▼               ▼                ▼                ▼
Dim Customer        Dim Date      Dim Priority      Dim Market
        \               |                |               /
         \              |                |              /
          \_____________|________________|_____________/
                          │
                          ▼
                     Fact Order
```

---

# Star Schema Produced

```text
                 +------------------+
                 |   dim_customer   |
                 +------------------+
                         |
                         |
+-------------+   +------+-------+   +----------------+
| dim_date    |---|  fact_order  |---| dim_priority   |
+-------------+   +------+-------+   +----------------+
                         |
                         |
                  +------+------+
                  |   dim_mkt   |
                  +-------------+
```

---
