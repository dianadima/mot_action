function [data,preproc] = eeg_trialselect(data, preproc, trlfile)
%remove catch trials/trials with responses, and add updated trial list to
%data structure for further analyses (action perception experiment)
%final step in EEG data cleaning 
%D.C.Dima (diana.c.dima@gmail.com) Feb 2020

%% load .mat file containing trial list & responses
trl = load(trlfile);
ntrl = 1720;

%check if a response variable was recorded and remove all trials with a response in addition to the catch trials
if isfield(trl,'response') && ~contains(trlfile,'p14')
    trl.catch_trl_idx = unique([trl.catch_trl_idx find(trl.response)]);
end

%make a catch/response trial index
catchlist = false(1,ntrl); 
catchlist(trl.catch_trl_idx) = 1;

%for the first participant - remove the last trial
if contains(trlfile, 'p01')
    %remove last trial which was not recorded in pilot session
    triallist = trl.trl_list(1:end-1);
    catchlist = catchlist(1:end-1);
elseif contains(trlfile,'p07')
    %remove first 3 trials, not recorded in EEG
    triallist = trl.trl_list(4:end); 
    catchlist = catchlist(4:end);
elseif contains(trlfile,'p10')
    %remove first 2 trials, not recorded in EEG
    triallist = trl.trl_list(3:end); 
    catchlist = catchlist(3:end);
else
    triallist = trl.trl_list;
end

preproc.catch_trl = catchlist;                    %save index of catch trials in the preproc struct

%% 1. remove catch trials from clean EEG data
% adjust catch trial index to EEG size
trl_rmv_eeg = catchlist(preproc.idx_badtrial==0); %keep only good trials, so as to match EEG data which has been cleaned

%new EEG data struct: keep only the trials set to 0 in the catch trial index
cfg = [];
cfg.trials = find(~trl_rmv_eeg);
data = ft_preprocessing(cfg, data);

%% 2. remove (1) bad EEG trials (2) catch & response trials from trial list
trl_rmv_lst = logical(catchlist'+preproc.idx_badtrial);
triallist(trl_rmv_lst) = [];

if numel(triallist)~=numel(data.trial)
    error('Something is wrong with the trial selection')
end


%% save

%remove cfg to reduce file size and add trial list/video names to the EEG data itself for easy further analysis
data = rmfield(data,'cfg');
data.triallist = triallist;
data.videofiles = trl.videofiles;

%save the final number of trials
preproc.num_trl = numel(data.trial);






end

