#!/bin/bash -l

#SBATCH -J fmriprep
#SBATCH -c 4
#SBATCH --mem=950G
#SBATCH -t 35:00:00
#SBATCH --mail-type=ALL
#SBATCH -p ag2tb
#SBATCH -o output_logs/fmriprep_subpop%A_%a.out
#SBATCH -e output_logs/fmriprep_subpop%A_%a.err


singularity=`which singularity`

SUB=${1}
SES=combined
TASK=restMENORDICrmnoisevols

dataset_description=s3://mybucket/dataset_description.json
data_bucket_in=s3://mybucket/sub-${SUB} #s3 bids input folder (fMRIprep style)
data_bucket_out=s3://mybucket/derivatives/sub-${SUB} #s3 bucket where derivatives go to
data_bucket_out2=s3://mybucket/work/sub-${SUB} #s3 bucket where derivatives go to

# plus additional s3 path for where wordir should go
work_dir=/scratch.global/mypath/work_dir/fmri_prep_work_${SUB}_${SES}

if [ ! -d ${work_dir} ]; then
  mkdir -p ${work_dir}

fi  


#example from abcd bids workflow additionally add working dir
in_dir=/scratch.global/mypath/in_dir/fmri_prep_in_${SUB}_${SES}_${TASK}

if [ ! -d ${in_dir} ]; then
	mkdir -p ${in_dir}

fi
#sync content to data bucket in
s3cmd sync ${data_bucket_in}  ${in_dir}/ --recursive; 
s3cmd sync ${dataset_description}  ${in_dir}/; 


#create out dir use scratch.gloabl for this case as it allows to get edit the outputs for the next step and pick up processing from there 
out_dir=/scratch.global/mypath/out_dir/fmri_prep_${SUB}_${SES}

if [ ! -d ${out_dir} ]; then
	mkdir -p ${out_dir}

fi

  
  singularity run --cleanenv \
    -B /tmp:/tmp \
    -B ${in_dir}:/bids_dir \
    -B ${out_dir}:/output_dir \
    -B ${work_dir}:/wd \
    -B ~/Documents/license.txt:/opt/freesurfer/license.txt \
    /path/to/my/fmriprep_unstable_01262024.sif \
    --output-spaces MNI152NLin6Asym:res-2 \
    --fs-license-file /opt/freesurfer/license.txt \
    --project-goodvoxels \
    --omp-nthreads 3 \
    --cifti-output 91k \
    -vv \
    -w /wd \
  /bids_dir /output_dir participant


s3cmd sync ${out_dir} ${data_bucket_out}/ --recursive
s3cmd sync ${work_dir} ${data_bucket_out2}/ --recursive

