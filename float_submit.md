
* Float user login to MMCloud Opcenter

```
float login -a <opcenter-ip-address> -u <user> -p <pass>
```


* Replace the placeholders <work-bucket>, <region>, AWS <access> key, <secret> key, <security-group>, and <job-name> with your specific values and execute the float submit command:

```
float submit --hostInit transient_JFS.sh \
-i docker.io/ashleytung148/transient-jfs \
--dirMap /mnt/jfs:/mnt/jfs \
--dataVolume '[size=60]:/mnt/jfs_cache' \
--vmPolicy '[onDemand=true]' \
--migratePolicy '[disable=true]' \
--env BUCKET=https://<work-bucket>.s3.<region>.amazonaws.com \
--env BUCKET_ACCESS_KEY=<access> \
--env BUCKET_SECRET_KEY=<secret> \
--securityGroup <security-group> \
-c 2 -m 4 \
-n <job-name> \
-j job-submit.sh
```
