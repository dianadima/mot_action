function [ratings,sub_to_exclude] = readdata_ratings(filepath, stimpath, nsub_idx, ratings, sub_to_exclude)

rating_types = {'social','valence','arousal','action'};

% read data
opts = detectImportOptions(filepath);
opts.Delimiter = '","';
opts.DataLines = [2 Inf];
opts.VariableNamesLine = 1;
data = readmatrix(filepath,opts,'OutputType','string');

nsub = size(data,1);

% get responses for each participant and assign to list

%find column indices
[~,idx] = find(contains(data,'catch_action')); idx_cth = unique(idx); %catch trials
[~,idx] = find(contains(data,'.mp4')); idx_vid = unique(idx); %video names
idx_rsp = idx_vid-1;  %responses
idx_fdb = idx_rsp-1;  %feedback
[~,idx] = find(contains(data,'viewing,')); idx_trl = unique(idx); %trial types

for isub = 1:nsub
    
    %find variables
    vid_list   = strsplit(data(isub,idx_vid),',','CollapseDelimiters',false)';
    vid_list   = cellfun(@(x) x(3:end), vid_list, 'UniformOutput', false);
    trl_list   = strsplit(data(isub,idx_trl),',','CollapseDelimiters',false)';
    catch_resp = strsplit(data(isub,idx_cth),'},','CollapseDelimiters',false)';
    rate_resp  = strsplit(data(isub,idx_rsp),',','CollapseDelimiters',false)';
    feedback   = strsplit(data(isub,idx_fdb),',','CollapseDelimiters',false)';
    
    %extract frames and make array of frames for this subset
    movieframes = extract_movie_frames(stimpath, vid_list, [],0);
    
    
    % first recreate the full stimulus list
    catch_idx = find(contains(trl_list,'catch'));
    ntrl = length(trl_list);
    stim_list = cell(ntrl,1); stim_idx = nan(ntrl,1);
    count = 1;
    for s = 1:length(vid_list)
        [stim_list{count:count+4}] = deal(vid_list(s)); %5 trials per stimulus
        stim_idx(count:count+4) = s;
        count = count+5; %where the next group starts
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
    %print(fig,'-dpng',sprintf('catch_sub%d', isub+nsub_idx))
    
    %plot histogram of overall responses to check for cheaters
    figure
    histogram(str2double(rate_resp)); title(sprintf('Ratings sub %d', isub+nsub_idx))
    
    %at command line, flag subjects to exclude
    exclude_sub = input('Exclude subject? ');
    if ~isempty(exclude_sub), sub_to_exclude(isub+nsub_idx) = 1; end
    
    close all
    
    %check for occasional glitch which leads to some responses not to be recorded
    if ntrl~=length(rate_resp)
        sub_to_exclude(isub+nsub_idx) = 1;
        fprintf('\nOut of %d trials, %d responses recorded. Skipping...\n',ntrl,length(rate_resp));
    else
        
        % calculate the ratings
        for r = 1:length(rating_types)
            
            resp_idx = find(contains(trl_list,rating_types{r}));
            resp_stim = stim_list(resp_idx); %nicer to have a cell array
            resp_val = rate_resp(resp_idx); %the actual 56 responses
            
            for rs = 1:length(resp_stim)
                
                stim = resp_stim{rs};
                if iscell(stim), stim = strsplit(stim{1},'/'); else, stim = strsplit(stim, '/'); end
                vid_idx = contains(videolist,stim(2));
                ratings(r,vid_idx,isub+nsub_idx) = str2double(resp_val(rs)); %not allowed to be empty
                
            end
            
        end
        
    end
    
    fprintf('\nSubject %d done...\n', isub)
    
end


end

