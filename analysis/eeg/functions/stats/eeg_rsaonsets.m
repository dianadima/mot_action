function [rsa_results] = eeg_rsaonsets(rsa_results)
% bootstrapping analysis of feature correlation onsets
% onsets are determined based on cluster-corrected sign permutation testing
% DC Dima 2021 (diana.c.dima@gmail.com)

rng(10)
rsacorr = rsa_results.subcorr;
time = rsa_results.time;

nboot = 1000;
nsub = size(rsacorr,1);
nmod = size(rsacorr,3);

onsets = nan(nboot,nmod);

for ib = 1:nboot
    
    idx = randi(nsub,nsub,1); %bootstrap with replacement
    rsaboot = rsacorr(idx,:,:);
    
    % sign permutation testing & cluster correction
    [~,obs,rand,~] = randomize_rho(rsaboot,'num_iterations',5000);
    opt.alpha = 0.05;
    opt.clusteralpha = 0.05;
    for imod = 1:nmod
        cluster = find2Dclusters(obs(:,imod),rand(:,:,imod),opt);
        if ~isempty(cluster.sigclusters)
            clustersig = cluster.sigtime;
            onsets(ib,imod) = time(find(clustersig,1));
        end
    end
end

rsa_results.onsets = onsets;

end

