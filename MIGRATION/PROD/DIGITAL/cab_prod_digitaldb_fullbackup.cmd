@echo off
echo Set up variables ...

echo Set up database connection information
set DB_NAME=
set USER_DB=sa
set PASSWD_DB=Cab@2021!@#$a
set BUCKET_NAME=cab-backup-database

echo Backup Path: %BACKUP_DIR%
@REM Example BACKUP_DIR=D:\DIGITAL_BACKUP

echo Database name: %DB_NAME%
echo Username: %USER_DB%
echo The bucket on S3 for storing backup file on AWS: %BUCKET_NAME%

timeout 1 >nul
set BACKUP_DIR=
set BACKUP_FILE_NAME=DIFF_%DB_NAME%.BAK
set FILE_BACKUP_PATH=%BACKUP_DIR%\%BACKUP_FILE_NAME%
echo Backup Path: %FILE_BACKUP_PATH%
timeout 1 >nul

echo Starting full backup of %DB_NAME% database...

sqlcmd -U %USER_DB% -P "%PASSWD_DB%" -Q "BACKUP DATABASE %DB_NAME% TO DISK='%FILE_BACKUP_PATH%' WITH INIT, COMPRESSION"

if %ERRORLEVEL% neq 0 (
    echo Backup failed with error code %ERRORLEVEL%.
    eventcreate /T ERROR /L APPLICATION /ID 100 /D "SQL Server backup failed with error code %ERRORLEVEL%."
    goto end
)

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

