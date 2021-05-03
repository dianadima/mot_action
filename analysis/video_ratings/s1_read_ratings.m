% read video rating data from mTurk
% exclude participants based on catch trials
% exclude videos based on inter-subject variability

%% set paths
clear

%change for each set

basepath = fileparts(fileparts(pwd));

datapath = fullfile(basepath, 'data','video_ratings','ratings2');
stimpath = fullfile(basepath, 'stimuli');
savepath = fullfile(basepath, 'analysis', 'results');

savefile = 'videoresponses.mat'; %filename to svae
loadile = 'Batch'; %preffix for raw data files
nfiles = 26; %number of raw data files
fidx = 1; %start from file #

%code
addpath(fullfile(pwd,'functions'))

%% list stimuli
% get video names and make a list
[videolist,categories,categories_idx] = list_stimuli(stimpath);
nvid = length(videolist);
%% read data

rating_types = {'social','valence','arousal','action'};

for f = fidx:nfiles %csv files
    
    filename = sprintf('Batch%d.csv',f);
    filepath = fullfile(datapath,filename);
    nsub = size(data,1);
    
    if f==1 %create results variables for first file
   
        sub_to_exclude = zeros(1,nsub); %index of subjects to remove based on QC
        ratings = nan(4,nvid,nsub);
        nsub_idx = 0;
        
    else %append resuilts to existing ones
        
        load(fullfile(savepath,savefile));
        
        % for combining batches
        nsub_idx = size(ratings,3); %these subjects will be added to the matrix with this starting point
        
        ratings(:,:,nsub_idx+1:nsub_idx+nsub) = NaN;
        sub_to_exclude(nsub_idx:nsub_idx+nsub) = NaN;
        
    end
    
    [ratings, sub_to_exclude] = readdata_ratings(filepath, stimpath, nsub_idx, ratings, sub_to_exclude);
    
    %save results
    if ~exist(fullfile(savepath,savefile),'file')
        save(fullfile(savepath,savefile),'videolist','ratings','rating_types','sub_to_exclude','videolist','categories','categories_idx');
    else
        save(fullfile(savepath,savefile),'-append','ratings','sub_to_exclude');
    end
    
end

%% read and append manually assigned labels
labels = readtable(fullfile(datapath,'videoset2labels.xlsx'));
watermark = table2array(labels(:,2));
num_agents = table2array(labels(:,3));
env = table2array(labels(:,4));

save(fullfile(savepath,savefile),'-append','watermark','num_agents','env')

%% make a large array of first frames for all videos
framearray = extract_movie_frames(stimpath, videolist, [],0);
save(fullfile(savepath,savefile),'-append','framearray')

%% analyse and plot ratings

%load, Z-score and check the number of ratings per video
load(fullfile(savepath, savefile))

%exclude bad subjects
sub_to_exclude(isnan(sub_to_exclude)) = 0;
ratingsE = ratings; 
ratingsE(:,:,logical(sub_to_exclude)) = [];

%z-score ratings
ratingsZ = (ratingsE - nanmean(ratingsE,2))./nanstd(ratingsE,[],2); %z-score

numratings = sum(~isnan(squeeze(ratingsE(1,:,:))),2);
figure; histogram(numratings)
  
%calculate ratings per video and ratings per subject
rating_types = {'Sociality','Valence','Arousal','Action'}; %nicer labels
ncat = length(categories);
nrat = length(rating_types);
nsub = size(ratingsZ,3);
nvid = length(videolist);

sub_rating_meansZ = nan(nrat,ncat,nsub);
vid_rating_meansZ = nan(nrat,ncat,30); %max number of vid per categ

