
* Float user login to MMCloud Opcenter

```
float login -a <opcenter-ip-address> -u <user> -p <pass>
```


* Submit jfs-service that will mount the work directory required for nextflow

```
float submit -n jfs-service \
--template nextflow:jfs \
--securityGroup <security-group> \
-e BUCKET=https://<jfs-s3-work-bucket>.s3.us-east-1.amazonaws.com \
--env BUCKET_ACCESS_KEY={secret:BUCKET_ACCESS_KEY_NAME} \
--env BUCKET_SECRET_KEY={secret:BUCKET_SECRET_KEY_NAME} \
-c 2 -m 4
```

* Submit nextflow job

```
float submit -n nextflow-head-1 \
-i docker.io/nextflow/nextflow:latest \
--dataVolume [opts=" --cache-dir /mnt/jfs_cache "]jfs://<private-ip-address>:6868/1:/mnt/jfs \
--withRoot \
--vmPolicy [onDemand=true] \
-j pipeline_submit.sh \
-c 4 -m 8
```
