#!/bin/bash -l

#SBATCH -J cifti-con-shuffeld-runs
#SBATCH --ntasks=12
#SBATCH --tmp=240gb
#SBATCH --mem=240gb
#SBATCH -t 36:00:00
#SBATCH --mail-type=ALL
#SBATCH -p ag2tb
#SBATCH -o output_logs/cifti-con-shuffeld-runs.out
#SBATCH -e output_logs/cifti-con-shuffeld-runs.err

SUB=${1} # subject ID
SES=${2} # session ID
TASK=${3} # task (e.g. auditory, rest)
FD=${4} # FD for this dataset
MAXMIN=${5} # how many minutes does groundtruth have and up to how many minutes masks for half 1 shall be created?
S_KERNEL=_none # e.g. 2.55
PERM=${6} # number of permutation (which random order of runs shall be used?)


MRE_DIR='/path/to/my/MATLAB_MCR/v91/'
WB_CMD='/path/to/my/workbench/1.4.2/workbench/bin_rh_linux64/wb_command'

#############################################################
#hardcoding warning:
INFOLDER=/path/to/my/input_dir

output_dir=/path/to/my/output_dir
#####################################################################

work_dir=/tmp/${SUB}/${SES}/${S_KERNEL}/${PERM}

if [ ! -d ${work_dir} ]; then
	mkdir -p ${work_dir}

fi

module load workbench/1.4.2; 
module load matlab; 

cd ${work_dir};

#grep TR from dtseries
TR=$(wb_command -file-information ${INFOLDER}/sub-${SUB}/ses-${SES}/func/sub-${SUB}_ses-${SES}_task-${TASK}_bold_desc-filtered_timeseries.dtseries.nii -only-step-interval) 

cd ${work_dir};
# create shuffled dtseries and masks for different amount of minutes
matlab -r "addpath('/path/to/my/code'); sessions_shuffled_runs_DCAN('${SUB}', '${SES}', ${FD}, '${TASK}', ${TR}, ${MAXMIN}, ${PERM}, '${INFOLDER}')"


#run cifti-con for ground truth part of data
python3 /path/to/my/cifti_connectivity/cifti_conn_wrapper.py \
--motion ${work_dir}/*.mat \
--mre-dir ${MRE_DIR} \
--additional-mask ${work_dir}/masks/sub-${SUB}_ses-${SES}_mask_groundtruth_${MAXMIN}min.txt \
--wb-command ${WB_CMD} --fd-threshold ${FD} \
${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii \
${TR} ${work_dir}/groundtruth/ matrix;


#dconn for half one for Xmin of data 
MINVAR=$(seq 5 5 ${MAXMIN});

for MIN in ${MINVAR}; 
do python3 /path/to/my/cifti_connectivity/cifti_conn_wrapper.py \
--motion ${work_dir}/*.mat \
--mre-dir ${MRE_DIR} \
--additional-mask ${work_dir}/masks/sub-${SUB}_ses-${SES}_mask_half1_${MIN}min.txt \
--wb-command ${WB_CMD} --fd-threshold ${FD} \
${work_dir}/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii \
${TR} ${work_dir}/half1/${MIN}min/ matrix;


D_ONE=${work_dir}/half1/${MIN}min/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii_all_frames_at_FD_${FD}.dconn.nii
D_TWO=${work_dir}/groundtruth/sub-${SUB}_ses-${SES}_task-${TASK}_bold_shuffled_timeseries.dtseries.nii_all_frames_at_FD_${FD}.dconn.nii

OUTDIR=${work_dir}/rel_val/
OUTNAME=rel_val_sub-${SUB}_ses-${SES}_smoothing${S_KERNEL}_${MIN}min_perm${PERM}

CIFTI_C='/path/to/my/cifti-matlab' 
GIFTI_C='path/to/my/gifti/'

mkdir ${work_dir}/rel_val/; 
matlab -r "addpath('/home/miran045/shared/projects/WashU_Nordic/PrecBabyData/code/whole_brain_map/DCAN_pip/'); CalculateDconntoDconnCorrelationIndividualSeedsNoDistMat('DconnShort','${D_ONE}','DconnGroundTruth','${D_TWO}', 'OutputDirectory','${OUTDIR}', 'OutputName','${OUTNAME}', 'wb_command','${WB_CMD}', 'CIFTI_path','${CIFI_C}', 'GIFTI_path','${GIFI_C}')"

#see output dir above
mkdir -p ${output_dir}/sub-${SUB}/ses-${SES}/smoothing${S_KERNEL}/${MIN}min

cp -R ${work_dir}/rel_val/rel_val_sub-${SUB}_ses-${SES}_smoothing${S_KERNEL}_${MIN}min_perm${PERM}.txt ${output_dir}/sub-${SUB}/ses-${SES}/smoothing${S_KERNEL}/${MIN}min;
rm -R ${work_dir}/half1/${MIN}min;
done





