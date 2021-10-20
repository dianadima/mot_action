function [ data, preproc ] = eeg_cleandata(rawdata, outfile, trlfile, varargin)
%semi-interactive artefact rejection & preprocessing pipeline for 64-channel EEG data (BrainProducts system) 
%input is epoched data in FT format, baselined and re-referenced to average of all electrodes
%input: FT data/file path; output file path; path to file with trial info;
%       optional - path to file with artefact rejection data that can be reapplied
%
%steps: 1. remove muscle artefacts using z-score threshold (semi-automated, z=15)
%       2. reject channels/trials interactively based on variance
%       3. remove EOG and ECG artefacts using ICA
%       4. remove catch trials and trials with a response and save matched trial list specifying stimulus order
%       5. perform additional filtering and resampling if required
%
% D.C.Dima (diana.c.dima@gmail.com) Feb 2020  


%specify electrode layout
layout = 'acticap-64ch-standard2';

%downsampling
resamplefs = 500;

%low-pass filtering
lpfilt = 100;

%% load data from file if not provided as a struct
if ischar(rawdata)
    rawdata = load(rawdata);
end

%badtrl_pho = rawdata.badtrials_photo;
 
%no preproc file provided; run artefact rejection from scratch
if isempty(varargin)
    
    %initial number of trials
    num_trl = numel(rawdata.trial);

    %visualize artefacts in vertical mode
    cfg = [];
    cfg.continuous = 'no';
    cfg.preproc.demean = 'no';
    cfg.viewmode = 'vertical';
    ft_databrowser(cfg, rawdata);
    input('Press ENTER to continue '); %continue
    close
    
    %% 1. automatically remove muscle artefacts based on z-value
    cfg_art = []; %create a configuration to store artefact definitions
    cfg_art.artfctdef.muscle.channel = 'EEG';
    cfg_art.artfctdef.muscle.continuous = 'no';
    cfg_art.artfctdef.muscle.cutoff = 15;         %z-score cutoff
    cfg_art.artfctdef.muscle.bpfilter = 'yes';
    cfg_art.artfctdef.muscle.bpfreq = [110 140];  %high freq filtering to detect muscle artefacts
    cfg_art.artfctdef.muscle.bpfiltord = 8;       %filter order
    cfg_art.artfctdef.muscle.hilbert = 'yes';
    cfg_art.artfctdef.muscle.boxcar = 0.2;
    cfg_art.artfctdef.muscle.artpadding = 0.1;    %pad the detected artefacts by 100 ms
    cfg_art.artfctdef.muscle.interactive = 'yes'; %adjust threshold if necessary
    
    cfg_art = ft_artifact_muscle(cfg_art, rawdata);
    cfg_art.artfctdef.reject = 'nan'; %reject trials by replacing them with NaNs
    data = ft_rejectartifact(cfg_art, rawdata);
    
    %save indices of trials with muscle artefacts
    art = cfg_art.artfctdef.muscle.artifact;
    badtrl_msc = eeg_badtrialidx(art,rawdata);
    zval = cfg_art.artfctdef.muscle.cutoff; %save zvalue
    
    %% 2. additional visual rejection of high-variance trials/channels
    cfg = [];
    cfg.method = 'summary'; %visualize outlier channels and reject them interactively
    cfg.keeptrial = 'nan';
    data = ft_rejectvisual(cfg, data);
    
    %get channel indices (to keep)
    chan = data.label;
    
    %save indices of trials with too-high variance
    art = data.cfg.artfctdef.summary.artifact;
    badtrl_var = eeg_badtrialidx(art,rawdata);
    
    %visualize artefacts again in vertical mode
    cfg = [];
    cfg.continuous = 'no';
    cfg.preproc.demean = 'no';
    cfg.viewmode = 'vertical';
    ft_databrowser(cfg, data);
    clear data
    
    %now remove the bad trials (variance + muscle) from the raw data
    %this way helps preserve the indices of bad trials
    badtrial_idx = false(num_trl,1);
    badtrial_idx(unique([badtrl_var; badtrl_msc])) = 1;
    
    cfg = [];
    cfg.trials = find(~badtrial_idx);
    cfg.channel = chan;
    data_clean = ft_preprocessing(cfg,rawdata);
    
    %% 3. ICA for EOG/ECG artefacts
    
    %downsample to speed up ICA
    cfg = [];
    cfg.resamplefs = 150;
    cfg.detrend = 'no';
    data_clean_ds = ft_resampledata(cfg, data_clean);
    
    %compute the rank of the data to constrain number of components
    data_cat = cat(2,data_clean_ds.trial{:});
    data_cat(isnan(data_cat)) = 0;
    num_comp = rank(data_cat);
    
    %now run ICA
    cfg= [];
    cfg.method = 'runica';
    cfg.numcomponent = num_comp;
    comp = ft_componentanalysis(cfg, data_clean_ds);
    
    %plot components with their time-courses
    cfg = [];
    cfg.layout = layout;
    cfg.viewmode = 'component';
    cfg.continuous = 'yes';
    cfg.blocksize = 60;
    ft_databrowser(cfg, comp);
    
    % plot topographies for first 16 components
    figure
    cfg = [];
    cfg.component = 1:20;
    cfg.layout    = layout;
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp)
    pause(1)
    
    %here give the component numbers to be removed, e.g. [7 10 34]
    comp_rmv = input('Components to be removed (use square brackets if several): ');
    
    close all
    
    %plot and save a figure of the rejected components for future reference
    h = figure;
    cfg = [];
    cfg.component = comp_rmv;
    cfg.layout    = layout;
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp);
    saveas(h, strrep(outfile,'.mat','_comp.png'));
    close;
    
    %this projects the artefactual components out of the original data
    cfg = [];
    cfg.unmixing = comp.unmixing;
    cfg.topolabel = comp.topolabel;
    cfg.demean = 'no';
    comp_orig = ft_componentanalysis(cfg,data_clean);
    
    cfg = [];
    cfg.component = comp_rmv;
    cfg.demean = 'no'; %note - data is demeaned by default
    data = ft_rejectcomponent(cfg, comp_orig, data_clean);
    
    clear data_clean_ds
    
    %check the dataset quality one final time
    cfg = [];
    cfg.preproc.demean = 'no';
    cfg.viewmode = 'vertical';
    ft_databrowser(cfg, data);
    input('Press ENTER to continue: ');
    
    %% Final preprocessing steps & save outputs
    
    %get some info of interest
    comp = rmfield(comp, 'time');
    comp = rmfield(comp, 'trial');
    
    %rereference - will be more robust after data cleaning
    cfg            = [];
    cfg.reref      = 'yes';
    cfg.refchannel = 'all';
    cfg.implicitref = 'Cz';
    cfg.refmethod  = 'avg';
    
    %low-pass filter as requested (30 Hz/100 Hz)
    cfg.lpfilter = 'yes';
    cfg.lpfreq = lpfilt;
    data = ft_preprocessing(cfg,data);
    
    %resample data
    cfg = [];
    cfg.detrend = 'no';
    cfg.resamplefs = resamplefs;
    data = ft_resampledata(cfg,data);
    
    preproc.num_channels = length(data.label);
    preproc.num_badtrial = sum(badtrial_idx);
    preproc.idx_badtrial = badtrial_idx;
    preproc.badtrial_variance = badtrl_var;
    preproc.badtrial_muscle = badtrl_msc;
    preproc.muscle_zvalue = zval;
    preproc.icacomponent = comp;
    preproc.comp_rmv = comp_rmv;
    preproc.chan = data.label;
    
    %remove catch/response trials and correct trial list to match cleaned EEG data
    [data, preproc] = eeg_trialselect(data,preproc,trlfile);
    
    %sanity check: plot the average data
    figure
    tmp = cat(3,data.trial{:});
    plot(data.time{1},mean(mean(tmp,1),3))
    
    %save outputs
    save(outfile, '-v7.3', '-struct', 'data'); %save the cleaned & preprocessed data
    save(strrep(outfile,'.mat','_preproc.mat'),'-struct','preproc'); %save variables & trial indices for each subject
    
    close all
    
