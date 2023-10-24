#!/bin/bash -l

#SBATCH -J infant_pip
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --tmp=120gb
#SBATCH --mem=120gb
#SBATCH -t 72:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/dcan_pip_%A_%a.out
#SBATCH -e output_logs/dcan_pip_%A_%a.err

SUB=${1}
SES=${2}

data_bucket_in=s3://mybucket/sub-${SUB}/DCAN_pip_input/DCAN_pip_input_${SUB}_${SES}
data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_derivatives/DCAN_pip_derivatives_${SUB}_${SES}

in_dir=/tmp/DCAN_pip_in_${SUB}_${SES}

if [ ! -d ${in_dir} ]; then
	mkdir -p ${in_dir}

fi
#sync content to data bucket in
s3cmd sync ${data_bucket_in}/  ${in_dir}/ --recursive; 

#create out dir
out_dir=/tmp/DCAN_pip_out_${SUB}_${SES}

if [ ! -d ${out_dir} ]; then
	mkdir -p ${out_dir}

fi


module load singularity; \
singularity exec --cleanenv \
-B ~/Documents/license.txt:/opt/freesurfer/license.txt \
-B ${in_dir}:/bids_input:ro \
-B ${out_dir}:/output \
/path/to/my/DCAN-infant-BIDS/infant-abcd-bids-pipeline_v0.0.21.sif \
/entrypoint.sh /bids_input /output --freesurfer-license=/opt/freesurfer/license.txt \
--ncpus 13 --stages="PreFreeSurfer:FreeSurfer" --participant-label ${SUB} --session-id ${SES} --atropos-mask-method CREATE --jlf-method T2W

#sync outputs back to s3
s3cmd sync ${out_dir}/ ${data_bucket_out}/ --recursive
