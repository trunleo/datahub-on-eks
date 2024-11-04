@echo off

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
ECHO Backup for: %YESTERDAY%

set FILE_BACKUP_PATH=%BACKUP_DIR%\%YESTERDAY%\%DB_NAME%_%YESTERDAY%.bak
set FOLDER_BACKUP_PATH=%BACKUP_DIR%\%YESTERDAY%\

echo Starting full backup of %DB_NAME% database...

echo Starting copy file to S3 bucket
aws s3 cp %FOLDER_BACKUP_PATH% s3://backup-mssql-cab/FULL/%YESTERDAY% --recursive
echo Copy file successfully

:end
echo Script complete.