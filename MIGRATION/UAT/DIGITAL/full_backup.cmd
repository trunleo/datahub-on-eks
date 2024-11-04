@echo off
echo Set up variables ...

set DB_NAME=AdventureWorksDW2019
set USER_DB=sa
set PASSWD_DB=Trungnikonian22!
set BACKUP_DIR=D:\BACKUP_FULL
set BUCKET_NAME=poc-mssql-express

echo Database name: %DB_NAME%
echo Username: %USER_DB%
echo The bucket on S3 for storing backup file on AWS: %BUCKET_NAME%

@For /F "tokens=2,3,4 delims=/ " %%A in ('Date /t') do @( 
    Set Month=%%A
    Set Day=%%B
    Set Year=%%C
)

@echo DAY = %Day%
@echo Month = %Month%
@echo Year = %Year%

timeout 1 >nul

set CURRENT_DATE=%Day%%Month%%Year%
echo Curret date: %CURRENT_DATE%

set FILE_BACKUP_PATH=%BACKUP_DIR%\%YESTERDAY%\FULL_%DB_NAME%_%CURRENT_DATE%.BAK
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
aws s3 cp %FILE_BACKUP_PATH% s3://%BUCKET_NAME%/DIGITAL-DB/FULL/FULL_%DB_NAME%_%CURRENT_DATE%.bak
if %ERRORLEVEL% neq 0 (
    echo Backup failed with error code %ERRORLEVEL%.
    goto end
)
timeout 1 >nul
echo Copy file successfully

:end
echo Script complete.
pause