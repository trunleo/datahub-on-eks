@echo off

set DB_NAME=AdventureWorks2019
set USER_DB=sa
set PASSWD_DB=Trungnikonian22!
set BACKUP_DIR=E:\BACKUP\4Migarate_AWS

@For /F "tokens=2,3,4 delims=/ " %%A in ('Date /t') do @( 
    Set Month=%%A
    Set Day=%%B
    Set Year=%%C
)

@echo DAY = %Day%
@echo Month = %Month%
@echo Year = %Year%

set CURRENT_DATE=%Day%%Month%%Year%

for /f "delims=" %%a in ('powershell -Command [DateTime]::Today.AddDays^(-1^).ToString^(\"ddMMyyyy\"^)') do @Set YESTERDAY=%%a
ECHO %YESTERDAY%

set FILE_BACKUP_PATH=%BACKUP_DIR%\%YESTERDAY%\DIFF_%DB_NAME%_%YESTERDAY%.BAK

echo Curret date: %CURRENT_DATE%
echo Starting diff backup of %DB_NAME% database...

sqlcmd -U %USER_DB% -P "%PASSWD_DB%" -Q "BACKUP DATABASE %DB_NAME% TO DISK='%FILE_BACKUP_PATH%' WITH DIFFERENTIAL"

if %ERRORLEVEL% neq 0 (
    echo Backup failed with error code %ERRORLEVEL%.
    eventcreate /T ERROR /L APPLICATION /ID 100 /D "SQL Server backup failed with error code %ERRORLEVEL%."
    goto end
)

echo Old backup files deleted successfully.

echo Copy file to S3 bucket
aws s3 cp %FILE_BACKUP_PATH% s3://backup-mssql-cab/DIFF/%YESTERDAY%/DIFF_%DB_NAME%_%YESTERDAY%.bak
echo Copy file successfully

:end
echo Script complete.