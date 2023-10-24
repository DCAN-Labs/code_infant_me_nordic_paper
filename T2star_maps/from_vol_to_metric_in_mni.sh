#input

#source from_vol_to_metric_in_mni.sh path_mri_processed_data subjectID output_folder

path_mri_processed_data=$1
subj=$2
vol=$3
output_folder=$4


path_to_native_surface=$path_mri_processed_data/MNINonLinear/fsaverage_LR32k

base_surf_left=$subj.L.midthickness.32k_fs_LR.surf.gii
base_surf_right=$subj.R.midthickness.32k_fs_LR.surf.gii

base_white_left=$subj.L.white.32k_fs_LR.surf.gii
base_pial_left=$subj.L.pial.32k_fs_LR.surf.gii

base_white_right=$subj.R.white.32k_fs_LR.surf.gii
base_pial_right=$subj.R.pial.32k_fs_LR.surf.gii


path_to_vol=$output_folder


out=$path_to_vol/surfs_mni
mkdir $out
out_left=$out/Left_surface.func.gii
out_right=$out/Right_surface.func.gii

module load workbench

wb_command -volume-to-surface-mapping $vol\
 $path_to_native_surface/$base_surf_left $out_left\
 -ribbon-constrained\
 $path_to_native_surface/$base_white_left\
 $path_to_native_surface/$base_pial_left


wb_command -volume-to-surface-mapping $vol\
 $path_to_native_surface/$base_surf_right $out_right\
 -ribbon-constrained\
 $path_to_native_surface/$base_white_right\
 $path_to_native_surface/$base_pial_right