for r = 1:length(rating_types)
    
    s_rating_meansZ = nan(ncat,nsub);
    v_rating_meansZ = nan(ncat,21);

    for c = 1:ncat
        cidx = categories_idx{c};
        s_rating_meansZ(c,:) = nanmean(squeeze(ratingsZ(r,cidx,:)),1);
        v_rating_meansZ(c,1:length(cidx)) = nanmean(squeeze(ratingsZ(r,cidx,:)),2);
    end
    
    figure; boxplot_jitter_groups(s_rating_meansZ,categories,sprintf('%s ratings per subject', rating_types{r}))
    print(gcf,'-dpng','-r300',fullfile(savepath, sprintf('%s_ratings_per_subjectZ',rating_types{r})))
    pause(1); close
    
    figure; boxplot_jitter_groups(v_rating_meansZ,categories,sprintf('%s ratings per video', rating_types{r}))
    print(gcf,'-dpng','-r300',fullfile(savepath, sprintf('%s_ratings_per_videoZ',rating_types{r})))
    pause(1); close
    
    sub_rating_meansZ(r,:,:) = s_rating_meansZ;
    vid_rating_meansZ(r,:,:) = v_rating_meansZ;
end
    
%append results
save(fullfile(savepath,savefile),'-append','sub_rating_meansZ','vid_rating_meansZ','ratingsZ','rating_types');

%% plot Z-score histograms for each action category

for r = 1:nrat
    
    figure
    f = gcf;
    f.Units = 'centimeters';
    f.Position = [100 100 40 30];
    f.PaperUnits = 'centimeters';
    f.PaperPosition = [100 100 40 30];
    for c = 1:ncat
        subplot(4,5,c)
        histogram(squeeze(sub_rating_meansZ(r,c,:)),'BinMethod','integers','FaceColor',[0.7 0.7 0.7])
        xlim([-2.5 2.5])
        set(gca,'FontSize',16)
        title(strrep(categories{c},'_',' '),'FontWeight','normal')
    end
    suptitle(sprintf('%s ratings',rating_types{r}))
    print(gcf,'-dpng','-r300',fullfile(savepath, sprintf('%s_ratings_histogramsZ',rating_types{r})))
end

%% plot sociality vs number of agents

cd(savepath)
scatter_ci(squeeze(nanmean(ratingsZ(1,:,:),3))',num_agents,'Mean sociality z-score', 'Number of agents')   

for i = 1:ncat
    r = squeeze(vid_rating_meansZ(1,i,:)); r(r==0) = NaN;
    scatter_ci(r(~isnan(r)),num_agents(categories_idx{i}), [strrep(categories{i},'_',' ') ' sociality z-score'], 'Number of agents')
end
   
%% select stimuli with low inter-subject agreement and exclude them

SDrat = nanstd(ratingsZ,[],3);
 
%plot the mean SD across categories
catstd = nan(4,ncat);
for c = 1:ncat
    catstd(:,c) = squeeze(nanmean(nanmean(SDrat(:,categories_idx{c},:),3),2));
end
figure;plot(1:ncat,catstd);legend(rating_types);xticks(1:ncat);xticklabels(categories)
figure;plot(1:ncat,mean(catstd,1));legend(rating_types);xticks(1:ncat);xticklabels(categories)

%index of videos to remove (2SD above mean SD)
[~,rmvid] = find(SDrat>=(nanmean(SDrat(:))+nanstd(SDrat(:))*2));
rmvid = unique(rmvid);

%plot outlier videos and create new categories_idx with these videos removed
categories_sub = categories_idx;
figure
for v = 1:length(rmvid)
    
     vididx = rmvid(v);
    
    subplot(6,6,v)
    imshow(framearray{vididx})
    title(sprintf('%s %d',videolist{vididx}, vididx))
end

print(gcf,'-dpng','-r300',fullfile(savepath, 'outlier_videos'))


%just remove the videos
videolist(rmvid) = [];
env(rmvid) = [];
watermark(rmvid) = [];
num_agents(rmvid) = [];
ratingsZ(:,rmvid,:) = [];
framearray(rmvid) = [];

%final action category index for new list
for c = 1:length(categories)
    categories_idx{c} = find(contains(videolist,categories{c}));
end

save(fullfile(savepath, 'videoset_307.mat'),'videolist','categories*','env','num_agents','watermark','rmvid','framearray*','ratingsZ','rating_types')
