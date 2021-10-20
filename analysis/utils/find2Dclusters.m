function cl2Dstats = find2Dclusters(obs_stat,r_stat,opt)
%find clusters in 2D data; one-sided test

try clusteralpha = opt.clusteralpha; catch, clusteralpha = 0.05; end
try alpha = opt.alpha; catch, alpha = 0.005; end
try clusterthresh = opt.clusterthresh; catch, clusterthresh = 'individual'; end
try clusterstatistic = opt.clusterstatistic; catch, clusterstatistic = 'maxsum'; end


if isvector(obs_stat), obs_stat = obs_stat(:); end

num_it = size(r_stat,1);
prc = 100* (1 - clusteralpha); %get cluster-setting percentile
if strcmp(clusterthresh, 'individual')
    thresh = prctile(r_stat,prc,1); %individual threshold setting, as in FT nonparametric_individual option
    o_thresh = squeeze(thresh); 
    if isvector(o_thresh), o_thresh = o_thresh(:); end
    obs_map = double(obs_stat>=o_thresh);
    if ismatrix(r_stat), r_thresh = repmat(thresh,num_it,1); elseif ndims(r_stat)==3, r_thresh = repmat(thresh,num_it,1,1); end
    r_map = double(r_stat>=r_thresh); %ones for values that should go in the clusters
elseif strcmp(clusterthresh,'common') %common threshold across sensors/sources/timepoints
    thresh = prctile(r_stat(:),prc);
    obs_map = double(obs_stat>=thresh);
    r_map = double(r_stat>=thresh);
end
max_r_cls = zeros(1,num_it); %maximal cluster statistic distribution

%here we are simply looking for clusters w/o spatial  structure
conn = conndef(ndims(obs_map),'max'); %use maximal structure as diagonal points belong to same cluster (e.g. temporal generalization)
obs_cls = bwconncomp(obs_map,conn);

for i = 1:num_it
    
    r_map_ = squeeze(r_map(i,:,:));
    r_cls =  bwconncomp(r_map_,conn);
    r_stat_ = squeeze(r_stat(i,:,:)); 
    if isvector(r_stat_), r_stat_ = r_stat_(:); end
    
    %get the maximal statistic distribution
    if ~isempty(r_cls.PixelIdxList) && strcmp(clusterstatistic,'maxsize')
        max_r_cls(i) = max(cellfun(@length,r_cls.PixelIdxList));
    elseif ~isempty(r_cls.PixelIdxList) && strcmp(clusterstatistic,'maxsum')
        tmp_cls = nan(1,length(r_cls.PixelIdxList));
        for ii = 1:length(r_cls.PixelIdxList)
            tmp_cls(ii) = sum(r_stat_(r_cls.PixelIdxList{ii}));
        end
        max_r_cls(i) = max(tmp_cls);
    elseif ~isempty(r_cls.PixelIdxList) && strcmp(clusterstatistic,'max')
        tmp_cls = nan(1,length(r_cls.PixelIdxList));
        for ii = 1:length(r_cls.PixelIdxList)
            tmp_cls(ii) = max(r_stat_(r_cls.PixelIdxList{ii}));
        end
        max_r_cls(i) = max(tmp_cls);
    elseif ~isempty(r_cls.PixelIdxList) && strcmp(clusterstatistic,'wcm')
        tmp_cls = nan(1,length(r_cls.PixelIdxList));
        for ii = 1:length(r_cls.PixelIdxList)
            if strcmp(clusterthresh,'individual')
                t = o_thresh(r_cls.PixelIdxList{ii});
            else
                t = thresh;
            end
            tmp_cls(ii) = sum((r_stat_(r_cls.PixelIdxList{ii})-t).^1);
        end
        max_r_cls(i) = max(tmp_cls);
    end
end

%now compare observed with random clusters
if strcmp(clusterstatistic,'maxsize')
    obs_clstat = cellfun(@length, obs_cls.PixelIdxList);
    if ~isempty(obs_clstat)
        cluster_pvals = nan(1,length(obs_clstat));
        for i = 1:length(obs_clstat)
            cluster_pvals(i) = ((sum(max_r_cls>=obs_clstat(i)))+1)/(num_it+1);
        end
    else
        cluster_pvals = NaN;
    end
elseif strcmp(clusterstatistic,'maxsum')
    cluster_pvals = nan(1,length(obs_cls.PixelIdxList));
    obs_clstat = cluster_pvals;
    for i = 1:length(obs_cls.PixelIdxList)
        obs = obs_stat(obs_cls.PixelIdxList{i});
        obs_clstat(i) = sum(obs);
        cluster_pvals(i) = ((sum(max_r_cls>=obs_clstat(i)))+1)/(num_it+1);
    end
elseif strcmp(clusterstatistic,'max')
    cluster_pvals = nan(1,length(obs_cls.PixelIdxList));
    obs_clstat = cluster_pvals;
    for i = 1:length(obs_cls.PixelIdxList)
        obs = obs_stat(obs_cls.PixelIdxList{i});
        obs_clstat(i) = max(obs);
        cluster_pvals(i) = ((sum(max_r_cls>=obs_clstat(i)))+1)/(num_it+1);
    end
elseif strcmp(clusterstatistic,'wcm')
    cluster_pvals = nan(1,length(obs_cls.PixelIdxList));
    obs_clstat = cluster_pvals;
    for i = 1:length(obs_cls.PixelIdxList)
        obs = obs_stat(obs_cls.PixelIdxList{i});
        if strcmp(clusterthresh,'individual')
            t = o_thresh(obs_cls.PixelIdxList{i});
        else
            t = thresh;
        end
        obs_clstat(i) = sum((obs(:)-t(:)).^1);
        cluster_pvals(i) = ((sum(max_r_cls>=obs_clstat(i)))+1)/(num_it+1);
    end
end

%save stuff
fprintf('\nSaving...')
cl2Dstats.clusters = obs_cls.PixelIdxList;
cl2Dstats.clusterstat = obs_clstat;
cl2Dstats.clusterpvals = cluster_pvals;
cl2Dstats.randclusterstatmax = max_r_cls;
cl2Dstats.sigclusters = cl2Dstats.clusters(cl2Dstats.clusterpvals<=alpha);
cl2Dstats.sigpvals = cl2Dstats.clusterpvals(cl2Dstats.clusterpvals<=alpha);

%save an indexing vector for time-resolved data
if isvector(obs_stat)
    cl2Dstats.sigtime = zeros(1,length(obs_stat));
    tpidx = cat(1,cl2Dstats.clusters{cl2Dstats.clusterpvals<=alpha});
    cl2Dstats.sigtime(tpidx) = 1;
end
end


