% Action perception EEG experiment analysis %

%% set paths
clear

%set main paths
bdir = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop';
basepath = fullfile(bdir,'MomentsInTime','mot_action');
basepath_eeg = fullfile(basepath,'data','eeg');

%Fieldtrip
addpath(fullfile(bdir,'Scripts', 'fieldtrip-20191022/'))
ft_defaults

%pairwise decoding & plotting
addpath(genpath(fullfile(bdir,'Scripts','meg-mvpa/mvpa-for-meg')))
addpath(genpath(fullfile(bdir,'Scripts','fusionlab_toolbox')))

%EEG analysis
addpath(genpath(pwd))
addpath(genpath(fullfile(basepath,'analysis','utils')))

%EEG data
eegpath = fullfile(basepath_eeg,'data');                        %raw EEG data
trlpath = fullfile(basepath_eeg,'trials');                      %trial lists & responses
stimfile = fullfile(basepath_eeg,'paradigm','videoset.mat');    %file with info about stimuli

outpath = fullfile(basepath,'results','eeg');                   %output: preproc data & figures

%% read/preprocess EEG data and plot ERPs

eeg_preprocessing(eegpath, trlpath, outpath, 0);

%% pairwise decoding of videos

eeg_decode(outpath);

%% RSA
cfg = [];
cfg.stimfile = stimfile; %only include this to create the RSA models from scratch - else they will be loaded from file
cfg.outpath = outpath;
cfg.method = 'euclid'; % or 'euclid' for eucliden distances
cfg.type = 'spearman';
cfg.decoding_file = fullfile(outpath,'pairwise_decoding_accuracy_pseudo.mat'); %file storing pairwise decoding accuracies

eeg_rsa(cfg);

%% variance partitioning
cfg = [];
cfg.outpath = outpath;
eeg_varpart(cfg);
