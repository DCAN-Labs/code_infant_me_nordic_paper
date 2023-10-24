#!/bin/bash -l

#SBATCH -J motion_correction
#SBATCH --ntasks=16
#SBATCH --tmp=320gb
#SBATCH --mem=320gb
#SBATCH -t 12:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/motion_correction.out
#SBATCH -e output_logs/motion_correction.err

module load fsl/5.0.10;

SUB=${1}
SES=${2}
#RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13");
RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09");

data_bucket_in=s3://mybucket/sub-${SUB}/BIDS_input_folders/Nibabies_input_${SUB}_${SES}
data_bucket_in2=s3://mybucket/sub-${SUB}/DCAN_pip_work/motion_regressors_echo-1
data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_work/motion_corrected_echos

work_dir=/tmp/motion_correction_work_${SUB}_${SES}
work_dir2=/tmp/motion_correction_work2_${SUB}_${SES}


if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi  

if [ ! -d ${work_dir2} ]; then
	mkdir -p ${work_dir2}

fi
#sync data to which correction shall be applied
for n in ${RUNVAR[@]}; do for e in 1 2 3 4 5;
do s3cmd sync ${data_bucket_in}/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold.nii.gz  ${work_dir}/; 
done; done;
#synch pre-calculated motion regressors
s3cmd sync ${data_bucket_in2}/  ${work_dir2}/ --recursive; 

cd ${work_dir}
for n in ${RUNVAR[@]}; do for e in 1 2 3 4 5;
do applyxfm4D sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold.nii.gz \
sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold.nii.gz \
sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold_mc.nii.gz \
${work_dir2}/sub-${SUB}_ses-ME_task-rest_run-${n}_echo-1_boldMC/MotionMatrices -fourdigit; 
done; done; 


#remove bold runs from work_dir to omit douplicating data
for n in ${RUNVAR[@]}; do for e in 1 2 3 4 5;
do rm ${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold.nii.gz;
done; done;

s3cmd sync ${work_dir}/ ${data_bucket_out}/ --recursive
