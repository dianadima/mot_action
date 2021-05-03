%% analysis pipeline for Meadows behavioural similarity data: Experiment 1
% DC Dima 2020 (diana.c.dima@gmai.com)

%%
clear; clc; close all

%set paths
basepath = fileparts(fileparts(pwd));                                         %parent directory
codepath = fullfile(basepath, 'analysis');                                    %analysis code
datapath = fullfile(basepath, 'data','multiple_arrangement','exp1');          %raw data
savepath = fullfile(basepath, 'results','multiple_arrangement','exp1');       %results to save

addpath(genpath(codepath));

%these data were collected in 2 batches, so they need to be combined
ndata = 2;
datasets = deal(fullfile(datapath,{'set1','set2'}));
savedata = deal(fullfile(savepath, {'rdm1.mat','rdm2.mat'}));
savefile = fullfile(savepath,'rdm.mat'); %this will contain the combined RDM

%files for RSA analysis
rsafile = fullfile(savepath,'rsa.mat');                  %RSA results
vptfile = fullfile(savepath,'rsa_varpart.mat');          %variance partitioning results
modfile = fullfile(savepath,'models.mat');               %RSA models
vidfile = fullfile(datapath,'video_features.mat');       %file containing video ratings & stimulus order info for generating RSA models

%% read data from the 2 datasets
%initial exclusions based on catch trials and feedback are done here

for d = 1:ndata

    sim_readdata_exp1(datasets{d},savedata{d});

end
    
%% to read in all mturk IDs and match them to Meadows IDs if necessary
mturkdatafile = fullfile(datasets{2}, 'mturk_id','Meadows_MomentsinTime_v_v4_mTurk-ID_tree.json');
sim_mturkid(mturkdatafile);

%% combine the two datasets
sim_combinedata(savedata{1},savedata{2},savefile);
    
%% check reliability
%at this stage we further reject participants based on training data reliability
sim_qualitycheck(savefile);

%% run rsa
sim_runrsa(savefile,modfile,rsafile)
%note: if vidfile is provided instead of modfile, model file will be generated here

%% run variance partitioning
sim_varpart(savefile,modfile,vptfile,1)