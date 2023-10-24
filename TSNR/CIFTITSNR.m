function [mean_tSNR,mean_tmean,mean_tSD] = CIFTITSNR(cifti_file,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%% declare optional input defaults then parse varargin

p = inputParser;
addParamValue(p,'OutputDirectory','./');
addParamValue(p,'CiftiPath','/path/to/my/Matlab_CIFTI/');
addParamValue(p,'GiftiPath','/path/to/my/gifti-1.6/');
% addParamValue(p,'WorkbenchCommand','wb_command');
addParamValue(p,'WorkbenchCommand','/path/to/my/workbench/1.5.0/workbench/bin_linux64/wb_command');
addParamValue(p,'DscalarTemplate','/path/to/my/91282_Greyordinates.dscalar.nii'); % can be any dscalar that uses the HCP 91k greyordinates

parse(p,varargin{:})

%% declare variables and set paths
addpath(genpath(p.Results.CiftiPath))
addpath(genpath(p.Results.GiftiPath))
output_directory=p.Results.OutputDirectory;
wb_command=p.Results.WorkbenchCommand;
dscalar_template=p.Results.DscalarTemplate;

%% load cifti file
cifti_tseries = ciftiopen(cifti_file,wb_command);
dtseries = cifti_tseries.cdata;
clear cifti_tseries

tmp_dscalar=ciftiopen(dscalar_template,wb_command);
outfile_base=extractBefore(cifti_file,'.dtseries.nii');

%% calculate tSNR
mean_dtseries = mean(dtseries,2);
tmp_dscalar.cdata=mean_dtseries;
mean_tmean = mean(mean_dtseries,'omitnan');
ciftisave(tmp_dscalar,[outfile_base 'tmean.dscalar.nii'],wb_command);
sd_dtseries = std(dtseries,[],2);
tmp_dscalar.cdata=sd_dtseries;
mean_tSD = mean(sd_dtseries,'omitnan');
ciftisave(tmp_dscalar,[outfile_base 'tsd.dscalar.nii'],wb_command);
tsnr_dtseries= mean_dtseries./sd_dtseries;
tmp_dscalar.cdata=tsnr_dtseries;
ciftisave(tmp_dscalar,[outfile_base 'tsnr.dscalar.nii'],wb_command);
mean_tSNR = mean(tsnr_dtseries,'omitnan');

end

