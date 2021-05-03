function [] = sim_varpart(rdmfile,modelfile,vpfile, exp)
%variance partitioning analysis
%input: rdmfile, file with RDM and noise ceiling
%       modelfile, file with RSA models
%       vpfile, file with results to be saved
%       exp, experiment number (1 or 2), determines cross-validation scheme

%load files
load(rdmfile,'nc'); rdm = nc.rdmvec;
load(modelfile,'models','modelnames')

%group models and select
mod1 = {'Action category','Action','Transitivity','Effectors'};
mod2 = {'Number of agents','Sociality','Valence','Arousal'};
mod3 = {'FC8','Environment'};
mod = {mod1,mod2,mod3};
sel_mod = sim_prepmodels(mod,models,modelnames);

%run variance partitioning
varpart = rdm_varpart_cv(rdm,sel_mod{1},sel_mod{2},sel_mod{3},exp);
varpart.modelnames = {'Semantic','Social','Visual'};

save(vpfile,'varpart');

comb_idx = [5 2 6 3 7 4 1];
%vp = varpart.avg.rsq_adj(comb_idx)*100;
vp = mean(varpart.rsq_adj(comb_idx,:),2)*100;
vennX(vp,1/100);

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

