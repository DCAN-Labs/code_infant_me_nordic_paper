#!/bin/bash -l

#SBATCH -J tedana
#SBATCH --ntasks=8
#SBATCH --tmp=480gb
#SBATCH --mem=480gb
#SBATCH -t 08:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/tedana.out
#SBATCH -e output_logs/tedana.err

SUB=${1}
SES=${2} 
#RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13");
RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09");


data_bucket_in=s3://mybucket/sub-${SUB}/DCAN_pip_work/motion_corrected_echos
data_bucket_in2=s3://mybucket/sub-${SUB}/DCAN_pip_work/bold_masks
data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_work/Tedana_outputs/ses-${SES}

work_dir=/tmp/tedana_work_${SUB}_${SES}

if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi  

work_dir2=/tmp/tedana_work_masks_${SUB}_${SES}

if [ ! -d ${work_dir2} ]; then
	mkdir -p ${work_dir2}

fi  

#sync input data for Tedana
for n in ${RUNVAR[@]}; do for e in 1 2 3 4 5;
do s3cmd sync ${data_bucket_in}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold_mc.nii.gz  ${work_dir}/; 
done; done;

#synch pre-calculated motion masks
s3cmd sync ${data_bucket_in2}/  ${work_dir2}/; 


module load python;
source activate tedana;

cd ${work_dir}

for n in ${RUNVAR[@]}; 
do tedana -d ${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-1_bold_mc.nii.gz \
${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-2_bold_mc.nii.gz \
${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-3_bold_mc.nii.gz \
${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-4_bold_mc.nii.gz \
${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-5_bold_mc.nii.gz \
-e 14.2 38.93 63.66 88.39 113.12 -\
-mask ${work_dir2}/sub-${SUB}_ses-ME_task-rest_run-${n}_echo-1_bold_mc_Tmean_mask.nii.gz \
--out-dir ${work_dir}/run-${n}_mc_tedana \
--prefix sub-${SUB}_ses-${SES}_task-rest_run-${n} --n-threads 4;
done;

#remove input data to avoid douplication
for n in ${RUNVAR[@]}; do for e in 1 2 3 4 5;
do rm ${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-${e}_bold_mc.nii.gz;
done; done;

#sync outputs to s3
s3cmd sync ${work_dir}/ ${data_bucket_out}/ --recursive
