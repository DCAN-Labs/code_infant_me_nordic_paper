#source code_metric_to_cifti.sh output_folder

wb_c=/path/to/my/workbench/bin_rh_linux64/wb_command


abs_path=$1


path_subj=$abs_path


path=$path_subj
path_out=$path/cifti_mni
###path_out=$path/cifti_native

mkdir $path_out

out=$path_out/surface_t2star.dscalar.nii
#left_metric=$path/surfs/Left_surface.func.gii
#right_metric=$path/surfs/Right_surface.func.gii


left_metric=$path/surfs_mni/Left_surface.func.gii
right_metric=$path/surfs_mni/Right_surface.func.gii

$wb_c -cifti-create-dense-scalar $out -left-metric $left_metric -right-metric $right_metric


