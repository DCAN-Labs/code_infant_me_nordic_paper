Slurm batch scripts for data processing using MSI computing resources.

Dependencies:

The abcd-hcp pipeline v0.1.3 Singularity container (https://hub.docker.com/repository/docker/dcanumn/abcd-hcp-pipeline) is used for head motion estimation. 
FSL 5.0.10 used to apply head motion correction prior to running tedana (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki).
An external brain mask for Tedana is calculated using sdcflows 2.0.8 (https://github.com/nipreps/sdcflows).
We used tedana 0.0.11rc1+9.g746d53d for multi-echo optimal combination (tedana.readthedocs.io) installed in a miniconda3 environment.
DCAN infant-abcd-bids-pipeline v0.0.21 Singularity container for data preprocessing (https://hub.docker.com/repository/docker/dcanumn/infant-abcd-bids-pipeline)

We ran the DCAN infant-abcd-bids-pipeline in three stages: 
1. to obtain preprocessed anatomical images for generating segmentations with BIBSNet (https://hub.docker.com/r/dcanumn/bibsnet)
2. to complete preprocessing with the external segmentations
3. to finalize processing with the motion regressors calculated from the first echo. For this step we replaced MNINonLinear/Results/<run>/Motion_Regressors.txt (and Motion_Regressors_dt.txt) with the pre-computed motion values and rerun the pipeline from DCANBOLDProcessing stage.

Other dependencies: 

Apptainer (1.2.2-1.el7) 
Slurm (22.05.9)  





