function [data,preproc] = eeg_trialselect(data, preproc, trlfile)
%remove catch trials/trials with responses, and add updated trial list to
%data structure for further analyses (action perception experiment)
%final step in EEG data cleaning 
%D.C.Dima (diana.c.dima@gmail.com) Feb 2020

%% load .mat file containing trial list & responses
trl = load(trlfile);

%check if a response variable was recorded and remove all trials with a response in addition to the catch trials
if isfield(trl,'response')
    trl.catch_trl_idx = unique([trl.catch_trl_idx find(trl.response)]);
end

%for the first participant - remove the last trial
if contains(trlfile, 'p01')
    %remove last trial which was not recorded in pilot session
    trl.trl_list = trl.trl_list(1:end-1);
elseif contains(trlfile,'p07')
    %remove first 3 trials, not recorded in EEG
    trl.trl_list = trl.trl_list(4:end); 
    trl.catch_trl_idx = trl.catch_trl_idx - 3;
elseif contains(trlfile,'p10')
    %remove first 2 trials, not recorded in EEG
    trl.trl_list = trl.trl_list(3:end); 
    trl.catch_trl_idx = trl.catch_trl_idx - 2;
end

trl.catch_trl_idx(trl.catch_trl_idx<1) = []; %in case indices point to removed trials

%% 1. make logical index of catch trials matching EEG data size (with bad trials removed)
% this will be removed from the EEG data
trl_rmv_eeg = false(1,length(trl.trl_list));        %initialize with all trials set to 0
trl_rmv_eeg(trl.catch_trl_idx) = 1;                 %set catch trials to 1
trl_rmv_eeg = trl_rmv_eeg(preproc.idx_badtrial==0); %keep only good trials, so as to match EEG data which has been cleaned

%new EEG data struct: keep only the trials set to 1 in the EEG index
cfg = [];
cfg.trials = find(~trl_rmv_eeg);
data = ft_preprocessing(cfg, data);

%% 2. make logical index of catch trial & bad EEG trials matching trial list size
% this will be removed from the trial list 
trl_rmv_lst = false(1,length(trl.trl_list));        %initialize with all trials set to 0
trl_rmv_lst(trl.catch_trl_idx) = 1;                 %set catch trials to 1
preproc.catch_trl = trl_rmv_lst;                    %save index of catch trials in the preproc struct
trl_rmv_lst(preproc.idx_badtrial) = 1;              %also set the EEG-based bad trials to 1, so that all are removed

%new trial list: keep only the trials set to 1 in the trial list index
triallist = trl.trl_list;
triallist(trl_rmv_lst) = [];

%% save

%remove cfg to reduce file size and add trial list/video names to the EEG data itself for easy further analysis
data = rmfield(data,'cfg');
data.triallist = triallist;
data.videofiles = trl.videofiles;

%save the final number of trials
preproc.num_trl = numel(data.trial);






end

