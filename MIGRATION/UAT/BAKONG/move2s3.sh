# Set up backup date
cd 
# set location variables on AWS:
bucket_name=backup-mssql-cab
sub_path=/BAKONG

# set backup location
backup_root_path=/var/lib/postgresql/backup

backup_full_path=

aws s3 cp 

pg_restore -U postgres -d tps --no-owner --no-privileges --verbose 202309270944_pg_tps_backup.tar