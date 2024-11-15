
% step 1 read in data
clear all
addpath(genpath('/path/to/my/cifti-matlab'));
addpath(genpath('/path/to/my/gifti/'));
wb_command='/path/to/my/workbench/1.4.2/workbench/bin_rh_linux64/wb_command';

%%
dscalar_template='/path/to/my/91282_Greyordinates.dscalar.nii'; % example for 91k dscalar format

run_num=['01'; '02'; '03'; '04'; '05'; '07'; '08'; '09'; '10']; % adapt specifically for each participant

% load dtseries for each run to create an average and identify regions wih high signal dropout. 
for n=1:9;
    RUN=run_num(n,:);
    cifti_file=['/path/to/my/sub-_ses-_task-restSErmnoisevols_run-' RUN '_space-fsLR_den-91k_bold.dtseries.nii'];
    %load cifti file
    cifti_tseries = ciftiopen(cifti_file,wb_command);
    dtseries = cifti_tseries.cdata;
    clear cifti_tseries
    avg_dtseries=nanmean(dtseries,2);
    all_dtseries(:,n)=avg_dtseries;
end

run_avg_dtseries=nanmean(all_dtseries,2);

tmp_dscalar=ciftiopen(dscalar_template,wb_command);
outfile_base=extractBefore(cifti_file,'run'); %this si used to define filepath and file name for saving data
last_surf_vertex=59412;
%%
% For this example, the search is restricted to surface vertices
avg_dtseries_surf=run_avg_dtseries(1:last_surf_vertex,:);

%create average of this across all runs
%
low_signal_threshold=prctile(avg_dtseries_surf, 5);
low_signal_areas=avg_dtseries_surf<low_signal_threshold;

%plot avg_dtseries
tmp_dscalar.cdata=run_avg_dtseries;
ciftisave(tmp_dscalar,[outfile_base 'avg_dtseries.dscalar.nii'],wb_command);

% plot low signal areas only and see, if they  make a good mask
mask=zeros(size(run_avg_dtseries));
mask(low_signal_areas)=1;
mask=logical(mask);

masked_dtseries=nan(size(run_avg_dtseries));
masked_dtseries(mask)=run_avg_dtseries(mask);

tmp_dscalar.cdata=masked_dtseries;
ciftisave(tmp_dscalar,[outfile_base 'masked_dtseries.dscalar.nii'],wb_command);
mean_signal_in_mask=nanmean(masked_dtseries);

tmp_dscalar.cdata=mask;
ciftisave(tmp_dscalar,[outfile_base 'masked_dtseries_binary.dscalar.nii'],wb_command);

%% load tSNR files
cifti_file='/path/to/my/sub-_ses-_task-restSErmnoisevols_run-00_space-fsLR_den-91k_boldtsnr.dscalar.nii';
cifti_tseries = ciftiopen(cifti_file,wb_command);
tSNR_SE = cifti_tseries.cdata;

cifti_file='/path/to/my/sub-_ses-_task-restSENORDICrmnoisevols_run-00_space-fsLR_den-91k_boldtsnr.dscalar.nii';
cifti_tseries = ciftiopen(cifti_file,wb_command);
tSNR_SENORDIC = cifti_tseries.cdata;

cifti_file='/path/to/my/sub-_ses-_task-restMErmnoisevols_run-00_space-fsLR_den-91k_boldtsnr.dscalar.nii';
cifti_tseries = ciftiopen(cifti_file,wb_command);
tSNR_ME = cifti_tseries.cdata;

cifti_file='/path/to/my/sub-_ses-_task-restMENORDICrmnoisevols_run-00_space-fsLR_den-91k_boldtsnr.dscalar.nii';
cifti_tseries = ciftiopen(cifti_file,wb_command);
tSNR_MENORDIC = cifti_tseries.cdata;

%calculate difference between SE and SENORDIC
masked_tSNR_SE=nan(size(tSNR_SE));
masked_tSNR_SE(mask)=tSNR_SE(mask);

masked_tSNR_SENORDIC=nan(size(tSNR_SENORDIC));
masked_tSNR_SENORDIC(mask)=tSNR_SENORDIC(mask);

diff_tSNR_SE=masked_tSNR_SENORDIC-masked_tSNR_SE;

outfile_base=extractBefore(cifti_file,'task');
tmp_dscalar.cdata=masked_tSNR_SE;
ciftisave(tmp_dscalar,[outfile_base 'tSNR_SE_masked_roi.dscalar.nii'],wb_command);
tmp_dscalar.cdata=masked_tSNR_SENORDIC;
ciftisave(tmp_dscalar,[outfile_base 'tSNR_SENORDIC_masked_roi.dscalar.nii'],wb_command);

