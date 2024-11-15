#!/bin/bash -l
# RMSE maps are created by Tedana version 24.0 (https://github.com/ME-ICA/tedana/tree/df583477030310cc31ef6e654b99a4d0eb21af73)
# output name is "desc-rmse_statmap.nii.gz"

# this script is used to normalize RMSE values
SUB=$1
SES=$2
TASK=$3
RUN=$4
WD=$5
OUT=$6


# to normalize RMSE maps, we divided them by the mean BOLD signal across all echoes for each run using FSL
module load fsl

mkdir -p ${OUT}
cd ${OUT}

# step one, average timeseries to a single frame
for n in 1 2 3 4 5; do fslmaths ${WD}/${RUN}_${SES}_e${n}_bold.nii.gz -Tmean ${WD}/${RUN}_${SES}_e${n}_bold_tmean.nii.gz; done


#step 2, merge echoes and average echoes to a mean image
fslmerge -t sub-${SUB}_ses_${SES}_task_${TASK}_run_${RUN}_combechoes_tmean.nii.gz ${WD}/${RUN}_${SES}_e1_bold_tmean.nii.gz ${WD}/${RUN}_${SES}_e2_bold_tmean.nii.gz ${WD}/${RUN}_${SES}_e3_bold_tmean.nii.gz ${WD}/${RUN}_${SES}_e4_bold_tmean.nii.gz ${WD}/${RUN}_${SES}_e5_bold_tmean.nii.gz

fslmaths sub-${SUB}_ses_${SES}_task_${TASK}_run_${RUN}_combechoes_tmean.nii.gz -Tmean sub-${SUB}_ses_${SES}_task_${TASK}_run_${RUN}_avgecho_tmean.nii.gz

#step 3 divide RMSE by mean image for normalized RMSE
fslmaths desc-rmse_statmap.nii.gz -div sub-${SUB}_ses_${SES}_task_${TASK}_run_${RUN}_avgecho_tmean.nii.gz desc-rmse_statmap_normalized.nii.gz
