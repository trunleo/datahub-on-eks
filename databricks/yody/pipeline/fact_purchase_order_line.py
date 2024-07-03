#!/usr/bin/env python
# coding: utf-8

# # fact_purchase_order_line

from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
from pyspark.sql.window import Window
from datetime import datetime, timedelta
from yody_function import upsert_deltalake
from yody_function.bigquery import upsert_bigquery
from yody_function.support_function import last_modify_time
import time
from google.cloud import storage, bigquery


start = time.time()
SPARK_HOME = 'yarn'
ENV = 'prod'
HDFS_MASTER = 'gs://yody-lakehouse'
DATA_SOURCE = 'lading-zone'
SCHEMA_NAME = 'prod_purchase_order_service'
TARGET_TABLE_TYPE = 'fact'
TARGET_TABLE_NAME = 'fact_purchase_order_line'
DATA_STORE = f'/dwh/{ENV}/{TARGET_TABLE_TYPE}/'
TARGET_PATH_TABLE = HDFS_MASTER+DATA_STORE+TARGET_TABLE_NAME
MODE = 'upsert'
#MODE = 'overwrite'
SESSION_NAME = f'{TARGET_TABLE_NAME}_{ENV}'



sparkSession = SparkSession    .builder    .appName(SESSION_NAME)    .master(SPARK_HOME)    .config("spark.sql.debug.maxToStringFields", 255)    .config("spark.sql.parquet.enableVectorizedReader", "false")    .config("spark.jars","gs://yody-lakehouse/job/jar_file/delta-core_2.12-1.0.1.jar")    .config('spark.jars', 'gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.28.0.jar,gs://yody-lakehouse/job/jar_file/delta-core_2.12-1.0.1.jar')    .config("spark.executor.max", '4')    .config("spark.executor.memory", '4g')    .getOrCreate()



def get_log(message, log_type='INFO'):
    time = (datetime.now()+timedelta(hours = 7)).strftime("%d-%m-%Y %H:%M:%S")
    log_mess = log_type + ": " + time + ' - '+ message
    return log_mess
    
def get_json_info(env, table_name):
    json_info = {
    "project_id": "yody-data-platform",
    "dataset": f"{env}_yody_analytics",
    "table_name": table_name
    }
    return json_info

def get_source_path(schema_name, source_table):
    path = f'{HDFS_MASTER}/{DATA_SOURCE}/prod/{schema_name}/{source_table}/*'
    return path   

def check_folder_exist(paths):
    storage_client = storage.Client()
    bucket_name = 'yody-lakehouse'
    bucket = storage_client.bucket(bucket_name)

    file_paths = []
    for path in paths:
        if len(list(bucket.list_blobs(prefix=path[20:-1]))) > 0:
            file_paths.append(path)
        else:
            print(get_log('Not found path in storage '+path, log_type='WARN'))
    storage_client.close()
    return file_paths

def get_processing_path(base_path):
    base_path = base_path[:-2]
    current_date = datetime.today()
    past_date = current_date - timedelta(days=2)
    start_date, end_date = past_date, current_date
    date_range = [start_date + timedelta(days=x) for x in range((end_date - start_date).days + 1)]
    raw_paths = [f"{base_path}/date_crawler={date.date()}*" for date in date_range]
    file_paths = check_folder_exist(raw_paths)
    file_paths = [base_path] if not file_paths else file_paths
    return file_paths


def get_deleted_query(json_info, deleted_str='is_deleted'):
    project = json_info['project_id']
    dataset = json_info['dataset']
    table = json_info['table_name']
    
    query_job = f'DELETE FROM `{project}.{dataset}.{table}` WHERE {deleted_str} = True'
    return query_job

def apply_columns(df, columns, func=None, naming_func=None):
    for col in columns:
        new_name = col
        if naming_func:
            new_name = naming_func(col)
        df = df.withColumn(new_name, func(col))
    return df
def process_table(params):
    # load variables
    schema_name = params['schema_name'] 
    source_name = params['source_name']
    table_name = params['table_name']
    write_mode = params['write_mode']
    columns_key = [i.strip() for i in params['columns_key'].split(', ')]
    output_cols = [i.strip() for i in params['output_cols'].split(', ')]
    prep_func = params['preprocess_function']
    truncate_flag = True if write_mode == 'overwrite' else False
    remove_mode = ('remove_mode' in params) and params['remove_mode']
    
    # extract
    print(get_log(f"preprocess table {table_name}"))
    source_path = get_source_path(schema_name, source_name)
    paths = get_processing_path(source_path) if write_mode =='upsert' else [source_path]
    df = sparkSession.read.option('mergeSchema', 'true').parquet(*paths)
    print(paths)
    
    # transform
    target_table = prep_func(df).select(output_cols)
    target_table.printSchema()
    
    #return target_table
    # load
    ## load HDFS
    print(get_log(f"write to HDFS table: {table_name}"))
    upsert_deltalake(sparkSession=sparkSession,
                     df_upsert=target_table,
                     path_table=TARGET_PATH_TABLE,
                     columns_key=columns_key,
                     mode=write_mode)
    ## load bigquery
    json_info = get_json_info(ENV, table_name)
    deleted_query = get_deleted_query(json_info) if remove_mode else None
    print(get_log(f"write to big query table {table_name}"))
    upsert_bigquery(df_upsert=target_table, 
                    json_info=json_info, 
                    columns_key=columns_key,
                    query_after_upsert=deleted_query,
                    truncate=truncate_flag,
                    mode=write_mode)
    
    return target_table


