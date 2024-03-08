#!/bin/bash
ogDir=$(pwd)

# [REQUIRED] Setup required by user
jfs_private_ip=''
address=''
username=''
password=''
accessKey=''
secretKey=''

# [OPTIONAL] Working directories will be under `/mnt/jfs/nextflow/`
workDir_suffix=''

# Directory setup
workDir='/mnt/jfs/nextflow/'$workDir_suffix
mkdir -p $workDir
cd $workDir

# Variable setup
export HOME=/mnt/jfs/nextflow
JFS_MOUNT_POINT=${JFS_MOUNT_POINT:-/mnt/jfs}
export NXF_HOME=$workDir

# Create config file
cat > mmc.config << EOF

params {
    multiqc_title   = "jrollins_2014_multiqc"
    fasta           = "s3://mmcloud-workshop/references/Caenorhabditis_elegans.WBcel235.dna.chromosome.all.fa.gz"
    gtf             = "s3://mmcloud-workshop/references/Caenorhabditis_elegans.WBcel235.110.gtf.gz"
    save_reference  = true
    remove_ribo_rna = true
    aligner         = "star_salmon"
    pseudo_aligner  = "salmon"
}

plugins {
    id 'nf-float'
}

process {
    executor      = 'float'
    errorStrategy = 'retry'
    withName: "QUALIMAP_RNASEQ" {
     extra = ' --dataVolume [opts=" --cache-dir /mnt/jfs_cache -o writeback_cache"]jfs://${jfs_private_ip}:6868/1:/mnt/jfs'
   }
    withName: 'STAR_ALIGN' {
        cpus    = 16
        memory  = '28.GB'
    }
}

workDir   = '${workDir}'
launchDir = '${workDir}'

float {
    address     = '${address}'
    username    = '${username}'
    password    = '${password}'
    commonExtra = ' --withRoot --dataVolume jfs://${jfs_private_ip}:6868/1:/mnt/jfs --vmPolicy [spotOnly=true,retryLimit=10,retryInterval=300s]'
    timefactor  = 5
}

aws {
  client {
    maxConnections = 20
    connectionTimeout = 300000
  }
  accessKey = '${accessKey}'
  secretKey = '${secretKey}'
}
EOF

# Create samplesheet
cat > jrollins-2014-samplesheet.csv << EOF
sample,fastq_1,fastq_2,strandedness
AL_TO_rep01,s3://mmcloud-workshop/input-data/AL_total_1_ACAGTG_L007_R1_001.fastq.gz,s3://mmcloud-workshop/input-data/AL_total_1_ACAGTG_L007_R2_001.fastq.gz,auto
AL_TO_rep01,s3://mmcloud-workshop/input-data/AL_total_1_ACAGTG_L008_R1_001.fastq.gz,s3://mmcloud-workshop/input-data/AL_total_1_ACAGTG_L008_R2_001.fastq.gz,auto
DR_TO_rep01,s3://mmcloud-workshop/input-data/DR_total_1_TTAGGC_L007_R1_001.fastq.gz,s3://mmcloud-workshop/input-data/DR_total_1_TTAGGC_L007_R2_001.fastq.gz,auto
DR_TO_rep01,s3://mmcloud-workshop/input-data/DR_total_1_TTAGGC_L008_R1_001.fastq.gz,s3://mmcloud-workshop/input-data/DR_total_1_TTAGGC_L008_R2_001.fastq.gz,auto

EOF

# [REQUIRED] Start Nextflow run
nextflow run nf-core/rnaseq \
-r 3.14.0 \
-c mmc.config \
--input jrollins-2014-samplesheet.csv \
--outdir 's3://nextflow-work-dir-public/jrollins_2014_rnaseq_output'
 
