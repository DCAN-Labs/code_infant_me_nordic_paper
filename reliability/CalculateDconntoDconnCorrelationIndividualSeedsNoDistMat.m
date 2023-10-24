function CalculateDconntoDconnCorrelationIndividualSeeds(varargin)
%CalculateDconntoDconnCorrelation calculates a correlation between dconns.
%In this case between a part of a dconn from a short part of a time series
%and the ground truth
%It calculates the correlation between each seed of one dconn and each seed
%of teh other and created an average value
% this function loads two dconns/pconns, calculates their correlation and
% writes the resulting matrix as a .txt file to the output directory
%
% Usage: [dconn_corr] = CalculateDconntoDconnCorrelation(varargin)
%
%   Required inputs:
%   dconn_one <path>               :  path to first pconn/dconn to load
%   dconn_two <path>       :  path to second pconn/dconn to load
%   wb_command <path>       :  path to workbench command
%   OutputDirectory <path> : path to output directory
%   GIFTI_path <path> : path to GIFTI tool box
%   CIFTI_path <path> : path to CIFTI tool box

%% declare optional input defaults then parse varargin
p = inputParser;
addParamValue(p,'DconnShort','./dummy');
addParamValue(p,'DconnGroundTruth','./dummytwo');
%addParamValue(p,'DistanceMatrix','./dummythree');
addParamValue(p,'OutputDirectory','./');
addParamValue(p,'OutputName','./');
addParamValue(p,'wb_command','wb_command');
addParamValue(p,'CIFTI_path','/home/miran045/shared/code/internal/utilities/cifti-matlab');
addParamValue(p,'GIFTI_path','/home/miran045/shared/code/internal/utilities/gifti/');

parse(p,varargin{:})


%% parse the inputs
output_directory=p.Results.OutputDirectory;
output_name=p.Results.OutputName;
wb_command=p.Results.wb_command;
addpath(genpath(p.Results.CIFTI_path))
addpath(genpath(p.Results.GIFTI_path))
dconn_short=p.Results.DconnShort;
dconn_long=p.Results.DconnGroundTruth;
%dist=p.Results.DistanceMatrix;
%% load distance matrix
%remark: intrahemespheric distances are geodesic, intrahemispheric and
%subcortical distances euclidean.
%distance_matrix=load(dist);
%dist_data=distance_matrix.EUGEODistancematrix;
%% load dconn one 
dconn_short_conn = ciftiopen(dconn_short,wb_command);
dconn_short_data = dconn_short_conn.cdata;
if (dconn_short_data(1,1) > 7)
    dconn_short_data = tanh(dconn_short_data);
end
%extract dimension infor to use it later to differentiate between L and R
%hemisphere for distances
try
dconn_new.diminfo=dconn_short_conn.diminfo;
catch
    which ciftiopen
    error('wrong ciftiopen')
end

clear dconn_short_conn

%% load dconn two 
dconn_long_conn = ciftiopen(dconn_long,wb_command);
dconn_long_data = dconn_long_conn.cdata;
if (dconn_long_data(1,1) > 7)
    dconn_long_data = tanh(dconn_long_data);
end
clear dconn_long_conn
%% define left and right hemisphere to ensur that only geodesic distances are used for excluding correlations
%Lhemi=[dconn_new.diminfo{1,1}.models{1,1}.start,(dconn_new.diminfo{1,1}.models{1,1}.start + dconn_new.diminfo{1,1}.models{1,1}.count)-1];
%Rhemi=[dconn_new.diminfo{1,1}.models{1,2}.start,(dconn_new.diminfo{1,1}.models{1,2}.start + dconn_new.diminfo{1,1}.models{1,2}.count)-1];

%dist_reduced=NaN(size(dist_data));
%dist_reduced(1:Lhemi(2),1:Lhemi(2))=dist_data(1:Lhemi(2),1:Lhemi(2));
%dist_reduced(Rhemi(1):Rhemi(2),Rhemi(1):Rhemi(2))=dist_data(Rhemi(1):Rhemi(2),Rhemi(1):Rhemi(2));
%binary matrix with 1 for all datapoints that shall be removed
%binary_dist=dist_reduced>=10 | isnan(dist_reduced);
%binary_dist=logical(abs(binary_dist-1));
%% exclude close voxels for correlation and calculate correlation by seed
%dconn_short_data(binary_dist)=NaN;
%dconn_long_data(binary_dist)=NaN;
%% calculate pairwise correlation (R squared)
%use loop as we're only interested in the diagonal of the matrix (faster)
tic
for i=1:size(dconn_short_data,1)
    seedCorr(i,1)=(corr(dconn_short_data(:,i), dconn_long_data(:,i), 'rows','pairwise')).^2;
end
toc
%% calculate correlation and write to file

writematrix(seedCorr, strcat(output_directory,'/', output_name, '.txt'));

end

