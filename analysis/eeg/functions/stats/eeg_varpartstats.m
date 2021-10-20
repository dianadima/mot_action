function [vp] = eeg_varpartstats(vp)
% run cluster-corrected stats for variance partitioning analyses

nreg = 7; %number of regressions

if isfield(vp,'rsq_rnd') %fixed-effects case
    
    maxd = squeeze(max(vp.rsq_rnd,[],1)); %nperm x nwin
    nperm = size(maxd,1);
    
    obsd = vp.rsq_adj;
    
    pval = nan(size(obsd));
    obsd = repmat(obsd,1,1,nperm);
    
    for i = 1:nreg
        pval(i,:) = (sum(maxd>squeeze(obsd(i,:,:))')+1)/(nperm+1);
    end
    
    vp.stats.pvalcorr = pval; %omnibus-corrected
    
    clustersig = zeros(size(pval));
    clusterpval = cell(nreg,1);
    opt = []; 
    opt.alpha = 0.001;
    opt.clusteralpha = 0.05;
    opt.clusterstatistic = 'maxsize';
    rsq_rnd = squeeze(max(vp.rsq_rnd,[],1));
    for i = 1:nreg
        cluster = find2Dclusters(vp.rsq_adj(i,:), rsq_rnd,opt);
        if ~isempty(cluster.sigclusters)
            clustersig(i,:) = cluster.sigtime;
            clusterpval{i} = cluster.sigpvals;
        end
    end
    
    vp.stats.clustersig = clustersig;
    vp.stats.clusterpval = clusterpval;
        
    %differences between unique variance amounts
    uv = obsd([7 6 5],:,:);
    rd = vp.rsq_rnd([7 6 5],:,:);
    pvalcomp = nan(3,size(uv,2));
    idx = [1 2; 2 3; 1 3];
    for i = 1:3
        odiff = squeeze(uv(idx(i,1),:,:) - uv(idx(i,2),:,:))'; %nperm x nwin
        rdiff = squeeze(rd(idx(i,1),:,:) - rd(idx(i,2),:,:));
        pvalcomp(i,:) = (sum(abs(rdiff)>abs(odiff))+1)/(nperm+1);
    end
    
    vp.stats.pvalcomp = pvalcomp;
    
else %cross-validated case
    
    rsq = permute(vp.rsq_adj,[2 1 3]); %num sub first
    [pval,obs,rand,pvalcorr] = randomize_rho(rsq);
    
    rmax = squeeze(max(rand,[],2));
    clustersig = false(size(obs));
    clusterpval = cell(nreg,1);
    opt = []; 
    opt.alpha = 0.05;
    opt.clusterstatistic = 'maxsum';
    for i = 1:nreg
        cluster = find2Dclusters(obs(i,:),rmax,[]);
        if ~isempty(cluster.sigclusters)
            clustersig(i,:) = cluster.sigtime;
            clusterpval{i} = cluster.sigpvals; 
        end
    end
    
    vp.stats.pval = pval;
    vp.stats.pvalcorr = pvalcorr;
    vp.stats.clustersig = clustersig;
    vp.stats.clusterpval = clusterpval;
    
    %test differences between features
    uv = obs([7 6 5],:); 
    rv = rand(:,[7 6 5],:);
    idx = [1 2; 2 3; 1 3];
    
    comp_clustersig = false(size(uv));
    comp_clusterpval = cell(size(uv,1),1);
    
    for i = 1:size(uv,1)
        obsdiff = abs(squeeze(uv(idx(i,1),:,:)) - squeeze(uv(idx(i,2),:,:)));
        rnddiff = abs(squeeze(rv(:,idx(i,1),:)) - squeeze(rv(:,idx(i,2),:)));
        cluster = find2Dclusters(obsdiff, rnddiff,[]);
        if ~isempty(cluster.sigclusters)
            comp_clustersig(i,:) = cluster.sigtime;
            comp_clusterpval{i} = cluster.sigpvals;
        end  
    end
    
    vp.stats.compclustersig = comp_clustersig;
    vp.stats.compclusterpval = comp_clusterpval;
    
    %get onsets
    vp = eeg_varpartonsets(vp);
    
end

end