convert_longtype = lambda x: F.col(x).cast('long')
convert_decimal = lambda x: F.col(x).cast('decimal(19, 2)')
convert_time_07 = lambda column_name: F.to_timestamp(F.col(column_name)+F.expr(f'INTERVAL 7 HOURS'))
convert_date_07 = lambda column_name: F.to_date(F.col(column_name)+F.expr(f'INTERVAL 7 HOURS'))
convert_date_key_07 = lambda column_name: F.date_format(F.col(column_name)+F.expr(f'INTERVAL 7 HOURS'), 'yyyyMMdd').cast('long')
def preprocess_purchase_order():
    source_po = get_source_path(SCHEMA_NAME, 'purchase_order')
    df_po = sparkSession.read.option('mergeSchema', 'true').parquet(source_po)
    df_po = last_modify_time(df_po, 'id', 'updated_date')
    df_po = apply_columns(df_po, ['id', 'supplier_id'], func=convert_longtype)
    df_po = apply_columns(df_po, ['status', 'merchandiser', 'supplier'], func=F.upper)
    df_po = df_po    .withColumn('activated_time_07', convert_time_07('activated_date'))    .withColumn('activated_date_07', F.to_date('activated_time_07'))    .withColumn('created_time_07', convert_time_07('created_date'))    .withColumn('locked_time_07', convert_time_07('locked_at'))
    
    cols_po = ['id AS purchase_order_id', 'code AS purchase_order_code', 'status AS purchase_order_status',
               'merchandiser_code', 'merchandiser', 'supplier_id', 'supplier', 
               'activated_date_07 AS purchase_order_activated_date_07',
               'activated_time_07 AS purchase_order_activated_time_07',
               'created_time_07 AS purchase_order_created_time_07',
               'locked_time_07 AS purchase_order_locked_time_07',
               'updated_date AS po_updated_date', 
               'is_deleted AS po_is_deleted']
    df_po = df_po.selectExpr(*cols_po)
    
    # read update purchase_order
    source_update = get_processing_path(source_po)
    df_po_update = sparkSession.read.option('mergeSchema', 'true').parquet(*source_update)
    df_po_update = df_po_update.selectExpr('id AS purchase_order_id')
    df_po_update = df_po_update.limit(0) if MODE =='overwrite' else df_po_update
    
    return df_po, df_po_update
def transform(df):
    # purchase_order - side table
    df_po, df_po_update = preprocess_purchase_order()
    
    # purchase_order_lines - source table
    ## fetch updated purchase_order_line data by its updated purchase_order
    source_pol = get_source_path(SCHEMA_NAME, 'purchase_order_lines')
    df_pol_all = sparkSession.read.option('mergeSchema', 'true').parquet(source_pol)
    
    cols = ['id', 'purchase_order_id', 'variant_id', 'product_id', 'sku', 'price', 'retail_price', 'quantity',
            'created_date', 'tax_rate', 'amount', 'updated_date', 'is_deleted']
    
    df_pol_update = df_pol_all.join(df_po_update, ['purchase_order_id'], 'inner')
    
    ## union all updated data
    df_pol_update = df_pol_update.select(cols)
    df = df.select(cols)
    df_pol = df.union(df_pol_update)

    df_pol = last_modify_time(df_pol, 'id', 'updated_date')
    df_pol = df_pol.withColumn("vat_rate", F.coalesce(F.col("tax_rate")/F.lit(100), F.lit(0.0)))
    df_pol = apply_columns(df_pol, ['id', 'product_id', 'variant_id'], func=convert_longtype)
    df_pol = apply_columns(df_pol, ['price', 'retail_price', 'amount', 'quantity', 'vat_rate'], 
                           func=convert_decimal)
    df_pol = df_pol    .fillna(0, subset=['price', 'retail_price', 'amount', 'quantity'])    .withColumn('created_date_key_07', convert_date_key_07('created_date'))
    
    cols_pol = ['id AS purchase_order_line_key', 'id AS purchase_order_line_id', 'purchase_order_id', 'variant_id', 
                'product_id', 'sku', 'price', 'retail_price', 'quantity AS merchandise_planned_quantity', 'quantity',
                'created_date_key_07', 'amount', 'updated_date AS pol_updated_date', 'vat_rate',
                'is_deleted AS pol_is_deleted']
    
    df_pol = df_pol.selectExpr(*cols_pol)
    
    # Join source table to side table on parent key.
    df_trans = df_pol.join(df_po, ['purchase_order_id'], "left")
    df_trans = df_trans    .withColumn('__update_at', F.greatest(F.to_timestamp('po_updated_date'), F.to_timestamp('pol_updated_date')))    .withColumn('is_deleted', (F.col('po_is_deleted') | F.col('pol_is_deleted')).cast('boolean'))
    
    return df_trans


params = {'schema_name': SCHEMA_NAME, 
          'source_name': 'purchase_order_lines',
          'table_name': TARGET_TABLE_NAME,
          'columns_key': 'purchase_order_line_key',
          'output_cols': 'purchase_order_line_key, purchase_order_line_id, merchandiser_code, merchandiser, '+\
                         'product_id, supplier_id, supplier, sku, variant_id, purchase_order_id, '+\
                         'purchase_order_code, purchase_order_status, price, retail_price, quantity, '+\
                         'created_date_key_07, merchandise_planned_quantity, amount, '+\
                         'purchase_order_activated_date_07, purchase_order_created_time_07, '+\
                         'purchase_order_activated_time_07, is_deleted, vat_rate, __update_at, '+\
                         'purchase_order_locked_time_07',
          'preprocess_function': transform,
          'write_mode': MODE,
          'remove_mode': True
         }
target_table = process_table(params)


sparkSession.stop()
stop = time.time()

print("Time executed: ", (stop-start)/60, 'mins')

