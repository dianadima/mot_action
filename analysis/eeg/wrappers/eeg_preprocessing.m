function [] = eeg_preprocessing(eegpath, trlpath, outpath, rerunflag)
% loop through subjects and read, preprocess and plot EEG data (basic timelock analysis)
% action perception experiment
% inputs: eegpath: path to data
%         trlpath: path to mat files with stimulus order
%         outpath: where to save preprocessed data
%         rerunflag: if 0, will attempt to reload preprocessed data from outpath and plot it; 
%                    if 1, will attempt to load artefact rejection criteria from file and reapply them; 
%                    if 2, will rerun pipeline from scratch even if preprocessed data exists.
%D.C. Dima (diana.c.dima@gmail.com) Feb 2020

%get the list of .mat files containing the trial lists and responses
trldir = dir(trlpath); trldir = {trldir(3:end).name};

nsub = numel(trldir);           %number of subjects
timelock_array = cell(nsub,1);  %store timelock data in cell array for averaging


for isub = 1:nsub
    
    %get subject-specific paths and filenames
    sub        = sprintf('%02.f',isub);
    subeegpath = fullfile(eegpath, sub);
    hdrfile    = fullfile(subeegpath, sprintf('vid%04.f.vhdr',isub));
    eegfile    = fullfile(subeegpath, sprintf('vid%04.f.eeg',isub));
    trlfile    = fullfile(trlpath, trldir{contains(trldir, ['p' sub '_'])});
    
    %get subject-specific output path (data & figures)
    suboutpath = fullfile(outpath, sub);
    outfile    = fullfile(suboutpath, [sub 'data.mat']);
    figpath    = fullfile(outpath,'Figures');
    
    %file with artefact rejection parameters - can be reapplied 
    prcfile = strrep(outfile,'.mat','_preproc.mat');
    
    if ~exist(suboutpath,'dir'), mkdir(suboutpath); end
    if ~exist(figpath,'dir'), mkdir(figpath); end
       
    %do not rerun preprocessing for subjects that have been preprocessed already
    if exist(outfile,'file') && ~rerunflag                              %do not rerun - load existing data
        
        data = load(outfile);
        eeg_readphotoduration(hdrfile,eegfile,prcfile); 
        
    elseif exist(prcfile,'file') && rerunflag==1                        %rerun, but load existing processing parameters
        
        data = eeg_readdata(hdrfile,eegfile);                           %read and realign data
        [data, ~] = eeg_cleandata(data, outfile, trlfile, prcfile);     %reject artifacts/preprocess
        
    else                                                                %run from scratch
        
        data = eeg_readdata(hdrfile,eegfile);                           %read and realign data
        [data, ~] = eeg_cleandata(data, outfile, trlfile);%, prcfile);  %reject artifacts/preprocess
        eeg_readphotoduration(hdrfile,eegfile,prcfile);                 %save stimulus duration for each subject
    end
    
    %timelock analysis
    cfg = [];
    timelock = ft_timelockanalysis(cfg,data);
    eeg_ploterp(timelock, sub, figpath) %plot & save ERP topographies/butterfly plot
    
    timelock_array{isub} = timelock;
    
end

close all
 
%plot & save grand average topography and global field power
cfg = [];
subtimelock = ft_timelockgrandaverage(cfg,timelock_array{:});
eeg_ploterp(subtimelock,'avg',figpath);

end

