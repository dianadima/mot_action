function [models,modelnames] = sim_getrsamodels(videofile, modfile)
%create RSA models from video features & image properties
%Inputs: videofile, .mat file containing behavioral ratings, labels, & frames
%        modfile, file where models will be saved
%
% DC Dima 2020 (diana.c.dima@gmail.com)

%load video feature file
v = load(videofile);

%extract video frames if they are not present in the file
if ~isfield(v, 'allframes')
    
    stimpath = uigetdir(pwd,'Video directory'); %manually get the stimulus directory
    [~,~,~,allframes] = extract_movie_frames(stimpath, v.videolist, [], 0);
    v.allframes = allframes;
    v.stimpath = stimpath;
    save(videofile,'-v7.3','-struct','v'); %save updated video feature file
    
else
    
    allframes = v.allframes;
    stimpath = v.stimpath;
    
end

%% initialize
nmod = 17;                  %number of models
nvid = length(v.videolist); %number of videos

models = nan((nvid*(nvid-1))/2,nmod);
modelnames = cell(1,nmod);

%% low-level properties (HSV)

framesize = [size(allframes{1},1), size(allframes{1},2)];
HSV = nan(nvid,3,prod(framesize));
labels = {'Pixel Value','Hue','Saturation'};

%average properties across all frames
for i = 1:nvid
    
    vid = allframes{i};
    HSVtemp = nan(size(vid,4),3,prod(framesize));
    for ii = 1:size(vid,4)
        frame = squeeze(vid(:,:,:,ii));
        hsvmap = rgb2hsv(frame);
        hsvmap = permute(hsvmap,[3 1 2]);
        HSVtemp(ii,:,:) = hsvmap(:,:);
    end
    HSV(i,:,:) = nanmean(HSVtemp,1);
end


for m = 1:3
    models(:,m) = pdist(squeeze(HSV(:,m,:)));
    modelnames{m} = labels{m};
    fprintf('Created %s model...\n', modelnames{m})
end

%model counter
m = m+1;

%% presence of a watermark
models(:,m) = pdist(v.watermark(:));
modelnames{m} = 'Watermark';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% GIST descriptor
param.imageSize = framesize;
param.orientationsPerScale = [8 8 8 8]; % number of orientations per scale (from HF to LF)
param.numberBlocks = 4;
param.fc_prefilt = 4;

nfeat = sum(param.orientationsPerScale)*param.numberBlocks^2;

gist = zeros(nvid, nfeat);

for i = 1:nvid
    
    vid = allframes{i};
    gisttemp = nan(size(vid,4),nfeat);
    for ii = 1:size(vid,4)
        gisttemp(ii,:) = LMgist(squeeze(vid(:,:,:,ii)), '', param);
    end
    gist(i,:) = nanmean(gisttemp,1);
    
end

models(:,m) = pdist(gist);
modelnames{m} = 'Gist';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% environment
models(:,m) = pdist(v.env(:));
modelnames{m} = 'Environment';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% optic flow
fullvideolist = deal(fullfile(stimpath,v.videolist));
of = get_optic_flow(fullvideolist, framesize);
models(:,m) = pdist(of);

modelnames{m} = 'Optic flow';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% CNN
% extract Conv1 and FC8 activations from AlexNet
sel_layers = {'pool1','fc8'};
numlayers = numel(sel_layers);
cnnfeatures = cell(numel(sel_layers),1);

for i = 1:nvid
    [cnnvidfeatures,cnnlayers] = extract_cnn_features('alexnet',allframes{i},sel_layers);
    for l = 1:numlayers
        cnnfeatures{l}(i,:) = nanmean(cnnvidfeatures{l},1);
    end
end
cnnmodels = nan((nvid*(nvid-1))/2,numlayers);
for l = 1:numlayers
    cnnmodels(:,l) = pdist(cnnfeatures{l});
end

models(:,m:m+numlayers-1) = cnnmodels;
modelnames(m:m+numlayers-1) = cnnlayers;
fprintf('Created %s model...\n', modelnames{m})
m = m+numlayers;

%% action category
% binary action model
categ_idx = cell(size(v.categories_idx));
count = 0;
categ = zeros(nvid,nvid);
%assign maximal distances across categories,
%and minimal distances within categories
for c = 1:length(v.categories)
    idx = count+1:count+length(v.categories_idx{c});
    count = idx(end);
    exclidx = idx(end)+1:nvid;
    categ(idx, exclidx) = 1;
    categ(exclidx, idx) = 1;
    categ_idx{c} = idx;
end

%figure; imagesc(categ)

models(:,m) = categ(tril(true(size(categ)),-1));
modelnames{m} = 'Action category';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% effectors
models(:,m) = pdist(v.eff(:));
modelnames{m} = 'Effectors';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% number of agents
models(:,m) = pdist(v.num_agents(:));
modelnames{m} = 'Number of agents';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% ratings: sociality, transitivity, valence, arousal, action

%transitivity was collected separately
models(:,m) = pdist(v.obj(:));
modelnames{m} = 'Transitivity';
tidx = m; %save index of this model

%rating-based models
for mr = 1:4
    ratings = squeeze(nanmean(v.ratingsZ(mr,:,:),3))';
    models(:,mr+m) = pdist(ratings);
    if mr==4
        modelnames{mr+m} = 'Activity'; %rename 'action' ratings
    else
        modelnames{mr+m} = v.rating_types{mr};
    end
end

%swap sociality & transitivity for more logical ordering
models(:,[tidx tidx+1]) = models(:,[tidx+1 tidx]);
modelnames([tidx tidx+1]) = modelnames([tidx+1 tidx]);

nmod = size(models,2); %get final number of models

%% normalize all models
for m = 1:nmod
    models(:,m) = (models(:,m)-min(models(:,m)))/(max(models(:,m))-min(models(:,m)));
end

%% save
save(modfile,'models*','modelnames')
fprintf('\n...Saved and finished\n')

%% correlate & plot
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

save(modfile,'-append','mcorrS','mcorrK')


end

