
echo Set configuration for network bandwidth..
aws configure set default.s3.max_concurrent_requests 20
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.s3.max_bandwidth 5Mb/s

echo max_concurrent_requests 20
echo max_queue_size 10000
echo s3.multipart_threshold 64MB
echo s3.multipart_chunksize 16MB
echo s3.max_bandwidth 5Mb/s
echo Set up complete.
