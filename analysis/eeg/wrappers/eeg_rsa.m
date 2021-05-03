function [rsa_results] = eeg_rsa(cfg)
% run RSA analysis on EEG data
% input: cfg with optional settings

% parse inputs
try nsub = cfg.nsub; catch, nsub = 10; cfg.nsub = nsub; end 
try nwin = cfg.nwin; catch, nwin = 601; cfg.nwin = nwin; end
try method = cfg.method; catch, method = 'euclid'; cfg.method = method; end
try type = cfg.type; catch, type = 'kendall'; end
try analysis_window = cfg.analysis_window; catch, analysis_window = [-0.2 1]; cfg.analysis_window = analysis_window; end
try window_length = cfg.window_length; catch, window_length = 1; cfg.window_length = window_length; end

try outpath = cfg.outpath; catch, outpath = pwd;cfg.outpath = outpath; end 
rsapath = fullfile(outpath,'RSA');
try modfile = cfg.modfile; catch, modfile = fullfile(rsapath,'models.mat'); cfg.modfile = modfile; end
try outfile = fullfile(rsapath,cfg.outfile); catch, outfile = fullfile(rsapath, sprintf('rsa_results_%s.mat',method)); cfg.outfile = outfile; end

try plotflag = cfg.plot; catch, plotflag = 1; end
try nperm = cfg.nperm; catch, nperm = 5000; cfg.nperm = nperm; end

try load(modfile,'models','modelnames');
catch
    if isfield(cfg,'stimfile')
        stimfile = cfg.stimfile;
        [models, modelnames] = eeg_rsamodels(stimfile, modfile);
    else
        error('No model file found. Please specify cfg.stimfile to create models'); 
    end
end


%initialize variables
nprs = size(models,1); %number of pairs
nmod = size(models,2); %number of models
rsacorr = nan(nsub,nwin,nmod);
rsardm = nan(nsub,nprs,nwin);

%run subject-wise analysis
for isub = 1:nsub
    
    %get subject specific paths and filenames
    sub = sprintf('%02.f',isub);
    suboutpath = fullfile(outpath, sub);
    
    switch method
        
        case 'euclid'
            
            datafile = fullfile(suboutpath, [sub 'data.mat']);
            data = load(datafile);
            datamatrix = eeg_preparerdm(data,1); %1 = average: prepares an RDM by averaging video repeats
            if size(datamatrix,3)~=152
                fprintf('\nSub%d:%dvideos\n',isub,size(datamatrix,3));
            end
            [~,rdm] = eeg_makerdm(datamatrix, 'channels', 'all', 'time', data.time{1},'analysis_window',analysis_window,'window_length',window_length);
            
        case 'decoding'
            
            if ~isfield(cfg, 'decoding_file')
                cfg.decoding_file = uigetfile('','Select file with decoding results');
            end
            load(cfg.decoding_file,'decoding_accuracy');
            if isstruct(decoding_accuracy)
                rdm = decoding_accuracy(isub).d';
            elseif iscell(decoding_accuracy)
                rdm = decoding_accuracy{isub}.d';
            else
                rdm = squeeze(decoding_accuracy(isub,:,:))';
            end
    end
                    
    subcorr = eeg_runrsa(rdm, models, type);
    rsacorr(isub,:,:) = subcorr;
    rsardm(isub,:,:) = rdm;
    
end

%average version
avgrsardm = squeeze(mean(rsardm,1));
avgcorr = eeg_runrsa(avgrsardm, models, type);

%sign permutation testing   
[pval,~,~,pval_corr] = randomize_rho(rsacorr,'num_iterations',nperm);

%save results
rsa_results.subcorr = rsacorr;
rsa_results.subrdm = rsardm;
rsa_results.subpval = pval;
rsa_results.subpvalcorr = pval_corr;
rsa_results.avgrdm = avgrsardm;
rsa_results.avgcorr = avgcorr;
rsa_results.modelnames = modelnames;
rsa_results.cfg = cfg;

if exist('data','var')
    time = data.time{1};
    time = time(nearest(time,analysis_window(1)):window_length:nearest(time,analysis_window(2)));
    rsa_results.time = time;
end

save(outfile,'-struct','rsa_results')

%plot if requested
if plotflag
    
    plotpath = fullfile(rsapath,'Figures'); 
    if ~exist(plotpath,'dir'), mkdir(plotpath); end
    
    eeg_plotrsa(rsa_results, plotpath)
    
end

end

