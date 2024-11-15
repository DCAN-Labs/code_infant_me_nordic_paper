#!/bin/bash -l

SUB=subject_ID
SES=ses_ID
RUN=run_number

module load afni
# step one, blur ME, SE and SENORDIC to same smoothness as MENORDIC
3dBlurToFWHM -FWHM 2.69 -automask -prefix sub-${SUB}_ses-${SES}_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -input sub-${SUB}_ses-${SES}_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz;
3dBlurToFWHM -FWHM 2.71 -automask -prefix sub-${SUB}_ses-${SES}_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -input sub-${SUB}_ses-${SES}_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz;
3dBlurToFWHM -FWHM 2.71 -automask -prefix sub-${SUB}_ses-${SES}_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -input sub-${SUB}_ses-${SES}_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz;

# step 2, calculate smoothenss to make sure that the same/a similar overall FWHM was reached
3dFWHMx -combine -detrend -automask -acf -input sub-${SUB}_ses-${SES}_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz > sub-BIO10001_ses-1_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_smoothed_to_MENORDIC_average_fwhm.txt;
3dFWHMx -combine -detrend -automask -acf -input sub-${SUB}_ses-${SES}_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz > sub-BIO10001_ses-1_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_smoothed_to_MENORDIC_average_fwhm.txt;
3dFWHMx -combine -detrend -automask -acf -input sub-${SUB}_ses-${SES}_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz > sub-BIO10001_ses-1_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_smoothed_to_MENORDIC_average_fwhm.txt;

# step 3: automask unsmoothed MENORDIC data or further TSNR calculation
3dAutomask -apply_prefix automask sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz;
3dAFNItoNIFTI automask+tlrc.HEAD;
mv automask.nii sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_automasked.nii;
gzip sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_automasked.nii;

# step 4: calculate tsnr by calculating mean and sd for each run using FSL
module load fsl

# MENORDIC
fslmaths ../sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_automasked.nii.gz -Tmean sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_mean_bold.nii.gz;
fslmaths ../sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_automasked.nii.gz -Tstd sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_std_bold.nii.gz;
fslmaths sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_mean_bold.nii.gz -div sub-BIO10001_ses-1_task-restMENORDICrmnoisevols_run-${RUN}_std_bold.nii.gz sub-${SUB}_ses-${SES}_task-restMENORDICrmnoisevols_run-${RUN}_tsnr_bold.nii.gz

# ME smoothed to MENORDIC
fslmaths ../sub-${SUB}_ses-${SES}_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tmean sub-${SUB}_ses-${SES}_task-restMEsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz;
fslmaths ../sub-${SUB}_ses-${SES}_task-restMErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tstd sub-${SUB}_ses-${SES}_task-restMEsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz;
fslmaths sub-${SUB}_ses-${SES}_task-restMEsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz -div sub-BIO10001_ses-1_task-restMEsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz sub-${SUB}_ses-${SES}_task-restMEsmoothedtoMENORDIC_run-${RUN}_tsnr_bold.nii.gz

# SE smoothed to MENORDIC
 fslmaths ../sub-${SUB}_ses-${SES}_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tmean sub-${SUB}_ses-${SES}_task-restSEsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz;
fslmaths ../sub-${SUB}_ses-${SES}_task-restSErmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tstd sub-${SUB}_ses-${SES}_task-restSEsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz;
fslmaths sub-${SUB}_ses-${SES}_task-restSEsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz -div sub-BIO10001_ses-1_task-restSEsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz sub-${SUB}_ses-${SES}_task-restSEsmoothedtoMENORDIC_run-${RUN}_tsnr_bold.nii.gz

#SENORDIC smoothed to MENORDIC
fslmaths ../sub-${SUB}_ses-${SES}_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tmean sub-${SUB}_ses-${SES}_task-restSENORDICsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz;
fslmaths ../sub-${SUB}_ses-${SES}_task-restSENORDICrmnoisevols_run-${RUN}_space-MNI152NLin6Asym_res-2_desc-preproc_bold_smoothed_to_MENORDIC.nii.gz -Tstd sub-${SUB}_ses-${SES}_task-restSENORDICsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz;
fslmaths sub-${SUB}_ses-${SES}_task-restSENORDICsmoothedtoMENORDIC_run-${RUN}_mean_bold.nii.gz -div sub-BIO10001_ses-1_task-restSENORDICsmoothedtoMENORDIC_run-${RUN}_std_bold.nii.gz sub-${SUB}_ses-${SES}_task-restSENORDICsmoothedtoMENORDIC_run-${RUN}_tsnr_bold.nii.gz

# step 5: sumarize results in overall mean
#number of available runs
run_num=12 
RVAR=$(seq -w 1 ${run_num}); #creates run number with 0 (01, 02, ...)
# 1. mean
for n in ${RVAR};
do for task in restMEsmoothedtoMENORDIC restSEsmoothedtoMENORDIC restSENORDICsmoothedtoMENORDIC restMENORDICrmnoisevols; 
do value=$(fslstats sub-${SUB}_ses-${SES}_task-${task}_run-${n}_tsnr_bold.nii.gz -m) 
echo "${task},${n},${value}" > mean_sub-${SUB}_ses-${SES}_run-${n}_task-${task}.csv
done; done

paste -d '\n' mean_sub-${SUB}_ses-${SES}_run-*.csv>mean_tsnr_sub-${SUB}_ses-${SES}.csv
rm mean_sub-${SUB}_ses-${SES}_run-*.csv
