#!/bin/bash -l

#SBATCH -J motion_regressors
#SBATCH --ntasks=2
#SBATCH --tmp=10gb
#SBATCH --mem=60gb
#SBATCH -t 05:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall
#SBATCH -o output_logs/motion_regressors.out
#SBATCH -e output_logs/motion_regressors.err

singularity=`which singularity`

SUB=${1}
SES=ME
#RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13");
RUNVAR=("01" "02" "03" "04" "05" "06" "07" "08" "09");

data_bucket_in=s3://mybucket/sub-${SUB}/BIDS_input_folders/Nibabies_input_${SUB}_${SES}
data_bucket_out=s3://mybucket/sub-${SUB}/DCAN_pip_work/motion_regressors_echo-1

work_dir=/tmp/motion_regressors_work_${SUB}_${SES}


if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi  

#sync from s3: nibabies BIDS input folder

for n in ${RUNVAR[@]}; 
do s3cmd sync ${data_bucket_in}/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-1_bold.nii.gz  ${work_dir}/; 
done;


module load singularity;
cd ${work_dir}
for n in *; 
do mkdir -p ${n::-7}MC; cp ${n} ${n::-7}MC; 
singularity exec --cleanenv -B ~/Documents/license.txt:/opt/freesurfer/license.txt -B ${work_dir}/${n::-7}MC:/wd /path/to/my/abcd-hcp-pipeline_dbp-hotfix-03172022.sif /bin/bash -c "/app/SetupEnv.sh && export HCPPIPEDIR_Global=/opt/pipeline/global/scripts && FSLOUTPUTTYPE=NIFTI_GZ && NameOffMRI=${n::-7} && source /opt/pipeline/global/scripts/log.shlib && source /opt/pipeline/global/scripts/opts.shlib && export FSLOUTPUTTYPE && fslroi /wd/${n::-7}.nii.gz /wd/${n::-7}_scout.nii.gz 0 1 && mkdir -p /wd/MotionCorrection /wd/MotionMatrices && /opt/pipeline/fMRIVolume/scripts/MotionCorrection.sh /wd/MotionCorrection /wd/${n::-7} /wd/${n::-7}_scout /wd/${n::-7}_mc /wd/Movement_Regressors /wd/MotionMatrices MAT_ MCFLIRT"; 
done

#remove bold runs from work_dir to omit douplicating data
for n in ${RUNVAR[@]}; 
do rm ${work_dir}/sub-${SUB}_ses-${SES}_task-rest_run-${n}_echo-1_bold.nii.gz;
done;

s3cmd sync ${work_dir}/ ${data_bucket_out}/ --recursive
