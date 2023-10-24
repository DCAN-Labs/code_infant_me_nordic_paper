The T2* maps presented in this paper were outputted by 'Tedana' in volume space and transformed from volume to surface space, using the derivatives from the DCAN infant pipeline/fMRIprep and the code shared in this repo. 
Before transformation to surface space, maps were transformed to 2mm MNI space.

Infant data: fsl 'applywarp'
Example: 
applywarp --rel --interp=< interpolation - here: spline> --in=<input image- here: T2* map> --warp=<reference warp - here:  ses-[]_task-rest_run-[]2standard.nii.gz> --ref=<reference image - here: T1w_restore.2.nii.gz> --out=<output filename>

Adult data: ants 'antsApplyTransforms'
Example: antsApplyTransforms -i <input image - here T2star map> -r <reference image - here: T1 native space>  -t <transform - here: from scanner to T1 mode for each run> -n <interpolation - here: BSpline> -o <output filename>

Values for echo weighting were calculated with the Matlab script shared here.
Additional packages used in Matlab are:'cifti-matlab' and gifti' and Connectome Workbench in Matlab 2019a.

https://www.mathworks.com/matlabcentral/fileexchange/56783-washington-university-cifti-matlab
https://github.com/gllmflndn/gifti
https://www.humanconnectome.org/software/workbench-command
