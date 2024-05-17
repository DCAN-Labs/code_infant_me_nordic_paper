#!/bin/bash -l

#SBATCH -J cifti-con-shuffeld-runs
#SBATCH --ntasks=32
#SBATCH --tmp=240gb
#SBATCH --mem=240gb
#SBATCH -t 36:00:00
#SBATCH --mail-type=ALL
#SBATCH -p msismall,agsmall,ag2tb
#SBATCH -o output_logs/rel_dense_curve_%A_%a.out
#SBATCH -e output_logs/rel_dense_curve_%A_%a.err


SUB=${1} # subject ID
SES=${2} # session 
TASK=${3} #- determine if SE or ME and NORDIC or non-NORDIC
FD=${4} # FD for this dataset
NUM=${5} #number of permutations to be run (this permutation number)
MIN=${6} #maximum minutes for reliability curve - attention: MIN must be smaller than half of the data
DERIVATIVESDIR=${7}
BASEDIR=${8}
S_KERNEL=none 

#############################################################################################
#paths to matlab runtime and wb_command
MRE_DIR='/path/to/myMATLAB_Runtime_R2016b/v91/'

WB_CMD='/path/to/my/workbench/1.4.2/workbench/bin_rh_linux64/wb_command'

dtseries_in=${DERIVATIVESDIR}/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-${TASK}_space-fsLR_den-91k_desc-interpolated_bold.dtseries.nii
motion_file=${DERIVATIVESDIR}/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-${TASK}_desc-dcan_qc.hdf5

#############################################################


#start loop for permutations


work_dir=/tmp/${SUB}/${SES}/${TASK}/${NUM}


pwd; hostname; date

if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi

module load workbench; 
module load matlab; 

# transform XCP-D motion file to DCAN motion file
matlab -r "addpath('/path/to/my/utilities/xcpd2dcanmotion/'); xcpd2dcanmotion('${motion_file}', '${work_dir}')";

#grep TR from dtseries
TR=$(wb_command -file-information ${dtseries_in} -only-step-interval) 

#shuffle data (by run) and create a mask for each half of the dataset (ground truth is secod half of data for now)
matlab -r "addpath('/path/to/my/code'); sessions_shuffled_runs_xcpd_dtseries('${SUB}', '${SES}', ${FD}, '${TASK}', ${TR}, ${MIN}, ${NUM}, '${work_dir}', '${dtseries_in}')";
## Bene changed ${x} to ${NUM}
#run cifti-con for ground truth part of data
python3 /home/faird/shared/code/internal/utilities/cifti_connectivity/cifti_conn_wrapper.py \
--motion ${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_desc-filtered_motion_mask.mat \
--mre-dir ${MRE_DIR} \
--additional-mask ${work_dir}/masks/sub-${SUB}_ses-${SES}_mask_groundtruth_${MIN}min.txt \
--wb-command ${WB_CMD} --fd-threshold ${FD} --remove-outliers \
${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii \
${TR} ${work_dir}/groundtruth/ matrix;

#run loop to calculate dconn for each of these minutes
#set MINVAR as for loop does not accept {1..${MIN}
MINVAR=$(seq 5 5 ${MIN}); 
#MINVAR=25
for n in ${MINVAR}; 
do python3 /home/faird/shared/code/internal/utilities/cifti_connectivity/cifti_conn_wrapper.py \
--motion ${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_desc-filtered_motion_mask.mat \
--mre-dir ${MRE_DIR} \
--additional-mask ${work_dir}/masks/sub-${SUB}_ses-${SES}_mask_half1_${n}min.txt \
--wb-command ${WB_CMD} --fd-threshold ${FD} --remove-outliers \
${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii \
${TR} ${work_dir}/half1/${n}min/ matrix;



D_ONE=${work_dir}/half1/${n}min/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii_all_frames_at_FD_${FD}.dconn.nii

D_TWO=${work_dir}/groundtruth/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii_all_frames_at_FD_${FD}.dconn.nii

OUTDIR=${work_dir}/rel_val/
OUTNAME=rel_val_sub-${SUB}_ses-${SES}_smoothing${S_KERNEL}_${n}min_perm${NUM}

WB_C='/path/to/my/workbench/1.4.2/workbench/bin_rh_linux64/wb_command'
CIFTI_C='/path/to/my/cifti-matlab' 
GIFTI_C='/path/to/my/gifti/'

mkdir ${work_dir}/rel_val/; 
#/home/miran045/shared/projects/WashU_Nordic/PrecBabyData/code/whole_brain_map/DCAN_pip
matlab -r "addpath('/path/to/my/code/'); CalculateDconntoDconnCorrelationIndividualSeedsNoDistMat('DconnShort','${D_ONE}','DconnGroundTruth','${D_TWO}', 'OutputDirectory','${OUTDIR}', 'OutputName','${OUTNAME}', 'wb_command','${WB_C}', 'CIFTI_path','${CIFI_C}', 'GIFTI_path','${GIFI_C}')"

#see output dir above
mkdir -p ${BASEDIR}/sub-${SUB}/task-${TASK}/smoothing${S_KERNEL}/${n}min

cp -R ${work_dir}/rel_val/rel_val_sub-${SUB}_ses-${SES}_smoothing${S_KERNEL}_${n}min_perm${NUM}.txt ${BASEDIR}/sub-${SUB}/task-${TASK}/smoothing${S_KERNEL}/${n}min;
rm -R ${work_dir}/half1/${n}min;

done;
