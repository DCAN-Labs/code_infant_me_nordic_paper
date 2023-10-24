
Calculating and plotting TSNR for Nordic and Non-Nordic Conditions

We used (uncentered) dtseries for each condition. 
Then, we used CIFTITSNR.m to calculate mean and sd for each run. 
This outputs dscalars with meand and sd tsnr for each run.

CIFTITSNR uses the packages 'cifti-matlab' and gifti' and Connectome Workbench commands in Matlab 2019a.

We averaged runs with >90% of motion free data to get an average tsnr value.

To create an average dscalar we used Workbench Command -cifti-average
Example: wb_command -cifti-average myaverage.dscalar.nii -cifti myrun1.dscalar.nii -cifti myrun2.dscalar.nii -cifti

To calculate the average tsnr across the brain we used Workbench Command -cifti-stats
Example -cifti-stats myaverage.dscalar.nii -reduce MEAN


https://www.mathworks.com/matlabcentral/fileexchange/56783-washington-university-cifti-matlab
https://github.com/gllmflndn/gifti
https://www.humanconnectome.org/software/workbench-command





