export BACKUP_DIR=E:\4AWS
export BUCKET_NAME=cab-backup-database

echo The bucket on S3 for storing backup file on AWS: $BUCKET_NAME

export BACKUP_FILE_NAME=BFONLINE_20240228.BAK
export FILE_BACKUP_PATH=$BACKUP_DIR\\$BACKUP_FILE_NAME

echo $FILE_BACKUP_PATH

echo Copy file to S3 bucket

aws s3 cp %FILE_BACKUP_PATH% s3://$BUCKET_NAME/BAKONG-DB/FULL/$BACKUP_FILE_NAME --cli-connect-timeout 6000 

echo Copy file successfully

echo Script complete.