tmp_dscalar.cdata=diff_tSNR_SE;
ciftisave(tmp_dscalar,[outfile_base 'difference_tSNR_SE_SENORDIC_masked_roi.dscalar.nii'],wb_command);
% percent difference across brain
pct_diff_tSNR_SENORDIC=((tSNR_SENORDIC.*100)./tSNR_SE)-100;
tmp_dscalar.cdata=pct_diff_tSNR_SENORDIC;
ciftisave(tmp_dscalar,[outfile_base 'percent_diff_tSNR_SE_SENORDIC.dscalar.nii'],wb_command);


%calculate difference between ME and MENORDIC
masked_tSNR_ME=nan(size(tSNR_ME));
masked_tSNR_ME(mask)=tSNR_ME(mask);

masked_tSNR_MENORDIC=nan(size(tSNR_MENORDIC));
masked_tSNR_MENORDIC(mask)=tSNR_MENORDIC(mask);

diff_tSNR_ME=masked_tSNR_MENORDIC-masked_tSNR_ME;

outfile_base=extractBefore(cifti_file,'task');

tmp_dscalar.cdata=masked_tSNR_ME;
ciftisave(tmp_dscalar,[outfile_base 'tSNR_ME_masked_roi.dscalar.nii'],wb_command);
tmp_dscalar.cdata=masked_tSNR_MENORDIC;
ciftisave(tmp_dscalar,[outfile_base 'tSNR_MENORDIC_masked_roi.dscalar.nii'],wb_command);
tmp_dscalar.cdata=diff_tSNR_ME;
ciftisave(tmp_dscalar,[outfile_base 'difference_tSNR_ME_MENORDIC_masked_roi.dscalar.nii'],wb_command);

pct_diff_tSNR_MENORDIC=((tSNR_MENORDIC.*100)./tSNR_ME)-100;
tmp_dscalar.cdata=pct_diff_tSNR_MENORDIC;
ciftisave(tmp_dscalar,[outfile_base 'percent_diff_tSNR_ME_MENORDIC.dscalar.nii'],wb_command);

%% show percent improvement
avg_masked_tSNR_SE=nanmean(masked_tSNR_SE)
avg_masked_tSNR_SENORDIC=nanmean(masked_tSNR_SENORDIC)
percent_change_SE=((avg_masked_tSNR_SENORDIC*100)/avg_masked_tSNR_SE)-100

avg_masked_tSNR_ME=nanmean(masked_tSNR_ME)
avg_masked_tSNR_MENORDIC=nanmean(masked_tSNR_MENORDIC)
percent_change_ME=((avg_masked_tSNR_MENORDIC*100)/avg_masked_tSNR_ME)-100

%% compare to rest of brain
nonmasked_tSNR_SE=nan(size(tSNR_SE));
nonmasked_tSNR_SE(~mask)=tSNR_SE(~mask);

nonmasked_tSNR_SENORDIC=nan(size(tSNR_SENORDIC));
nonmasked_tSNR_SENORDIC(~mask)=tSNR_SENORDIC(~mask);

nonmasked_tSNR_ME=nan(size(tSNR_ME));
nonmasked_tSNR_ME(~mask)=tSNR_ME(~mask);

nonmasked_tSNR_MENORDIC=nan(size(tSNR_MENORDIC));
nonmasked_tSNR_MENORDIC(~mask)=tSNR_MENORDIC(~mask);

avg_nonmasked_tSNR_SE=nanmean(nonmasked_tSNR_SE)
avg_nonmasked_tSNR_SENORDIC=nanmean(nonmasked_tSNR_SENORDIC)
percent_change_SE_none=((avg_nonmasked_tSNR_SENORDIC*100)/avg_nonmasked_tSNR_SE)-100

avg_nonmasked_tSNR_ME=nanmean(nonmasked_tSNR_ME)
avg_nonmasked_tSNR_MENORDIC=nanmean(nonmasked_tSNR_MENORDIC)
percent_change_ME_none=((avg_nonmasked_tSNR_MENORDIC*100)/avg_nonmasked_tSNR_ME)-100
%% save results
condition_var={'SE'; 'SENORDIC'; 'ME'; 'MENORDIC'};
avg_tsnr_mask=[avg_masked_tSNR_SE; avg_masked_tSNR_SENORDIC; avg_masked_tSNR_ME; avg_masked_tSNR_MENORDIC];
avg_tsnr_nonmask=[avg_nonmasked_tSNR_SE; avg_nonmasked_tSNR_SENORDIC; avg_nonmasked_tSNR_ME; avg_nonmasked_tSNR_MENORDIC];
mean_signal_mask=[mean_signal_in_mask; NaN; mean_signal_in_mask_ME; NaN];
results_tab=table(condition_var, avg_tsnr_mask, avg_tsnr_nonmask, mean_signal_mask);

writetable(results_tab, [outfile_base 'results_tSNR_mask.csv'])
