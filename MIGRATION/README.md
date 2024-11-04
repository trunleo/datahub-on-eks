# MIGRATION DATABASE WITH BACKUP/RESTORE MECHANISM
We have 2 folders for ``UAT`` environment and ``PROD`` environment:

+ [UAT Environment](https://github.com/renova-cloud/cab-dbm-aws/blob/61f7467755fb01e441d8eb847ffe738bacd02299/MIGRATION/UAT)
+ [PROD Environment](https://github.com/renova-cloud/cab-dbm-aws/blob/0986a5df72ec5f63919c74b6c3042984b8e4e83a/MIGRATION/PROD) 

In each folder, we have 2 folders for
+ ``BAKONG`` database: will be deployed on EC2
+ ``DIGITAL`` database: will be deployed on AWS RDS 

Both environments will use ``S3 Accelerator`` to transfer the ``backup files`` from ``On-premise`` to ``S3``. In addition, we also use ``bash scripts`` to backup database and ``SQL Scripts`` to restore database on AWS.

## [PROD ENVIRONMENT](./PROD/)
### SET UP S3 ACCELERATOR AND NETWORK BANDWIDTH
`Amazon S3 Transfer Acceleration`  can speed up content transfers to and from Amazon S3 by as much as 50-500% for long-distance transfer of larger objects.

`Network Bandwidth` will be limited to ``3Mib/s`` to **avoid affecting** customers' current bandwidth (the current bandwidth maximum is ``6Mib/s``)

Firstly, we must modify the ``BUCKET_NAME`` in [cab_prod_s3_acceleration_and_bandwidth](./PROD/cab_prod_s3_acceleration_and_bandwidth.cmd) to bucket name that ``CAB`` use to storing ``backup files`` on ``S3``

To start processing, we just run [cab_prod_s3_acceleration_and_bandwidth](./PROD/cab_prod_s3_acceleration_and_bandwidth.cmd) script with default setting. Or we can modify the parameter in scripts. 

The metrics that configured by default in scripts:
| Metrics name                       | Default Value | Customize Value |
|------------------------------------|---------------|-----------------|
| default.s3.max_concurrent_requests | 10            | 20              |
| default.s3.max_queue_size          | 1000          | 10000           |
| default.s3.multipart_threshold     | 8MB           | 64MB            |
| default.s3.multipart_chunksize     | 8MB           | 16MB            |
| default.s3.max_bandwidth           | None          | 3Mib/s          |

### FOR [BAKONG DATABASE](./PROD/BAKONG/)
**BAKONG** database is **PostgreSQL 12** which be deployed on ``AWS EC2 (Ubuntu 22.04)``

**HOW TO WORK**

1. Backup database on On-premise with [backup scripts](./PROD/BAKONG/backup_scripts/) 
2. The backup scripts will auto sync the backup files to ``S3`` through ``S3 Acceleration``
3. On AWS, we will connect to **Database** instance via ``SSH`` or ``AWS SSM``
4. Using [restore script](./PROD/BAKONG/restore_scripts/cab_prod_bakong_restoredb.sh) to restore database with backup file which be transfer to S3 at **Step 2**


### FOR [DIGITAL DATABASE](./PROD/DIGITAL/)
**DIGITAL** database is **SQL Server 19** which be deployed on ``AWS RDS for SQL Server``

**HOW TO WORK**

1. Open [full backup script for SQL Server](./PROD/DIGITAL/cab_prod_digitaldb_fullbackup.cmd) and modify some parameters:
   * **DB_NAME**: the name of backup database
   * **USER_DB**: the username of backup database
   * **PASSWD_DB**: the password of backup database
   * **BACKUP_DIR**: The path for storing backup files
   * **BUCKET_NAME**: The bucket name for storing backup files on AWS S3
2. This script will **full backup database** and **store full backup file** on local path. The backup file will be transfer to ``S3`` when backup **completed**
3. When ``backup file`` available on ``S3``, we will restore it to ``RDS instance`` with []()
4. Begin **the next day to cutover time**, we just only ``incremental backup`` with [differential backup](./PROD/DIGITAL/cab_prod_digitaldb_diffbackup.cmd) file
We also modify the parameters in this script:
   * **DB_NAME**: the name of backup database
   * **USER_DB**: the username of backup database
   * **PASSWD_DB**: the password of backup database
   * **BACKUP_DIR**: The path for storing backup files
   * **BUCKET_NAME**: The bucket name for storing backup files on AWS S3
5. This script will **incremental backup database** and **store incremental backup file** on local path. The backup file will be transfer to ``S3`` when backup **completed**
6. We will restore both ``full backup file`` and ``latest incremental backup file`` day by day until cutover time.