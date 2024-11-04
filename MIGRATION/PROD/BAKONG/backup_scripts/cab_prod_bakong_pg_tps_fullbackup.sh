#!/bin/bash

# Backup directory and name suffix
BACKUP_DIR=/var/lib/postgresql/backup
FILE_SUFFIX=_pg_tps_backup.tar
DAY=`date +"%A"`
DIR_DATE=`date +"%Y%m%d"`
# Name file using the date and supplied suffix
FILE=`date +"%Y%m%d%H%M"`${FILE_SUFFIX}

# AWS variables
database_name=tps 
bucket_name=backup-mssql-cab
sub_path=/BAKONG

#Create directory with date
FULL_DIR=${BACKUP_DIR}/${DAY}/${DIR_DATE}
mkdir -p  ${FULL_DIR}
# Combine the backup directory and file name
OUTPUT_FILE=${BACKUP_DIR}/${DAY}/${DIR_DATE}/${FILE}
# Execute the backup as a tar

#db tps
pg_dump -F t tps > ${OUTPUT_FILE}

aws s3 cp ${OUTPUT_FILE} s3://${bucket_name}${sub_path}/${database_name}/${DIR_DATE}/${FILE}

#!/bin/bash

# Backup directory and name suffix
FILE_SUFFIX=_pg_tps_backup.tar
DAY=`date +"%A"`
DIR_DATE=`date +"%Y%m%d"`

# Name file using the date and supplied suffix
FILE=`date +"%Y%m%d%H%M"`${FILE_SUFFIX}

#AWS variables
database_name=tps
sub_path=/BAKONG

FULL_DIR=/home/postgres/backup_file
/home/postgres/backup_file/BAKONG/tps/20230927