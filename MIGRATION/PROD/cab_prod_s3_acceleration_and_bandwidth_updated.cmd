@echo off
timeout 1 >nul
set BUCKET_NAME=cab-backup-database
aws s3api put-bucket-accelerate-configuration --bucket %BUCKET_NAME% --accelerate-configuration Status=Enabled
aws configure set default.s3.use_accelerate_endpoint true

timeout 1 >nul
echo Set configuration for network bandwidth..
aws configure set default.s3.max_concurrent_requests 5
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.s3.max_bandwidth 5MB/s
if %ERRORLEVEL% neq 0 (
    echo Backup failed with error code %ERRORLEVEL%.
    goto end
)

timeout 1 >nul
echo max_concurrent_requests 5
timeout 1 >nul
echo max_queue_size 10000
timeout 1 >nul
echo s3.multipart_threshold 64MB
timeout 1 >nul
echo s3.multipart_chunksize 16MB
timeout 1 >nul
echo s3.max_bandwidth 5MB/s

:end
echo Set up complete.
pause