% run RSA analysis on whole video set

%% paths and files
clear
addpath(fullfile(pwd,'functions'))
addpath(genpath(fullfile(fileparts(pwd),'utils')))

%where to load data and store results
analysispath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_action/results/video_ratings';

loadfile = fullfile(analysispath,'videoset_full.mat');
savefile = fullfile(analysispath,'rsamodels_full.mat');

%% get models
[models, modelnames] = get_rsa_models(loadfile,savefile); 

%% plot models
load(loadfile,'categories','categories_idx')
plot_rsa_models(models,modelnames,'Model RDMs',categories, categories_idx)

%% model corrs
nmod = numel(modelnames);
mcorrS = corr(models,'type','Spearman','rows','pairwise');
mcorrK = nan(nmod,nmod);
for i = 1:nmod
    mcorrK(i,i) = 1;
    for j = i+1:nmod
        mcorrK(i,j) = rankCorr_Kendall_taua(models(:,i),models(:,j));
        mcorrK(j,i) = mcorrK(i,j);
    end
end

figure;plot_rdm(mcorrS,modelnames,[],0,1)
title('Spearman`s model correlations')

figure;plot_rdm(mcorrK,modelnames,[],0,1)
title('Kendall`s tau-A model correlations')
save(savefile,'-append','mcorr*')
