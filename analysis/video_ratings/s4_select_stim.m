%script for subselecting videos based on lowest correlation between
%sociality & number of agents

clear; clc
addpath(pwd,'functions')
bdir = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_action';

%% Experiment 1

%balanced sampling
balanced = 1; %0 for random, 1 for balanced, 2 for proportional
nstim = 152; % 8 per category
niter = 10000;

loadpath = fullfile(bdir,'results/video_ratings');
loadfile = fullfile(loadpath, 'videoset_full.mat');
rsafile = fullfile(loadpath, 'rsamodels_full.mat');

%run randomization
results = select_stim_rand(loadfile,rsafile,nstim,niter,balanced);

% plot results
figure; plot_rdm(squeeze(results.mcorrs(:,:,results.idx_mincorr_soc)),results.modelnames,[],1,1); title(sprintf('Subset %d', results.idx_mincorr_soc))

% copy videos: get the set of videos with the lowest correlation and save them to a new file
results = load(savefile);
sub_idx = results.subset_idx(results.idx_mincorr_soc,:);
savefile = strrep(loadfile,'full',num2str(nstim));
loaddir = fullfile(bdir,'stimuli/full_set');
savedir = fullfile(bdir,'stimuli/exp1');

subsample_videos(sub_idx,loadfile,loaddir,savefile,savedir)

%% Experiment 2
balanced = 1; %0 for random, 1 for balanced, 2 for proportional
nstim = 76; %4 per category
niter = 10000;

% remove videos previously used from large dataset & get new models
vset = make_videoset_339(loadfile,savefile);
loadfile = fullfile(loadpath,'videoset_339.mat'); 
rsafile = fullfile(loadpath,'models_339.mat');
save(loadfile,'-struct','set')
sim_getrsamodels(loadfile,rsafile)

% run randomization on this set
results = select_stim_rand(loadfile,rsafile,nstim,niter,balanced);

% plot results
figure; plot_rdm(squeeze(results.mcorrs(:,:,results.idx_mincorr_soc)),results.modelnames,[],1,1); title(sprintf('Subset %d', results.idx_mincorr_soc))

% copy videos: get the set of videos with the lowest correlation and save them to a new file
results = load(savefile);
sub_idx = results.subset_idx(results.idx_mincorr_soc,:);
savefile = strrep(loadfile,'_339',num2str(nstim));

loaddir = fullfile(bdir,'stimuli/full_set');
savedir = fullfile(bdir,'stimuli/exp2');

subsample_videos(sub_idx,loadfile,loaddir,savefile,savedir)

% 11 more videos were manually removed: make a new 65-video videoset
subdatapath = fullfile(bdir,'stimuli/exp2');
subnames = dir(subdatapath);
subnames = {subnames(3:end).name}; %alphabetical order
if any(contains(subnames,'.DS')), subnames(contains(subnames,'.DS')) = []; end
nvid = numel(subnames);

respath = fullfile(bdir,'results/video_ratings');
v = load(fullfile(respath,'videoset_339.mat'));
idx = nan(nvid,1);
for i = 1:nvid
    idx(i) = find(contains(v.videolist,subnames{i})); %ensures proper indexing
end

%now subsample variables & models
action = v.action(idx);
allframes = v.allframes(idx);
arousal = v.arousal(idx);
env = v.environment(idx);
num_agents = v.numagents(idx);
ratingsZ = v.ratingsZ(:,idx,:);
sociality = v.sociality(idx);
valence = v.valence(idx);
watermark = v.watermark(idx);
videolist = subnames;
rating_types = v.rating_types;
categories = v.categories;
categories_idx = cell(1,numel(categories));
for i = 1:numel(categories)
    categories_idx{i} = find(contains(videolist,categories{i}));
end
subsample_idx = idx;

clear v i
save(fullfile(respath,'videoset_65.mat'),'-v7.3')
