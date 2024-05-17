function sessions_shuffled_runs_xcpd_dtseries(SUB, SES, FD, TASK, TR, MAXMIN, permnum, infolder, infile)

addpath(genpath('/my/path/to/cifti-matlab'));


%% step 1, load random run order
if contains(TASK, 'ME')
    load(['rand_order_runs_sub-' SUB '.mat']);
elseif contains(TASK, 'SE')
    load(['rand_order_runs_sub-' SUB '_SE.mat']);
end
run_oder=rand_order_runs(permnum,:);
%% step 2, load concatenated dtseries

%load concatenated time series
concatenated_timeseries=cifti_read(infile);

%determine list of frames per run by subject
if contains(SUB, 'BIO') %PA0001
    if contains(TASK, 'SE')
    framelist=[1124; 1124; 647; 1124; 1124; 1124; 1124; 1124; 597; 1124; 597; 1124]; %3T runs
    elseif contains(TASK, 'ME')
    framelist=repelem(547,10,1); %3T runs
    end
 elseif contains(SUB, 'C02') %PA0002
    if contains(TASK, 'SE')
    framelist=repelem(1124,10,1);
    elseif contains(TASK, 'ME')
    framelist=[510; 510; 441; 441; 441; 510; 510; 510; 510; 510; 510; 510; 510; 510]; 
    end
elseif contains(SUB, '7001') %PC0001
    framelist=[547; 547; 337; 547; 547; 337; 547; 547; 337; 547; 547; 337]; 
elseif contains(SUB, '9501') %PC0002
    framelist=[547; 547; 337; 547; 547; 337; 547; 337; 547; 547; 337];
  
end

%create array with starting and stopping point of frame list
framelist_start=1;
for i=2:size(framelist,1)
    framelist_start(i,1)=framelist(i-1,1)+framelist_start(i-1,1);
end

for i=1:size(framelist,1)
    framelist_stop(i,1)=framelist_start(i,1)+framelist(i,1)-1;
end

%split data by run according to the frames per run
for i=1:size(framelist,1)
    data_by_run{i}=concatenated_timeseries.cdata(:,framelist_start(i):framelist_stop(i));
end

%rearrange data by run order to build new concatenated timeseries
k=1;
rearranged_data=[data_by_run{1,run_oder(k)}];
while k<size(run_oder,2)
rearranged_data=[rearranged_data, data_by_run{1,run_oder(k+1)}];
k=k+1;
end

new_timeseries=concatenated_timeseries;
new_timeseries.cdata=rearranged_data;
new_timeseries.diminfo{1,2}.length=size(rearranged_data,2);


cifti_write(new_timeseries, [infolder '/sub-' SUB '_ses-' SES '_task-' TASK '_bold_shuffled_timeseries.dtseries.nii']);
%% step 3, load motion file and create masks
%load motion file
load([infolder '/sub-' SUB '_ses-' SES '_task-' TASK '_desc-dcan_qc_power_2014_FD_only.mat']);

%pick fd traces with fitting FD value
for i=1:size(motion_data,2)
    list_thresholds(i,1)=motion_data{1,i}.FD_threshold;
end
index=find(list_thresholds==FD);

fd_vector=motion_data{1,index}.frame_removal;

retained_frames=abs(fd_vector-1);
%% step 3.1, sort motion file according to new run order

%split data by run according to the frames per run
for i=1:size(framelist,1)
    fd_by_run{i}=retained_frames(framelist_start(i):framelist_stop(i));
end

%rearrange data by run order to build new concatenated motion trace
k=1;
rearranged_fd=[fd_by_run{1,run_oder(k)}];
while k<size(run_oder,2)
rearranged_fd=[rearranged_fd; fd_by_run{1,run_oder(k+1)}];
k=k+1;
end

good_frames=find(rearranged_fd==1); %good frames in whole dataset

%% step 3.2 replace cell in motion file
motion_data{1,index}.frame_removal=abs(rearranged_fd-1);
motion_data{1,index}.total_frame_count=size(rearranged_fd,1);
motion_data{1,index}.remaining_frame_count=size(good_frames,1);
motion_data{1,index}.remaining_seconds=size(good_frames,1)*TR;
save([infolder '/sub-' SUB '_ses-' SES '_task-' TASK '_desc-filtered_motion_mask.mat'], 'motion_data');

%% step 3.3, create masks and write them to tmp space
mkdir([infolder '/masks'])

% mask groundtruth - start after MAXMIN
cap=round(MAXMIN*60/TR);
if size(good_frames,1)>cap*2
    mask_gt=zeros(size(rearranged_fd));
    mask_gt(good_frames(cap+1:cap*2))=1;
else
    error('not enough data')
end

writematrix(mask_gt, [infolder '/masks/sub-' SUB '_ses-' SES '_mask_groundtruth_' num2str(MAXMIN) 'min.txt']);

%mask half 1 for every minute defined in MIN_X
MIN_X=[1:MAXMIN];

for i=1:size(MIN_X,2)
    framecount=round(MIN_X(i)*60/TR);
    mask_h1=zeros(size(rearranged_fd));
    mask_h1(good_frames(1:framecount))=1;

    writematrix(mask_h1, [infolder '/masks/sub-' SUB '_ses-' SES '_mask_half1_' num2str(MIN_X(i)) 'min.txt']);
end


end

