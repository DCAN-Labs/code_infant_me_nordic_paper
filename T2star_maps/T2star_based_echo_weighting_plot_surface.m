
% step 1 read in data
clear all
addpath(genpath('/path/to/my/cifti-matlab'));
addpath(genpath('/path/to/my/gifti/'));
wb_command='/path/to/my/workbench/bin_rh_linux64/wb_command';

cd('/path/to/my/input_dir');

SUB=''; % select subject of interest (PB04, PB04, PB05, adult)
SES=''; % select session (ME or MENORDIC)

%% get rid of medial wall
example_file_R = gifti('tpl-fsLR_hemi-R_den-32k_desc-nomedialwall_dparc.label.gii');
data_array_R=example_file_R.cdata;
example_file_L = gifti('tpl-fsLR_hemi-L_den-32k_desc-nomedialwall_dparc.label.gii');
data_array_L=example_file_R.cdata;
%% read in data (loop over good runs and average) - runs with over 90% motion free data
%run_num=['01'; '02'; '03'; '04'; '05'; '06'; '07'; '08'; '09'; '10'; '11'; '12'; '13'; '14']; % adult
%run_num=['01'; '02';'06'; '07'; '08']; % PB04
%run_num=['04'; '08'; '09']; % PB05
run_num=['01'; '02'; '05'; '06'; '08'; '09'; '10'; '13'; '14'; '15'; '19'; '20']; % PB01
for n=1:size(run_num,1)
    sub_struct = cifti_read(['sub-' SUB '/ses-' SES '/surfaces_run-' run_num(n,:) '/path/to/my/surface_t2star.dscalar.nii']);
    
    sub1=sub_struct.cdata;
    sub1(~logical([data_array_L;data_array_R]))=NaN;
    sub_all(:,n)=sub1;
end
sub=mean(sub_all,2);
%% Formula for weighting
TE1=14.2;
TE2=38.93;
TE3=63.66;
TE4=88.39;
TE5=113.12;

%% for surface

sub_ms=sub.*1000;

%%%%%%%%%%%%%%%% TE1
for i=1:size(sub,1)
    W1(i,1)=TE1*(exp(-TE1/sub_ms(i,1)));
end

%%%%%%%%%%%%%%%% TE2
for i=1:size(sub,1)
    W2(i,1)=TE2*(exp(-TE2/sub_ms(i,1)));
end

%%%%%%%%%%%%%%%% TE2
for i=1:size(sub,1)
    W3(i,1)=TE3*(exp(-TE3/sub_ms(i,1)));
end

%%%%%%%%%%%%%%%% TE4
for i=1:size(sub,1)
    W4(i,1)=TE4*(exp(-TE4/sub_ms(i,1)));
end

%%%%%%%%%%%%%%%% TE5
for i=1:size(sub,1)
    W5(i,1)=TE5*(exp(-TE5/sub_ms(i,1)));
end
%% normalize weights
sum_weights=W1+W2+W3+W4+W5;

W1norm=W1./sum_weights;
W2norm=W2./sum_weights;
W3norm=W3./sum_weights;
W4norm=W4./sum_weights;
W5norm=W5./sum_weights;
%% calculate stats
% combine data to facilitate calculation
table_t2_echos=[sub_ms,W1norm,W2norm,W3norm,W4norm,W5norm];
%stats
for i=1:6
    stats(1,i)=nanmean(table_t2_echos(:,i)); %mean
    stats(2,i)=nanstd(table_t2_echos(:,i)); %standard deviation
    stats(3,i)=prctile(table_t2_echos(:,i),5); %5th percentile
    stats(4,i)=prctile(table_t2_echos(:,i),95); %95th percentile

end
%echo weighting
%% write files
ciftiW1=sub_struct;
ciftiW1.cdata=W1norm;
cifti_write(ciftiW1, ['sub-' SUB '/ses-' SES '/sub-' SUB '_ses-' SES '_task-rest_run-average_weighting_TE1.dscalar.nii']);

ciftiW2=sub_struct;
ciftiW2.cdata=W2norm;
cifti_write(ciftiW2, ['sub-' SUB '/ses-' SES '/sub-' SUB '_ses-' SES '_task-rest_run-average_weighting_TE2.dscalar.nii']);

ciftiW3=sub_struct;
ciftiW3.cdata=W3norm;
cifti_write(ciftiW3, ['sub-' SUB '/ses-' SES '/sub-' SUB '_ses-' SES '_task-rest_run-average_weighting_TE3.dscalar.nii']);

ciftiW4=sub_struct;
ciftiW4.cdata=W4norm;
cifti_write(ciftiW4, ['sub-' SUB '/ses-' SES '/sub-' SUB '_ses-' SES '_task-rest_run-average_weighting_TE4.dscalar.nii']);

ciftiW5=sub_struct;
ciftiW5.cdata=W5norm;
cifti_write(ciftiW5, ['sub-' SUB '/ses-' SES '/sub-' SUB '_ses-' SES '_task-rest_run-average_weighting_TE5.dscalar.nii']);


