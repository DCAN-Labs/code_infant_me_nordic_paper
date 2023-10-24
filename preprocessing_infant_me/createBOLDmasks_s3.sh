#!/bin/bash -l

#SBATCH -J brain-mask
#SBATCH --ntasks=2
#SBATCH --tmp=100gb
#SBATCH --mem=10gb
#SBATCH -t 05:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/brain-mask.out
#SBATCH -e output_logs/brain-mask.err

SUB=${1}
SES=ME #bold mask is only created for ME, the same mask can be used for ME NORDIC
#RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13");
RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09");

data_bucket_in=s3://mybucket/sub-${SUB}/DCAN_pip_work/motion_corrected_echos
data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_work/bold_masks

work_dir=/tmp/bold_masks_work_${SUB}_${SES}

if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi  

#create subdirectories for different steps
mkdir ${work_dir}/masks
mkdir ${work_dir}/Tmean

#sync data to which correction shall be applied
for n in ${RUNVAR[@]}; 
do s3cmd sync ${data_bucket_in}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-1_bold_mc.nii.gz  ${work_dir}/Tmean/; 
done; 


module load fsl/5.0.10;

#step one Tmean
cd ${work_dir}/Tmean
for n in *;
do fslmaths ${n} -Tmean ../masks/${n::-7}_Tmean.nii.gz;  
done;

module load singularity;
#step two, mask
cd ${work_dir}/masks
for n in * ;  
do singularity exec -B ${work_dir}/masks:/wd /path/to/my/sdcflows/img/sdcflows_2.0.8.sif /bin/bash -c "python3 -c \"from sdcflows.utils.tools import brain_masker; brain_masker('/wd/${n}', '/wd/${n::-7}_mask.nii.gz', 5)\" " ; 
done; 

#sync content to out dir
s3cmd sync ${work_dir}/masks/ ${data_bucket_out}/ --recursive
