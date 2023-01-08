--
-- MySQL Sync
--

CREATE TABLE mysql_sales_order_grid  (
`entity_id` UInt32,
`status` Nullable(String),
`store_id` Nullable(UInt16),
`store_name` Nullable(String),
`customer_id` Nullable(UInt32),
`grand_total` Nullable(Float32),
`order_currency_code` String,
`created_at` DateTime,
`updated_at` DateTime,
`billing_address` Nullable(String),
`shipping_address` Nullable(String),   
`shipping_location` Nullable(String),
`shipping_information` Nullable(String),
`customer_email` Nullable(String),
`customer_group` Nullable(String)

)  ENGINE = MySQL(
	'rc1b-h6umc9xnez8xrxyw.mdb.yandexcloud.net:3306', 
	'magento-cloud', 
	'sales_order_grid', 
	'yc-user', 
	'12345678'
);


CREATE TABLE sales_order (
`entity_id` UInt32,
`status` Nullable(String),
`store_id` Nullable(UInt16),
`store_name` Nullable(String),
`customer_id` Nullable(UInt32),
`grand_total` Nullable(Float32),
`order_currency_code` String,
`created_at` DateTime,
`updated_at` DateTime,
`billing_address` Nullable(String),
`shipping_address` Nullable(String),   
`shipping_location` Nullable(String),
`shipping_information` Nullable(String),
`customer_email` Nullable(String),
`customer_group` Nullable(String)

) ENGINE = ReplacingMergeTree
  PARTITION BY toYYYYMM(`created_at`)
  ORDER BY (`entity_id`)
  TTL `created_at` + INTERVAL 1 MONTH TO DISK 'object_storage'; 
  
 
 
INSERT INTO inventory.sales_order (entity_id, status, store_id, store_name, customer_id, grand_total, order_currency_code, created_at, updated_at,
	billing_address, shipping_address, shipping_location, shipping_information, customer_email, customer_group)
SELECT  
	entity_id, status, store_id, store_name, customer_id, grand_total, order_currency_code, created_at, updated_at,
	billing_address, shipping_address, shipping_location, shipping_information, customer_email, customer_group
FROM mysql_sales_order_grid
WHERE entity_id > (SELECT MAX(entity_id) from sales_order); 


SELECT * FROM system.disks; 





--
-- MS SQL Server Sync
--

/* Не дало эффекта
drop table inventory.kafka_store_data ON CLUSTER '{cluster}' ;
CREATE TABLE inventory.kafka_store_data  ON CLUSTER '{cluster}' (
       store_id  UInt32,
       store_name String,
       store_address Nullable(String),
       store_location Nullable(String),
       description Nullable(String)
) ENGINE = Kafka SETTINGS kafka_broker_list = 'rc1a-rt35ilk2vrvspq82.mdb.yandexcloud.net:9091',
                kafka_topic_list = 'inventory.dbo.store_data',
                kafka_group_name = 'inventory-consumer-group',
                kafka_format = 'JSONEachRow'; 

drop table inventory.ch_store_data ON CLUSTER '{cluster}' ;
CREATE TABLE inventory.ch_store_data ON CLUSTER  '{cluster}' (
        store_id  UInt32,
        store_name String,
        store_address Nullable(String),
        store_location Nullable(String),
        description Nullable(String)
) ENGINE = ReplicatedMergeTree ('/clickhouse/tables/{shard}/ch_store_data', '{replica}')
ORDER BY (store_id);

drop VIEW inventory.materialized_store_data ON CLUSTER '{cluster}';
CREATE MATERIALIZED VIEW materialized_store_data ON CLUSTER '{cluster}' TO ch_store_data
AS SELECT  store_id, store_name, store_address, store_location, description
FROM kafka_store_data;
*/

CREATE VIEW inventory.ch_store_data (
    `store_id` Nullable(UInt32),
    `store_name` Nullable(String),
    `store_address` Nullable(String),
    `store_location` Nullable(String),
    `description` Nullable(String)
) AS SELECT
    JSONExtract(unparsed_row, 'store_id', 'UInt32') AS store_id,
    JSONExtract(unparsed_row, 'store_name', 'String') AS store_name,
    JSONExtract(unparsed_row, 'store_address', 'String') AS store_address,
    JSONExtract(unparsed_row, 'store_location', 'String') AS store_location,
    JSONExtract(unparsed_row, 'description', 'String') AS description
FROM inventory.inventory_dbo_store_data_unparsed; 




