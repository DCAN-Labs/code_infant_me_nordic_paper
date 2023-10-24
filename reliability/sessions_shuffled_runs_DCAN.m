function sessions_shuffled_runs_DCAN(SUB, SES, FD, TASK, TR, MAXMIN, permnum, infolder)

addpath(genpath('/path/to/my/cifti-matlab'));

%% step 1, load random run order
if SUB=='PB0005'
    SES_short=SES(1:2);
    load(['/path/to/my/rand_order_runs_' SUB '_' SES_short '.mat']);
elseif SUB=='PB0004'
    SES_short=SES(1:2);
    load(['/path/to/my/rand_order_runs_' SUB '_' SES_short '.mat']);
else
    load(['/path/to/my/rand_order_runs_' SUB '.mat']);
end
run_oder=rand_order_runs(permnum,:);
%% step 2, load concatenated dtseries

%load concatenated time series
concatenated_timeseries=cifti_read([infolder '/sub-' SUB '/ses-' SES '/func/sub-' SUB '_ses-' SES '_task-' TASK '_bold_desc-filtered_timeseries.dtseries.nii']);

%determine list of frames per run by subject
if SUB=='PB0005'
   if contains(SES,'ME')
       framelist=[317; 317; 317; 181; 317; 317; 317; 317; 317; 317; 317; 317; 317]; 
   elseif contains(SES,'SE')
       framelist=[420; 420; 420; 420; 284; 420; 420; 115; 301; 420; 420; 420; 420]; 
   end
elseif SUB=='PB0004'
  if contains(SES,'ME')
      framelist=[317; 317; 317; 317; 317; 317; 130; 110; 317]; 
  elseif contains(SES,'SE')
        framelist=[420; 131; 420; 420; 420; 420; 420; 420]; 
  end
elseif SUB=='adult'
    framelist=repelem(510,10,1); 
elseif SUB=='PB0001'
    framelist=repelem(230,21,1);
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

cifti_write(new_timeseries, ['sub-' SUB '_ses-' SES '_task-' TASK '_bold_shuffled_timeseries.dtseries.nii']);
%% step 3, load motion file and create masks
%load motion file
load([infolder '/sub-' SUB '/ses-' SES '/func/sub-' SUB '_ses-' SES '_task-' TASK '_desc-filtered_motion_mask.mat']);

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
save(['sub-' SUB '_ses-' SES '_task-' TASK '_desc-filtered_motion_mask.mat'], 'motion_data');

%% step 3.3, create masks and write them to tmp space
mkdir('masks')

% mask groundtruth - start after MAXMIN
cap=round(MAXMIN*60/TR);
if size(good_frames,1)>cap*2
    mask_gt=zeros(size(rearranged_fd));
    mask_gt(good_frames(cap+1:cap*2))=1;
else
    error('not enough data')
end

writematrix(mask_gt, ['masks/sub-' SUB '_ses-' SES '_mask_groundtruth_' num2str(MAXMIN) 'min.txt']);

%mask half 1 for every minute defined in MIN_X
MIN_X=[1 2 3 4 5 7 10:5:MAXMIN];

for i=1:size(MIN_X,2)
    framecount=round(MIN_X(i)*60/TR);
    mask_h1=zeros(size(rearranged_fd));
    mask_h1(good_frames(1:framecount))=1;

    writematrix(mask_h1, ['masks/sub-' SUB '_ses-' SES '_mask_half1_' num2str(MIN_X(i)) 'min.txt']);
end


end

