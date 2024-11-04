@echo off
echo Set up variables ...

set DB_NAME=BFONLINE
set USER_DB=sa
set PASSWD_DB=Cab@2021!@#$a
set BACKUP_DIR=E:\4AWS
set BUCKET_NAME=cab-backup-database

echo Username: %USER_DB%
echo The bucket on S3 for storing backup file on AWS: %BUCKET_NAME%

timeout 1 >nul

set BACKUP_FILE_NAME=BFONLINE_20240228.BAK
set FILE_BACKUP_PATH=%BACKUP_DIR%\%BACKUP_FILE_NAME%

echo Copy file to S3 bucket
timeout 1 >nul
aws s3 cp %FILE_BACKUP_PATH% s3://%BUCKET_NAME%/DIGITAL-DB/FULL/%BACKUP_FILE_NAME% --cli-connect-timeout 6000 
if %ERRORLEVEL% neq 0 (
    echo Backup failed with error code %ERRORLEVEL%.
    goto end
)
timeout 1 >nul
echo Copy file successfully

:end
echo Script complete.
pause