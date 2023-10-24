#!/bin/bash -l

SUB=${1}
SES=${2}
RUN=${3}

subjectID=sub-${SUB}

output_folder=/path/to/my/output_folder/${SUB}/surfaces_run-${RUN}
mkdir -p ${output_folder}
path_mri_processed_data=/path/to/my/preprocessed_data
t2star_map=/path/to/my/${SUB}/sub-${SUB}_ses-${SES}_run-${RUN}_T2starMNI2mm.nii.gz

./from_vol_to_metric_in_mni.sh ${path_mri_processed_data} ${SUB} ${t2star_map} ${output_folder}
./code_metric_to_cifti_in_mni.sh ${output_folder}