else
    
    %loads in the preproc structure with bad trials marked
    %useful for tweaking processing parameters w/o rerunning artefact rejection
    preprocfile = varargin{1};
    preproc = load(preprocfile);

    badtrial_idx = preproc.idx_badtrial; %indices of bad trials
    chan = preproc.chan;                 %channels to keep
    comp = preproc.icacomponent;         %ICA components
    comp_rmv = preproc.comp_rmv;         %indices of comp to remove
    
    %clean data based on previously detected bad trials/channels
    cfg = [];
    cfg.trials = find(~badtrial_idx);
    cfg.channel = chan;
    data_clean = ft_preprocessing(cfg,rawdata);
    
    %remove ICA bad components
    %this projects the artefactual components out of the original data
    cfg = [];
    cfg.unmixing = comp.unmixing;
    cfg.topolabel = comp.topolabel;
    cfg.demean = 'no';
    comp_orig = ft_componentanalysis(cfg,data_clean);
    
    cfg = [];
    cfg.component = comp_rmv;
    cfg.demean = 'no'; %note - data is demeaned by default
    data = ft_rejectcomponent(cfg, comp_orig, data_clean);
    
    clear data_clean
    
    %low-pass filter as requested (30 Hz/100 Hz)
    cfg = [];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = lpfilt;
    
    %rereference - will be more robust after data cleaning
    cfg.reref      = 'yes';
    cfg.implicitref = 'Cz';
    cfg.refchannel = 'all';
    cfg.refmethod  = 'median';
    
    data = ft_preprocessing(cfg,data);
    
    %resample data
    cfg = [];
    cfg.detrend = 'no';
    cfg.resamplefs = resamplefs;
    data = ft_resampledata(cfg,data);
    
    %remove catch/response trials and correct trial list to match cleaned EEG data
    [data, preproc] = eeg_trialselect(data,preproc,trlfile);
    
    %sanity check: plot the average data
    figure
    tmp = cat(3,data.trial{:});
    plot(data.time{1},mean(mean(tmp,1),3))
    
    %save outputs
    save(outfile, '-v7.3', '-struct', 'data'); %save the cleaned & preprocessed data
    
end




end

