function [varpart] = eeg_varpartonsets(varpart)
% analysis of variance partitioning effect onsets 
% across 100 split-half iterations

nreg = size(varpart.rsq_adj,1);
nitr = 100;

%get onsets for the split-half iterations
rsq = permute(varpart.rsq_adj,[2 1 3]);
[~,~,rand,~] = randomize_rho(rsq);
rmax = squeeze(max(rand,[],2));

opt = [];
opt.alpha = 0.05;

onsets = nan(nitr,nreg);

for it = 1:nitr
    for i = 1:nreg
        cluster = find2Dclusters(squeeze(rsq(it,i,:)),rmax,[]);
        if ~isempty(cluster.sigclusters)
            clustersig = cluster.sigtime;
            if ~isempty(find(clustersig,1))
                onsets(it,i) = vp.time(find(clustersig,1));
            end
        end
    end
end

varpart.onsets = onsets;

end

