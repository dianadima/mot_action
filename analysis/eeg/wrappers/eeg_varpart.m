function [] = eeg_varpart(cfg)
% run variance partitioning analysis on EEG data
% input: cfg with optional settings
%        outpath: results path
%        modfile: file with model RDMs
%        vpfile: output file
%        decoding_file: file with decoding accuracy/RDM
%        type: 'cv', split-half cross-validated, or 'avg', fixed-effects

try outpath = cfg.outpath; catch, outpath = pwd; cfg.outpath = outpath; end 
rsapath = fullfile(outpath,'RSA');

try modfile = fullfile(rsapath,cfg.modfile); catch, modfile = fullfile(rsapath,'models.mat'); cfg.modfile = modfile; end
try vpfile = fullfile(rsapath,cfg.vpfile); catch, vpfile = fullfile(rsapath, 'rsa_varpart.mat'); end
try type = cfg.type; catch, type = 'cv'; end %cross-validated (cv) vs fixed-effects (avg)
try decoding_file = fullfile(outpath, cfg.decoding_file); catch, decoding_file = fullfile(outpath,'decoding_accuracy.mat'); end

load(decoding_file,'decoding_matrix','time')
rdm = decoding_matrix; clear decoding_matrix   
load(modfile,'models','modelnames')

%group models and select
mod1 = {'Action category','Activity','Transitivity','Effectors'};
mod2 = {'Number of agents','Valence','Arousal'}; %'Sociality',
mod3 = {'Environment','FC8','Conv1'};

groupnames = {'Action', 'Social', 'Visual'};
mod = {mod1,mod2,mod3};
ncomb = 7; 
sel_mod = sim_prepmodels(mod,models,modelnames);

if strcmp(type,'cv')
    
    varpart = eeg_varpartcv(rdm,time,reg,sel_mod{1},sel_mod{2},sel_mod{3});

elseif strcmp(type,'avg')
    
    % get time windows and normalize RDM
   [winmat,time,nwin] = eeg_timewindows(time,size(rdm,3));
    
    rdm = squeeze(nanmean(rdm,1));
    for r = 1:size(rdm,2)
        rdm(:,r) = (rdm(:,r)-min(rdm(:,r)))/(max(rdm(:,r))-min(rdm(:,r)));
    end
 
    %initialize variables
    nprm = 1000;
    randidx = nan(nprm,size(rdm,1));
    
    rsq_adj = nan(ncomb,nwin);
    rsq_tot = nan(1,nwin);
    rsq_rnd = nan(ncomb,nprm,nwin);
    
    for ip = 1:nprm
        randidx(ip,:) = randperm(size(rdm,1));
    end
    
    %run analysis
    for w = 1:nwin
        widx = winmat(:,w);
        fprintf('\nWin %d\n', w)
        vp = rdm_varpart(mean(rdm(:,widx),2)',sel_mod{1},sel_mod{2},sel_mod{3});
        rsq_adj(:,w) = vp.rsq_adj;
        rsq_tot(w) = vp.total_rsq;
        
        %randomize
        for ip = 1:nprm
            randrdm = rdm(randidx(ip,:),w);
            vprand = rdm_varpart(randrdm',sel_mod{1},sel_mod{2},sel_mod{3});
            rsq_rnd(:,ip,w) = vprand.rsq_adj;
        end
    end

    varpart.rsq_adj = rsq_adj;
    varpart.rsq_tot = rsq_tot;
    varpart.rsq_rnd = rsq_rnd;
    varpart.vif = vp.vif; %this does not change across time
    varpart.comb_labels = vp.comb_labels;
    varpart.time = time;

end

varpart.modelnames = groupnames;
varpart = eeg_varpartstats(varpart);
save(vpfile,'varpart');

eeg_plotvarpart(varpart)

% select the models/sets of models for variance partitioning
    function [sel_mod] = sim_prepmodels(mod,models,modelnames)
        
        nmod = numel(mod);
        sel_mod = cell(nmod,1);
        
        for i = 1:nmod
            
            mtmp = mod{i};
            midx = nan(numel(mtmp),1);
            for ii = 1:numel(mtmp)
                midx(ii) = find(cellfun(@(x) strcmp(mtmp{ii},x), modelnames));
            end
            sel_mod{i} = models(:,midx);
        end
        
    end

end
