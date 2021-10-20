function [models, modelnames] = eeg_rsamodels(videofile, modfile)
% create model RDMs for EEG RSA/variance partitioning analysis

%extract or load frames here
v = load(videofile);
if ~isfield(v, 'allframes')
    
    stimpath = uigetdir(pwd,'Video directory');
    [~,~,~,allframes] = extract_movie_frames(stimpath, v.videolist, [], 0);
    save(videofile,'-append','allframes','stimpath');
    
else
    
    allframes = v.allframes;
    
end

%% initialize
nmod = 14;                  %number of models
nvid = length(v.videolist); %number of videos

models = nan((nvid*(nvid-1))/2,nmod);
modelnames = cell(1,nmod);
%m = 1; %model counter - for easy editing

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

%% environment
models(:,m) = pdist(v.env(:));
modelnames{m} = 'Environment';
fprintf('Created %s model...\n', modelnames{m})
m = m+1;

%% CNN
sel_layers = {'pool1','fc8'};
numlayers = numel(sel_layers);
cnnfeatures = cell(numel(sel_layers),1);

for i = 1:nvid
    [cnnvidfeatures,cnnlayers,~] = extract_cnn_features('alexnet',allframes{i},sel_layers);
    if i==1, numlayers = length(cnnlayers); end
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

%% number of agents
models(:,m) = pdist(v.num_agents(:));
modelnames{m} = 'Number of agents';
fprintf('Created %s model...\n', modelnames{m})

%% ratings: sociality, valence, arousal
%rating-based models
for mr = 1:3
    ratings = squeeze(nanmean(v.ratingsZ(mr,:,:),3))';
    models(:,mr+m) = pdist(ratings);
    modelnames{mr+m} = v.rating_types{mr};
end


%% action & transitivity
m = m+mr+1;
ratings = squeeze(nanmean(v.ratingsZ(mr+1,:,:),3))';
models(:,m) = pdist(ratings);
modelnames{m} = v.rating_types{mr+1};
m = m+1;

%transitivity was collected separately
models(:,m) = pdist(v.obj);
modelnames{m} = 'Transitivity';
m = m+1;

%% effectors - rdm already saved
models(:,m) = v.effector_rdm;
modelnames{m} = 'Effectors';
m = m+1;

%% action category
%action model
categ_idx = cell(size(v.categories_idx));
count = 0;
categ = zeros(nvid,nvid);
for c = 1:length(v.categories)
    idx = count+1:count+length(v.categories_idx{c});
    count = idx(end);
    exclidx = idx(end)+1:nvid;
    categ(idx, exclidx) = 1;
    categ(exclidx, idx) = 1;
    categ_idx{c} = idx;
end

models(:,m) = categ(tril(true(size(categ)),-1));
modelnames{m} = 'Action category';
fprintf('Created %s model...\n', modelnames{m})

%% normalize all models
nmod = size(models,2); %get final number of models
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
title('Spearman''s model correlations')

figure;plot_rdm(mcorrK,modelnames,[],0,1)
title('Kendall''s tau-A model correlations')

save(modfile,'-append','mcorrS','mcorrK')


end
























