% read and save transitivity ratings and effector labels to the 2 final stimulus set

%% Experiment 1

bdir = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_action';

% set paths
clear
basepath = fullfile(bdir,'data/video_ratings/ratings1');
frmepath = fullfile(basepath, 'frames'); 
stimpath = fullfile(basepath, 'Stimuli');
ctchpath = fullfile(basepath, 'catch');

savefile = fullfile(bdir,'results/video_ratings/ratings1/transitivity.mat'); %filename to svae
loadfile = 'Batch1.csv'; %preffix for raw data files
nfiles = 1; %number of raw data files
fidx = 1; %start from file #

%code
addpath(fullfile(pwd,'functions'))

% list stimuli
% get video names and make a list; create directories for extracted frames
if ~exist(frmepath,'dir'), mkdir(frmepath); end
if ~exist(ctchpath,'dir'), mkdir(ctchpath); end
v = dir(stimpath);
videolist = {v(4:end).name};
nvid = length(videolist);

filepath = fullfile(basepath,loadfile);

% read data
data = readmatrix(filepath,'OutputType','string');
nsub = size(data,1);
transitivity = nan(nvid,nsub);
rating_type = 'object';
sub_to_exclude = zeros(1,nsub); %index of subjects to remove based on QC

% get responses for each participant and assign to list

%find column indices
[~,idx] = find(contains(data,'catch_action')); idx_cth = unique(idx); %catch trials
[~,idx] = find(contains(data,'.mp4')); idx_vid = unique(idx); %video names
idx_rsp = idx_vid-1;  %responses
idx_fdb = idx_rsp-1;  %feedback
[~,idx] = find(contains(data,'object,')); idx_trl = unique(idx); %trial types

for isub = 1:nsub
    
    %find variables
    vid_list   = strsplit(data(isub,idx_vid),',','CollapseDelimiters',false)';
   % vid_list   = cellfun(@(x) x, vid_list, 'UniformOutput', false);
    trl_list   = strsplit(data(isub,idx_trl),',','CollapseDelimiters',false)';
    catch_resp = strsplit(data(isub,idx_cth),'},','CollapseDelimiters',false)';
    rate_resp  = strsplit(data(isub,idx_rsp),',','CollapseDelimiters',false)';
    feedback   = strsplit(data(isub,idx_fdb),',','CollapseDelimiters',false)';
    
    %extract frames and make array of frames for this subset
    % if isub==1
    %     movieframes = extract_movie_frames(stimpath, vid_list, frmepath);
    % else
         load(fullfile(frmepath,'videoframes.mat'),'framearray_first','stimuli');
         movieframes = cell(1,nvid);
         for iv = 1:nvid
             movieframes{iv} = framearray_first{contains(stimuli,vid_list{iv})};
         end
    % end
    % first recreate the full stimulus list
    catch_idx = find(contains(trl_list,'catch'));
    ntrl = length(trl_list);
    stim_list = cell(ntrl,1); stim_idx = nan(ntrl,1);
    count = 1;
    for s = 1:length(vid_list)
        stim_list{count} = vid_list(s); %1 trials per stimulus
        stim_idx(count) = s;
        count = count+1; %where the next group starts
        if ismember(count, catch_idx) %but if there's a catch we add 1
            stim_list{count} = vid_list(s);
            stim_idx(count) = s;
            count = count+1;
        end
    end
    
    % plot the catch videos and responses + feedback
    figure('color','w')
    fig = gcf;
    fig.Units = 'centimeters';
    fig.Position = [100 100 40 30];
    for icatch = 1:5
        subplot(2,3,icatch); imshow(movieframes{stim_idx(catch_idx(icatch))})
        respstr = strsplit(catch_resp(icatch),':');
        title(respstr(2),'FontWeight','normal','FontSize',18)
    end
    suptitle(feedback)
    print(fig,'-dpng',fullfile(ctchpath,sprintf('catch_sub%d', isub)))
    
    %plot histogram of overall responses to check for cheaters
    figure
    histogram(str2double(rate_resp)); title(sprintf('Ratings sub %d', isub))
    
    %at command line, flag subjects to exclude
    exclude_sub = input('Exclude subject? ');
    if ~isempty(exclude_sub), sub_to_exclude(isub) = 1; end
    
    close all
    
    %check for occasional glitch which leads to some responses not to be recorded
    if ntrl~=length(rate_resp)
        sub_to_exclude(isub) = 1;
        fprintf('\nOut of %d trials, %d responses recorded. Skipping...\n',ntrl,length(rate_resp));
    else
        
        % calculate the ratings
        resp_idx = find(contains(trl_list,rating_type));
        resp_stim = stim_list(resp_idx); %nicer to have a cell array
        resp_val = rate_resp(resp_idx); %the actual 56 responses
        
        for rs = 1:length(resp_stim)
            
            stim = resp_stim{rs};
            if iscell(stim), stim = strsplit(stim{1},'/'); else, stim = strsplit(stim, '/'); end
            vid_idx = contains(videolist,stim);
            transitivity(vid_idx,isub) = str2double(resp_val(rs)); %not allowed to be empty
            
        end
        
    end
    
    fprintf('\nSubject %d done...\n', isub)
    
end

%save results
save(savefile,'videolist','transitivity','sub_to_exclude','videolist');

