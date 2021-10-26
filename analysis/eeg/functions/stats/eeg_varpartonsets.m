function [varpart] = eeg_varpartonsets(varpart)
% analysis of variance partitioning effect onsets across 100 split-half iterations
% based on cluster-corrected sign permutation testing
% DC Dima 2021 (diana.c.dima@gmail.com)

nreg = size(varpart.rsq_adj,1); %number of regressions
nitr = 100; %number of CV iterations

%get onsets for the split-half iterations
rsq = permute(varpart.rsq_adj,[2 1 3]); %permute dimensions
[~,~,rand,~] = randomize_rho(rsq);      %sign permutation
rmax = squeeze(max(rand,[],2));         %take max across regressions

%cluster correction
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

