% combine video rating data from different video sets

%% set paths
clear; clc

basepath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_action/results/video_ratings';
stimpath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_stimuli';

videofile1 = fullfile(basepath,'ratings1','videoset_184.mat');
videofile2 = fullfile(basepath,'ratings2','videoset_307.mat');

videopath1 = fullfile(stimpath, 'initial_curation','set1');
videopath2 = fullfile(stimpath, 'initial_curation','set2');

savefile = fullfile(basepath,'videoset_full.mat');

load(videofile1); 
videolist1 = videolist_renamed; 
categories1 = categories; 
categories_idx1 = categories_idx; 
framearray1 = framearray_mid;
env1 = env; 
num_agents1 = num_agents; 
watermark1 = watermark; 
ratingsZ1 = ratingsZ;

%make sure there are no NaNs/zeros from combining the datasets previously
%(in the first set of ratings there are zeros where there should be NaNs, from concatenating the 2 video sets)
%remove the 2 participants that have only NaNs once that was taken into account (experiment glitch)
ratingsZ1(ratingsZ1==0) = NaN;
idxnan = find(squeeze(nansum(nansum(ratingsZ1,2),1))==0);
ratingsZ1(:,:,idxnan) = [];


load(videofile2); 
videolist2 = videolist; 
categories2 = categories; 
categories_idx2 = categories_idx; 
framearray2 = framearray;
env2 = env; 
num_agents2 = num_agents; 
watermark2 = watermark; 
ratingsZ2 = ratingsZ;

nvid = length(videolist1) + length(videolist2);
ncat = length(categories2); %the 2nd one contains all categories

framearray_mid = cell(1, nvid); 
videolist = cell(1, nvid); 
fullvideolist = cell(1, nvid);
env = nan(1, nvid); 
num_agents = nan(1, nvid); 
watermark = nan(1,nvid);
nrat1 = size(ratingsZ1,3); 
nrat2 = size(ratingsZ2,3);
ratingsZ = nan(4,nvid,nrat1+nrat2);
categories = categories2; 
categories_idx = cell(1,ncat);
categories1 = cellfun(@(x) strrep(x,' ', ''), categories1, 'UniformOutput',false); %remove spaces

cidx = 0;
for c = 1:ncat
    
    c1 = find(contains(categories1,categories2{c}));
    c2 = c;
    categories_idx{c} = [];
    
    if ~isempty(c1) %some missing categories in 1st set
        cat_idx1 = categories_idx1{c1};
        frameidx = cidx+1:cidx+length(cat_idx1);
        categories_idx{c} = frameidx;
        framearray_mid(frameidx) = framearray1(cat_idx1);
        videolist(frameidx) = videolist1(cat_idx1);
        fullvideolist(frameidx) = deal(fullfile(videopath1,videolist1(cat_idx1)));
        env(frameidx) = env1(cat_idx1);
        num_agents(frameidx) = num_agents1(cat_idx1);
        watermark(frameidx) = watermark1(cat_idx1);
        ratingsZ(:,frameidx,1:nrat1) = ratingsZ1(:,cat_idx1,:);
        cidx = cidx+length(cat_idx1);
    end
    
    cat_idx2 = categories_idx2{c2};
    frameidx = cidx+1:cidx+length(cat_idx2);
    categories_idx{c} = [categories_idx{c} frameidx];
    framearray_mid(frameidx) = framearray2(cat_idx2);
    videolist(frameidx) = videolist2(cat_idx2);
    fullvideolist(frameidx) = deal(fullfile(videopath2,videolist2(cat_idx2)));
    env(frameidx) = env2(cat_idx2);
    num_agents(frameidx) = num_agents2(cat_idx2);
    watermark(frameidx) = watermark2(cat_idx2);
    ratingsZ(:,frameidx,nrat1+1:nrat1+nrat2) = ratingsZ2(:,cat_idx2,:);
    cidx = cidx+length(cat_idx2);
    
    
end

save(savefile,'videolist','fullvideolist','framearray_mid','videolist','fullvideolist','categories','categories_idx','ratingsZ','rating_types','watermark','num_agents','env')
    
    