sub_to_exclude(isnan(sub_to_exclude)) = 0;
transitivity(:,logical(sub_to_exclude)) = [];
transZ = (transitivity - nanmean(transitivity,1))./nanstd(transitivity,[],1); %z-score
% check reliability
looS = nan(size(transZ,2),1); looK = looS;
for is = 1:size(transZ,2)
    s = transZ(:,is);
    l = transZ;
    l(:,is) = [];
    l = mean(l,2);
    looS(is) = corr(s, l,'type','Spearman');
    looK(is) = rankCorr_Kendall_taua(s,l);
end
obj = mean(transZ,2);

save(savefile,'-append','loo*','transZ','obj')

%% Experiment 2
%load frames to check catch trials
stimfile = fullfile(bdir,'results/video_ratings/videoset_65.mat');
load(stimfile, 'allframes')

savefile = fullfile(bdir,'results/video_ratings/ratings2/transitivity.mat'); %filename to svae

nvid = numel(allframes);
exclude_idx = zeros(nsub,1);
transitivity = nan(nvid,nsub);

for isub = 1:nsub
    
    dsub = data{isub};
    
    dsub_hdr = dsub(1,:);
    dsub(1:3,:) = []; %remove 'instruction screen' trials + header
    
    type_idx = find(contains(dsub_hdr,'type'));
    catchtrl = find(contains(dsub(:,type_idx(2)),'catch'));
    
    stim_idx = find(contains(dsub_hdr,'stimulus'));
    catch_idx = find(contains(dsub_hdr,'responses'));
    resp_idx = find(contains(dsub_hdr,'response'),1);
    
    stimnum = cellfun(@(x) x(end-5:end-4), dsub(:,stim_idx), 'UniformOutput', false);
    stimnum = cellfun(@str2double, stimnum);
    
    figure
    for i = 1:numel(catchtrl)
        
        cstim = stimnum(catchtrl(i));
        cstr = dsub{catchtrl(i), catch_idx};
       
        subplot(2,3,i)
        imshow(squeeze(allframes{cstim}(:,:,:,1)));
        title(cstr(strfind(cstr,':')+1:end));
        
    end
      
    excl = input('Exclude subject? ');
    close
    if ~isempty(excl)
        exclude_idx(isub) = 1;
    else
        
        obj_idx = find(contains(dsub(:,type_idx(2)),'object')); %index excluding header
        obj_stim = stimnum(obj_idx);
        [~,sortidx] = sort(obj_stim,'ascend');
        
        trans = cell2mat(dsub(obj_idx,resp_idx));
        trans = trans(sortidx); %sort the responses
        
        figure; histogram(trans)
        excl2 = input('Exclude subject? ');
        close
        if ~isempty(excl2)
            exclude_idx(isub) = 1;
        else
          transitivity(:,isub) = trans;
        end
    end
end

transitivity(:,logical(exclude_idx)) = [];

save(savefile,'transitivity','exclude_idx')
        
transZ = (transitivity - nanmean(transitivity,1))./nanstd(transitivity,[],1); %z-score

%check reliability
looS = nan(size(transZ,2),1); looK = looS;
for is = 1:size(transZ,2)
    s = transZ(:,is);
    l = transZ;
    l(:,is) = [];
    l = mean(l,2);
    looS(is) = corr(s, l,'type','Spearman');
    looK(is) = rankCorr_Kendall_taua(s,l);
end
obj = mean(transZ,2);

save(savefile,'-append','transZ','looS','looK','obj')

%% add effectors & transitivity to both video sets to use in further analyses

vfiles = {fullfile(bdir,'results/video_ratings/videoset_152.mat'),...
        fullfile(bdir,'results/video_ratings/videoset_65.mat')};


eff_file = fullfile(bdir,'data/video_ratings/effectors.xlsx');
[~, sheets] = xlsfinfo(eff_file);

data = cell(2,1);
for s = 1:2
    [~,~,data{s}] = xlsread(eff_file,sheets{s});
end

%first set
eff_models = cell(2,1);
for s = 1:2
    
    sdata = data{s};
    idx = cellfun(@(x) strcmp(x,'NaN'), sdata);
    [sdata{idx}] = deal(0);
    eff = cell2mat(sdata(2:end,2:6));
    save(vfiles{s},'-append','eff');
    
end

trans_files = {fullfile(bdir,'results/video_ratings/ratings1/transitivity.mat'),...
    fullfile(bdir,'results/video_ratings/ratings2/transitivity.mat')};

%update stim paths
stim_paths = {fullfile(fileparts(bdir),'mot_stimuli/exp1'),...
    fullfile(fileparts(bdir),'mot_stimuli/exp2')};

for s = 1:2
    load(trans_files{s});
    transitivity = transZ;
    stimpath = stim_paths{s};
    save(vfiles{s}, '-append', 'transitivity','obj','stimpath');
end
    
%save video_features files
savepaths = {fullfile(bdir,'data/multiple_arrangement/exp1'),...
    fullfile(bdir,'data/multiple_arrangement/exp2')};
for s = 1:2
    
    load(vfiles{s});
    save(fullfile(savepaths{s},'video_features.mat'),'-v7.3','allframes','categories','categories_idx','env','eff',...
        'num_agents','obj','rating_types','ratingsZ','stimpath','videolist','watermark');
end



