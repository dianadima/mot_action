function [rsa_results] = eeg_rsa(cfg)
% run RSA analysis on EEG data
% input: cfg with optional arguments
%       outpath: where to save results
%       outfile: results filename
%       modfile: file with model RDMs
%       plotflag: plot results, 1
% output: rsa results structure
% DC Dima (diana.c.dima@gmail.com)

% parse inputs
try outpath = cfg.outpath; catch, outpath = pwd;cfg.outpath = outpath; end
rsapath = fullfile(outpath,'RSA'); if ~exist(rsapath,'dir'), mkdir(rsapath); end
try modfile = cfg.modfile; catch, modfile = fullfile(rsapath,'models.mat'); cfg.modfile = modfile; end
try outfile = fullfile(rsapath,cfg.outfile); catch, outfile = fullfile(rsapath, 'rsa.mat'); cfg.outfile = outfile; end
try plotflag = cfg.plot; catch, plotflag = 1; end

nperm = 5000; %randomization iterations

try load(modfile,'models','modelnames');
catch
    fprintf('\nNo model file found. Creating models... \n')
    if isfield(cfg,'stimfile')
        stimfile = cfg.stimfile;
        [models, modelnames] = eeg_rsamodels(stimfile, modfile);
    else
        error('No model file found. Please specify cfg.stimfile to create models');
    end
end

%load decoding matrix    
if ~isfield(cfg, 'decoding_file')
    cfg.decoding_file = uigetfile('','Select file with decoding results');
end
load(cfg.decoding_file,'decoding_matrix','time');

%create new time axis
time_orig = time;
[winmat,time,nwin] = eeg_timewindows(time_orig,numel(time_orig));

%initialize variables
nmod = size(models,2); %number of models
nsub = size(decoding_matrix,1);
rsacorr = nan(nsub,nwin,nmod);
    
%run subject-wise analysis
for isub = 1:nsub
    
    rdm = squeeze(decoding_matrix(isub,:,:));
    [subcorr,time] = eeg_runrsa(rdm, models, time_orig, 'kendall');
    rsacorr(isub,:,:) = subcorr;
    
end

%average version
avgrsardm = squeeze(mean(decoding_matrix,1));
avgcorr = eeg_runrsa(avgrsardm, models, time_orig, 'kendall');

%sign permutation testing
[pval,obs,rand,pval_corr] = randomize_rho(rsacorr,'num_iterations',nperm);

clustersigt = false(size(obs));
clusterpval = cell(nmod,1);
opt.alpha = 0.05;
opt.clusteralpha = 0.05;
for imod = 1:nmod
    cluster = find2Dclusters(obs(:,imod),rand(:,:,imod),opt);
    if ~isempty(cluster.sigclusters)
        clustersigt(:,imod) = cluster.sigtime;
        clusterpval{imod} = cluster.sigpvals;
    end
end

% noise ceiling
nc_low = nan(nsub,nwin);
nc_upp = nan(nsub,nwin);

avg = squeeze(mean(decoding_matrix,1));
for isub = 1:nsub
    tmp1 = squeeze(decoding_matrix(isub,:,:));
    tmp2 = decoding_matrix;
    tmp2(isub,:,:) = [];
    tmp2 = squeeze(mean(tmp2,1));
    for iwin = 1:nwin
        widx = winmat(:,iwin);
        nc_low(isub,iwin) = rankCorr_Kendall_taua(mean(tmp1(:,widx),2), mean(tmp2(:,widx),2));
        nc_upp(isub,iwin) = rankCorr_Kendall_taua(mean(tmp1(:,widx),2), mean(avg(:,widx),2));
    end
end


%save results
rsa_results.subcorr = rsacorr;
rsa_results.subrdm = decoding_matrix;
rsa_results.subpval = pval;
rsa_results.subpvalcorr = pval_corr;
rsa_results.clustersig = clustersigt;
rsa_results.clusterpval = clusterpval;
rsa_results.avgrdm = avgrsardm;
rsa_results.avgcorr = avgcorr;
rsa_results.modelnames = modelnames;
rsa_results.time = time;
rsa_results.nc.upp = nc_upp;
rsa_results.nc.low = nc_low;
rsa_results.cfg = cfg;

save(outfile,'-struct','rsa_results')

rsa_results = eeg_rsaonsets(rsa_results);

save(outfile,'-struct','rsa_results')

%plot if requested
if plotflag
    
    plotpath = fullfile(rsapath,'Figures_NMF');
    if ~exist(plotpath,'dir'), mkdir(plotpath); end
    
    eeg_plotrsa(rsa_results, plotpath)
    
end

end

