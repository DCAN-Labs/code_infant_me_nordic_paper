#!/bin/bash -l

#SBATCH -J abcd-xcp
#SBATCH -c 32
#SBATCH --mem=80G
#SBATCH -t 8:00:00
#SBATCH --mail-type=ALL

#SBATCH -p msismall
#SBATCH -o output_logs/xcp_full_%A_%a.out
#SBATCH -e output_logs/xcp_full_%A_%a.err

SUB=${1}
SES=combined

singularity=`which singularity`

work_dir=/mypath/sub-${SUB}

if [ ! -d ${work_dir} ]; then
  mkdir -p ${work_dir}

fi  

out_dir=/mypath/sub-${SUB}

if [ ! -d ${out_dir} ]; then
  mkdir -p ${out_dir}

fi

env -i ${singularity} run --cleanenv \
-B ~/Documents/license.txt:/opt/freesurfer/license.txt \
-B /scratch.global/mypath/out_dir/fmri_prep_${SUB}_${SES}/:/data:ro \
-B ${out_dir}:/out \
-B ${work_dir}:/work \
/path/to/my/xcp_d_0.6.1.sif \
/data /out participant -r 45 -f 0.3 --cifti -m --participant-label ${SUB} --despike --lower-bpf 0.009 --band-stop-min 15 --band-stop-max 25 --motion-filter-type notch --omp-nthreads 3 --nthreads 64 --warp-surfaces-native2std --resource-monitor --dcan-qc -vv --input-type fmriprep \
-w /work
