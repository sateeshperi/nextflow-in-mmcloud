# Juiceflow - AWS

## Introduction

Juiceflow combines JuiceFS and Nextflow on MMCloud, offering a powerful, scalable solution for managing and executing workflows in the cloud.

<details>
<summary>Expand for more details on JuiceFS</summary>

[JuiceFS](https://juicefs.com/docs/community/introduction/) is an open-source, high-performance distributed file system designed specifically for cloud environments. It offers unique features, such as:

* Separation of Data and Metadata: JuiceFS stores files in chunks within object storage like Amazon S3, while metadata can be stored in various databases, including Redis.
* Performance: Achieves millisecond-level latency and nearly unlimited throughput, depending on the object storage scale.
* Easy Integration with MMCloud: MMCloud provides pre-configured nextflow head node templates with JuiceFS setup, simplifying deployment.
* Comparison with S3FS: For a detailed comparison between JuiceFS and S3FS, see [JuiceFS vs. S3FS](https://juicefs.com/docs/community/comparison/juicefs_vs_s3fs/). JuiceFS typically offers better performance and scalability.


</details>

---

## Pre-requisites

- A security group for controlling traffic to and from your AWS resources.
- AWS S3 buckets for Nextflow work and output directories.
- Your AWS S3 keys

<details>
<summary>Expand for instructions on creating the required security group</summary>

- **Inbound rules should include:**
    - SSH over TCP on port 22 for secure shell access.
    - HTTPS over TCP on port 443 for secure web traffic.
    - Custom TCP over TCP on port 6868, used by the Redis server in this setup.

- **Navigation:** AWS EC2 console -> Network & Security -> Security Groups

![Security Group Configuration](https://hackmd.io/_uploads/SJK_BoMlA.png)

</details>

---

## Overview of the Setup

This solution leverages two scripts:
- `transient_JFS.sh`: Formats the work directory S3 bucket to JuiceFS format.
- `job-submit.sh`: Contains Nextflow input parameters and MMC config.

---

## Steps


* Login to your MMCloud opcenter:

```bash!
float login -a <opcenter-ip-address> -u <user>
```

### Download Scripts

* Host-init script

```bash!
wget https://mmce-data.s3.amazonaws.com/juiceflow/v1/aws/transient_JFS.sh
```

* Job-submit script (Download the template or create one locally based on the template below with your Nextflow inputs and run configurations)

```bash!
wget https://mmce-data.s3.amazonaws.com/juiceflow/v1/aws/job_submit.sh
```

<details>
<summary>Expand to view a sample job-submit.sh script</summary>

```bash!
#!/bin/bash

# ---- User Configuration Section ----
# These configurations must be set by the user before running the script.

# OpCenter IP Address: IP address for the OpCenter.
opcenter_ip_address='0.00.000.000'

# OpCenter Credentials: Username and password for accessing OpCenter.
opcenter_username='<username>'
opcenter_password='<password>'

# ---- Optional Configuration Section ----
# These configurations are optional and can be customized as needed.

# JFS (JuiceFS) Private IP: Retrieved from the WORKER_ADDR environment variable.
jfs_private_ip=$(echo $WORKER_ADDR)

# AWS S3 Access and Secret Keys: For accessing S3 buckets.
accessKey=$(echo $BUCKET_ACCESS_KEY)
secretKey=$(echo $BUCKET_SECRET_KEY)

# Work Directory: Defines the root directory for working files. Optional suffix can be added.
workDir_suffix=''
workDir='/mnt/jfs/'$workDir_suffix
mkdir -p $workDir  # Ensures the working directory exists.
cd $workDir  # Changes to the working directory.
export NXF_HOME=$workDir  # Sets the NXF_HOME environment variable to the working directory.

# ---- Nextflow Configuration File Creation ----
# This section creates a Nextflow configuration file with various settings for the pipeline execution.

# Use cat to create or overwrite the mmc.config file with the desired Nextflow configurations.
cat > mmc.config << EOF
// enable nf-float plugin.
plugins {
    id 'nf-float'
}

// Process settings: Executor, error strategy, and resource allocation specifics.
process {
    executor = 'float'
    errorStrategy = 'retry'

    extra = '--dataVolume [opts=" --cache-dir /mnt/jfs_cache "]jfs://${jfs_private_ip}:6868/1:/mnt/jfs --dataVolume [size=120]:/mnt/jfs_cache --vmPolicy [spotOnly=true,retryLimit=10,retryInterval=300s]'
}

// Directories for Nextflow execution.
workDir = '${workDir}'
launchDir = '${workDir}'

// OpCenter connection settings.
float {
    address = '${opcenter_ip_address}'
    username = '${opcenter_username}'
    password = '${opcenter_password}'
}

// AWS S3 Client configuration.
aws {
  client {
    maxConnections = 20
    connectionTimeout = 300000
  }
  accessKey = '${accessKey}'
  secretKey = '${secretKey}'
}
EOF

# ---- Data Preparation ----
# Copies essential files from S3 to the working directory.

# Copy the sample sheet and params.yml from S3 to the current working directory.
aws s3 cp s3://nextflow-input/samplesheet.csv .
aws s3 cp s3://nextflow-input/scripts/params.yml .

# ---- Nextflow Command Setup ----
# Important: The -c option appends the mmc config file and soft overrides the nextflow configuration.

# Assembles the Nextflow command with all necessary options and parameters.
nextflow_command='nextflow run <nextflow-pipeline> \
-r <revision-number> \
-c mmc.config \
-params-file params.yml \
--input samplesheet.csv \
--outdir 's3://nextflow-output/rnaseq/' \
-resume '

# -------------------------------------
# ---- DO NOT EDIT BELOW THIS LINE ----
# -------------------------------------
# The following section contains functions and commands that should not be modified by the user.

# Function to export AWS keys for the current session.
function aws_keys() {
  local access_key=$(echo $BUCKET_ACCESS_KEY)
  local secret_key=$(echo $BUCKET_SECRET_KEY)
  export AWS_ACCESS_KEY_ID=$access_key
  export AWS_SECRET_ACCESS_KEY=$secret_key
}

# Function to find and remove old metadata from the S3 bucket.
function remove_old_metadata () {
  echo $(date): "First finding and removing old metadata..."
  # Logic to find and delete old metadata files.
}

# Function to dump JuiceFS metadata and copy it to an S3 bucket.
function dump_and_cp_metadata() {
  echo $(date): "Attempting to dump JuiceFS data"
  # Logic for dumping and copying metadata.
}

# Variables initialization.
FOUND_METADATA=""

# Start the Nextflow run and handle errors or success.
$nextflow_command

if [[ $? -ne 0 ]]; then
  echo $(date): "Nextflow command failed."
  # If the Nextflow command fails, execute error handling routines.
  aws_keys
  remove_old_metadata
  dump_and_cp_metadata
  exit 1
else 
  echo $(date): "Nextflow command succeeded."
  # If the Nextflow command succeeds, proceed with cleanup and metadata handling.
  aws_keys
  remove_old_metadata
  dump_and_cp_metadata
  exit 0
fi

```

</details>

### Job-Submit Script Adjustments

* First, assign values to the OpCenter configuration settings:

```bash
# OpCenter Configuration
opcenter_ip_address='192.168.1.1' # Example IP, replace with actual
opcenter_username='admin'         # Example username, replace with actual
opcenter_password='password'      # Example password, replace with actual
```

* Then, modify the `process.extra` within the `mmc.config` section to customize the `vmPolicy` (Default policy is `spotFirst`. Adjust as needed e.g., `onDemand`, `spotOnly`). You may find more options when calling `float submit -h`:

```bash
--vmPolicy [spotOnly=true,retryLimit=10,retryInterval=300s]
```

For handling samplesheets and params file, you have two options: download them or create them directly in the script. Here’s how to do both:

### Downloading Samplesheet and Params File

* Provide download commands for users to obtain samplesheet and params file for Nextflow, ensuring you replace `<download-link>` with the actual URLs:

```bash
# Download samplesheet
aws s3 cp s3://nextflow-input/samplesheet.csv .

# Download params file
aws s3 cp s3://nextflow-input/params.yml .
```

### Creating Samplesheet and Params File Directly in the Script

* Alternatively, users can create these files directly within the script using the `cat` command as shown below.

<details>
<summary>Expand to include instructions on creating samplesheet and params files directly in the script</summary>

```bash
# Create samplesheet
cat > samplesheet.csv << EOF
sample,fastq_1,fastq_2,strandedness
AL_TO_rep01,s3://nextflow-input/Sample_1_L007_R1_001.fastq.gz,s3://nextflow-input/Sample_1_L007_R2_001.fastq.gz,auto
AL_TO_rep01,s3://nextflow-input/Sample_2_L008_R1_001.fastq.gz,s3://nextflow-input/Sample_2_L008_R2_001.fastq.gz,auto
AL_TO_rep01,s3://nextflow-input/Sample_3_L014_R1_001.fastq.gz,s3://nextflow-input/Sample_3_L014_R2_001.fastq.gz,auto
AL_TO_rep01,s3://nextflow-input/Sample_4_L009_R1_001.fastq.gz,s3://nextflow-input/Sample_4_L009_R2_001.fastq.gz,auto
EOF

# Create params file
cat > params.yml << EOF
multiqc_title: "rnaseq_multiqc"
fasta: "s3://nextflow-input/reference/Caenorhabditis_elegans.WBcel235.dna.toplevel.fa.gz"
gtf: "s3://nextflow-input/reference/Caenorhabditis_elegans.WBcel235.111.gtf.gz"
save_reference: true
remove_ribo_rna: true
skip_alignment: true
pseudo_aligner: "salmon"
EOF
```

</details>

---

* Finally, ensure you customize your `nextflow_command` with specific pipeline requirements and save the changes:

```bash
nextflow_command='nextflow run your_pipeline.nf \
-r your_revision \
-c mmc.config \
-params-file params.yml \
--input samplesheet.csv \
--outdir your_output_directory \
-resume'
```

> Remember to replace placeholders with your specific pipeline details. 

---

### Float Submit Command

* Replace the placeholders `<work-bucket>`, `<region>`, AWS `<access>` key, `<secret>` key, `<security-group>`, and `<job-name>` with your specific values and execute the float submit command:

```bash!
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

---

## Monitoring on OpCenter

* Proceed to the OpCenter `Jobs` dashboard to monitor the progress of the job

![image](https://hackmd.io/_uploads/Hk1fv3MxA.png)
    
* Once the job starts `Executing`, you can monitor the Nextflow stdout by clicking on the job -> `Attachments` -> `stdout.autosave`:

![image](https://hackmd.io/_uploads/BygRFG71C.png)

---

> Once the files have been staged, the `nf-float` plugin in the Nextflow config will start sending processes to mmcloud for execution.

* Click on the `Workflows` dashboard in the OpCenter to monitor workflow execution and get a detailed view for each process in the Nextflow workflow:

![image](https://hackmd.io/_uploads/B1wg2zQJC.png)

* Click on the workflow name, and you can monitor the jobs running in this workflow in this consolidated view:

![image](https://hackmd.io/_uploads/Sk9-g7mkC.png)

---

### Resuming Workflows with the Job-Submit Script

The job-submit script also allows the resuming of failed Nextflow workflows. You may simply resubmit your previous command again, using the same Bucket. This time, ensure that your Nextflow command include a `-resume`.
    
---

# Create Job Templates to Launch via GUI

Job Templates allow for the ease and customaization of runs that follow a similar format, without having the need to manually set up a command every time. It requires the submission of one job first.

* From the `Jobs` dashboard, select the jfs-service job previously submitted above and click on `More Actions` -> `Save as Template` (NOTE: this is still a BETA feature):

![image](https://hackmd.io/_uploads/rJugK78pp.png)

* Provide a name and tag for the private template:

![image](https://hackmd.io/_uploads/H1kBCGmkC.png)

* Navigate to the `Job Templates` dashboard and click on `Private` templates:

![image](https://hackmd.io/_uploads/rk-FRGmyA.png)

![image](https://hackmd.io/_uploads/H1rtJ7XyA.png)

* You can click on any job template, edit/change samplesheet, variables etc., and submit new jobs from the GUI.

![image](https://hackmd.io/_uploads/ry88l6GxA.png)

> * Users can also submit jobs from templates via CLI
>```bash!
>float submit --template private::<template-name>:<template-tag> \
>-e BUCKET=s3://<aws-jfs-bucket>
>```
> Addtionally, please keep in mind the features that need to be updated with every run if they deviate from the default values provided in the public template. This will mainly include:
> * S3 Bucket URL + keys
> * Updating of the job script in accordance to your pipeline run