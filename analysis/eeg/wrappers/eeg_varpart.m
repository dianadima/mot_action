function [] = eeg_varpart(cfg)
% run variance partitioning analysis on EEG data
% input: cfg with optional settings


try nwin = cfg.nwin; catch, nwin = 601; cfg.nwin = nwin; end
try outpath = cfg.outpath; catch, outpath = pwd;cfg.outpath = outpath; end 
rsapath = fullfile(outpath,'RSA');
try rdmfile = cfg.rdmfile; catch, rdmfile = fullfile(rsapath,'rsa.mat'); end
try modfile = cfg.modfile; catch, modfile = fullfile(rsapath,'models.mat'); cfg.modfile = modfile; end
try vpfile = cfg.vpfile; catch, vpfile = fullfile(rsapath, 'rsa_varpart.mat'); end
try type = cfg.type; catch, type = 'cv'; end %cross-validated (cv) vs fixed-effects (avg)

load(modfile,'models','modelnames')

%group models and select
mod1 = {'Action category','Action','Transitivity','Effectors'};
mod2 = {'Number of agents','Sociality','Valence','Arousal'};
mod3 = {'FC8','Environment'};
mod = {mod1,mod2,mod3};
sel_mod = sim_prepmodels(mod,models,modelnames);


%load files
if strcmp(type,'avg')
    
    load(rdmfile,'avgrdm'); 
    rdm = avgrdm;
    
    rsq_adj = nan(7,nwin);
    rsq_tot = nan(1,nwin);
    for w = 1:nwin
        vp = rdm_varpart(rdm(:,w)',sel_mod{1},sel_mod{2},sel_mod{3});
        rsq_adj(:,w) = vp.rsq_adj;
        rsq_tot(w) = vp.total_rsq;
    end
    
    varpart.modelnames = {'Semantic','Social','Visual'};
    varpart.rsq_adj = rsq_adj;
    varpart.rsq_tot = rsq_tot;
    varpart.comb_labels = vp.comb_labels;
    
else
    
    load(rdmfile,'subrdm'); 
    
    varpart = eeg_varpartcv(subrdm,sel_mod{1},sel_mod{2},sel_mod{3});

end

save(vpfile,'varpart');

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
