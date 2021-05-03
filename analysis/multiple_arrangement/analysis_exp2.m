%% analysis pipeline for Meadows behavioural similarity data: Experiment 2
% DC Dima 2020 (diana.c.dima@gmai.com)

%%
clear; clc; close all

%set paths
basepath = fileparts(fileparts(pwd));                                         %parent directory
codepath = fullfile(basepath, 'analysis');                                    %analysis code
datapath = fullfile(basepath, 'data','multiple_arrangement','exp2');          %raw data
savepath = fullfile(basepath, 'results','multiple_arrangement','exp2');       %results to save

addpath(genpath(codepath));

savefile = fullfile(savepath,'rdm.mat'); %this will contain the RDM

%files for RSA analysis
rsafile = fullfile(savepath,'rsa.mat');            %RSA results
vptfile = fullfile(savepath,'rsa_varpart.mat');    %variance partitioning results
modfile = fullfile(savepath,'models.mat');         %RSA models
vidfile = fullfile(datapath,'video_features.mat'); %file containing video ratings & stimulus order info for generating RSA models

%% read data
%initial exclusions based on catch trials and feedback are done here
sim_readdata_exp2(datapath,savefile);
       
%% check reliability
%at this stage we further reject participants based on training data reliability
sim_qualitycheck(savefile);

%% run rsa
sim_runrsa(savefile, modfile, rsafile)
%note: if vidfile is provided instead of modfile, model file will be generated here

%% run variance partitioning
sim_varpart(savefile, modfile, vptfile,2)