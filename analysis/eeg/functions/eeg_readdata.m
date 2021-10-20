function [data] = eeg_readdata(hdrfile, eegfile)
%read and preprocess EEG data from action perception experiment
%trials are read based on stimulus onset, realigned to photodiode onsets,
%and epoched into -0.2 to 1 segments
%data is high-pass filtered at 0.1 Hz and re-referenced to average of mastoids
%D.C. Dima (diana.c.dima@gmail.com) Feb 2020

toi = [-0.2 1]; %duration of epoch of interest

%define trials and realign to photodiode onset
cfg = [];
cfg.headerfile = hdrfile;
cfg.datafile   = eegfile;
cfg.trialdef.eventtype = 'Stimulus';
cfg.trialdef.eventvalue = 'S  1';    %align trials to video onset
cfg.trialdef.prestim = abs(toi(1));
cfg.trialdef.poststim = 1.5;         %read in larger epochs to help with alignment to photodiode triggers
cfg = ft_definetrial(cfg);  
data = ft_preprocessing(cfg);
data = eeg_alignphoto(data, toi);    %realign trials to photodiode and cut into epochs of interest
%badtrials_photo = data.badtrials_photo;

cfg = [];
cfg.toilim = toi;
data = ft_redefinetrial(cfg,data);

%preprocess data
cfg = [];      

cfg.channel = {'all', '-Photodiode'}; %remove photodiode channel
cfg.demean = 'yes';                   %demean data
cfg.baselinewindow = [toi(1) 0];      %use pre-trigger period for baselining
cfg.detrend = 'no';                

cfg.hpfilter = 'yes';                 %high-pass filter before artefact rejection to remove slow drifts
cfg.hpfreq = 0.1;                     %use a low threshold to avoid distorting temporal dynamics
cfg.hpfiltord = 3;                    %a lower filter order ensures filter stability

data = ft_preprocessing(cfg,data);

%deal with 3rd participant issue of one extra block recorded at the start
if contains(hdrfile,'0003') || contains(hdrfile,'0011')
    cfg = [];
    cfg.trials = 151:numel(data.trial);
    data = ft_preprocessing(cfg, data);
end

%data.badtrials_photo = badtrials_photo;



end

