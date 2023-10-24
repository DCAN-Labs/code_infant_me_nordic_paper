#!/bin/bash -l

#SBATCH -J infant_pip
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --tmp=120gb
#SBATCH --mem=120gb
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/dcan_pip_%A_%a.out
#SBATCH -e output_logs/dcan_pip_%A_%a.err

SUB=${1}
SES=${2}
aseg_path=${3} #full path to segmentation, no / at end


data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_derivatives/DCAN_pip_derivatives_${SUB}_${SES}
# in_dir on tier 1
in_dir=/path/to/my/DCAN_pip_input/DCAN_pip_input_${SUB}_${SES}

#out dir on tier 1
out_dir=/hpath/to/my/DCAN_pip_derivatives/DCAN_pip_derivatives_${SUB}_${SES}


module load singularity; \
singularity exec --cleanenv \
-B ~/Documents/license.txt:/opt/freesurfer/license.txt \
-B ${in_dir}:/bids_input:ro \
-B ${out_dir}:/output \
-B ${aseg_path}:/aseg \
/path/to/my/DCAN-infant-BIDS/infant-abcd-bids-pipeline_v0.0.21.sif \
/entrypoint.sh /bids_input /output --freesurfer-license=/opt/freesurfer/license.txt \
--ncpus 13 --stages="DCANBOLDProcessing:ExecutiveSummary" --participant-label ${SUB} --session-id ${SES} --aseg /aseg/sub-${SUB}_ses-${SES}_aseg_cc.nii.gz --atropos-mask-method REFINE

#sync outputs back to s3
s3cmd sync ${out_dir}/ ${data_bucket_out}/ --recursive
