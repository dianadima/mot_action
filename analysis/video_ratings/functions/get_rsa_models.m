function [models,modelnames] = get_rsa_models(videofile,modfile)

%extract or load frames here
v = load(videofile);
if ~isfield(v, 'allframes')
    
    stimpath = uigetdir(pwd,'Video directory');
    [~,~,~,allframes] = extract_movie_frames(stimpath, v.videolist, [], 0);
    v.allframes = allframes;
    v.stimpath = stimpath;
    save(videofile,'-v7.3','-struct','v');
    
else
    
    allframes = v.allframes;
    stimpath = v.stimpath;
    
end

%% initialize
nmod = 15;                  %number of models
nvid = length(v.videolist); %number of videos
    
models = nan((nvid*(nvid-1))/2,nmod);
modelnames = cell(1,nmod);

%% low-level properties
    %HSV - hue, sat, value
    framesize = [size(allframes{1},1), size(allframes{1},2)];
    HSV = nan(nvid,3,prod(framesize));
    labels = {'Pixel Value','Hue','Saturation'};
    
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
    
    m = m+1;
    
    %% watermark
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
    of = get_optic_flow(fullvideolist, 0.1*framesize);  
    models(:,m) = pdist(of);
    
    modelnames{m} = 'Optic flow';
    fprintf('Created %s model...\n', modelnames{m})
    m = m+1;
    
    %% CNN
    sel_layers = {'conv1','fc8'};
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
    
    %figure; imagesc(categ)
    
    models(:,m) = categ(tril(true(size(categ)),-1));
    modelnames{m} = 'Action category';
    fprintf('Created %s model...\n', modelnames{m})
    m = m+1;
    
    %% number of agents
    models(:,m) = pdist(v.num_agents(:));
    modelnames{m} = 'Number of agents';
    fprintf('Created %s model...\n', modelnames{m})
    
    %% ratings: sociality, transitivity, valence, arousal, action
    
    %rating-based models
    for mr = 1:4
        ratings = squeeze(nanmean(v.ratingsZ(mr,:,:),3))';
        models(:,mr+m) = pdist(ratings);
        modelnames{mr+m} = v.rating_types{mr};
    end
    
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

