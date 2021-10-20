% Action perception EEG experiment analysis %

%% set paths
clear; clc

%set main paths
bdir = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop';
basepath = fullfile(bdir,'MomentsInTime','mot_action');
basepath_eeg = fullfile(basepath,'data','eeg');

%Fieldtrip
addpath(fullfile(bdir,'Scripts', 'fieldtrip-20191022/'))
ft_defaults

%pairwise decoding & plotting
addpath(fullfile(bdir,'Scripts','meg-mvpa/mvpa-for-meg')); mvpa_setup
addpath(genpath(fullfile(bdir,'Scripts','fusionlab_toolbox')))

%EEG analysis
addpath(genpath(pwd))
addpath(genpath(fullfile(basepath,'analysis','utils')))

%EEG data
eegpath = fullfile(basepath_eeg,'data');                        %raw EEG data
trlpath = fullfile(basepath_eeg,'trials');                      %trial lists & responses
stimfile = fullfile(basepath_eeg,'paradigm','videoset.mat');    %file with info about stimuli

outpath = fullfile(basepath,'results','eeg');                   %output: preproc data & figures
if ~exist(outpath,'dir'), mkdir(outpath); end

%% read/preprocess EEG data and plot ERPs

eeg_preprocessing(eegpath, trlpath, outpath, 0);

%% pairwise decoding of videos

eeg_decode(outpath);

%% RSA
cfg = [];
cfg.stimfile = stimfile; % only include this to create the RSA models from scratch - else they will be loaded from file
cfg.outpath = outpath;
cfg.modfile = fullfile(outpath,'RSA','models.mat');
cfg.decoding_file = fullfile(outpath,'decoding_accuracy.mat'); %file storing pairwise decoding accuracies

eeg_rsa(cfg);

%% variance partitioning
% cross-validated
cfg = [];
cfg.outpath = outpath;
cfg.vpfile = 'varpart_cv.mat';
cfg.type = 'cv';
eeg_varpart(cfg);

%fixed-effects
cfg.vpfile = 'varpart_avg.mat';
cfg.type = 'avg';
eeg_varpart(cfg)
