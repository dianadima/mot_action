function [nc] = sim_reliability(rdm, fpath, ftitle, color)
% get and plot RDM reliability: leave-one-out/split half with different metrics
% adapted for RDM where different subjects saw different subsets of stimuli
% inputs: rdm (Nsub x Npairs OR NSub x NStim x NStim)
%         fpath, figure path
%         ftitle, figure title
%         color, raincloud plot color
% DC Dima 2020 (diana.c.dima@gmail.com)

nsub = size(rdm,1);
if ndims(rdm)==3
    rdmvec = nan(nsub,(size(rdm,2)*(size(rdm,2)-1))/2);
    for isub = 1:nsub
        r = squeeze(rdm(isub,:,:));
        rdmvec(isub,:) = r(tril(true(size(r)),-1));
    end
else
    rdmvec = rdm;
end

%initialize
looS = nan(nsub,1); looK = nan(nsub,1); %lower bound of noise ceiling (Spearman, Kendall)
uppS = nan(nsub,1); uppK = nan(nsub,1); %upper bound of noise ceiling (Spearman, Kendall)
looRsqOrd = nan(nsub,1); uppRsqOrd = nan(nsub,1); %upper bound of noise ceiling (R-squared)
looRsqAdj = nan(nsub,1); uppRsqAdj = nan(nsub,1); %lower bound of noise ceiling (R-squared)

for isub = 1:nsub
    
    %select the stimuli seen by this participant
    subrdm = rdmvec(isub,:);
    idx = ~isnan(subrdm);
    subrdm = subrdm(idx);
    
    %select the same stimuli & average all participants
    loordm = rdmvec(:,idx);
    allrdm = nanmean(loordm,1);

    %leave out participant and average the rest
    loordm(isub,:) = [];
    loordm = nanmean(loordm,1);
    
    %Spearman
    looS(isub) = corr(subrdm(:),loordm(:),'type','Spearman','rows','pairwise');
    uppS(isub) = corr(subrdm(:),allrdm(:),'type','Spearman','rows','pairwise');

    %Kendall's tau-A
    looK(isub) = rankCorr_Kendall_taua(subrdm(:),loordm(:));
    uppK(isub) = rankCorr_Kendall_taua(subrdm(:),allrdm(:));
    
    %R-squared
    lm = fitlm(loordm(:),subrdm(:));
    looRsqAdj(isub) = lm.Rsquared.Adjusted;
    looRsqOrd(isub) = lm.Rsquared.Ordinary;
    
    lm = fitlm(allrdm(:),subrdm(:));
    uppRsqAdj(isub) = lm.Rsquared.Adjusted;
    uppRsqOrd(isub) = lm.Rsquared.Ordinary;
    
end

%plot leave-one-out correlations
vec = [looS looK];
lbl = {'Spearman`s rho', 'Kendall tau-A'};

if isempty(color), color = [0.5 0.7 0.8]; end

for l = 1:2
    
    figure
    raincloud_plot(vec(:,l),'color', color,'box_on',1)
    set(gca,'FontSize',18)
    xlabel(lbl{l})
    yticks([])
    box off
    if ~isempty(ftitle), title(ftitle,'FontWeight','normal');end
    
    print(gcf,'-dpng','-r300', fullfile(fpath,strrep(['reliability_loo_' lbl{l}(1:9-l) '_' ftitle],' ', '_')))
end

%get split-half reliability
nperm = 1000;
splithalfS = nan(nperm,1);
splithalfK = nan(nperm,1);
nsamp = floor(nsub/2);
for p = 1:nperm
    
    idx = randperm(nsub,nsamp);
    rdm1 = rdmvec(idx,:);
    rdm1 = squeeze(nanmean(rdm1,1));
    rdm2 = rdmvec; rdm2(idx,:) = [];
    rdm2 = squeeze(nanmean(rdm2,1));
    splithalfS(p) = corr(rdm1(:),rdm2(:),'type','Spearman','rows','pairwise');
    splithalfK(p) = rankCorr_Kendall_taua(rdm1(:),rdm2(:));
end

%plot split-half reliability
vec = [splithalfS splithalfK];
for l = 1:2
    
    figure
    raincloud_plot(vec(:,l),'color', color,'box_on',1)
    set(gca,'FontSize',18)
    xlabel(lbl{l})
    yticks([])
    box off
    if ~isempty(ftitle), title(ftitle,'FontWeight','normal');end
    
    print(gcf,'-dpng','-r300', fullfile(fpath,strrep(['reliability_splithalf_' lbl{l}(1:9-l) '_' ftitle],' ', '_')))
end

%get pairwise split-half reliability (useful for Exp 1)
nperm = 1000;
splithalfSpairs = nan(nperm,1);
splithalfKpairs = nan(nperm,1);

%get number of ratings per pair
rdmnan = ~isnan(rdmvec);
rdmsum = squeeze(sum(rdmnan,1));
npairs = numel(rdmsum);

for p = 1:nperm
    
    rdm1 = nan(npairs,1); 
    rdm2 = nan(npairs,1);
    
    for ip = 1:npairs
        
        %draw a random half of ratings for this pair
        %there is a minimum of 2 ratings per pair
        idx = randperm(rdmsum(ip),floor(rdmsum(ip)/2));
        tmp = rdmvec(:,ip); %select the pair
        rdm1(ip) = nanmean(tmp(idx),1);
        tmp(idx) = [];
        rdm2(ip) = nanmean(tmp,1);
        
    end
    
    splithalfSpairs(p) = corr(rdm1,rdm2,'type','Spearman','rows','pairwise');
    splithalfKpairs(p) = rankCorr_Kendall_taua(rdm1,rdm2);

end

nc.looK = looK;
nc.looS = looS;
nc.uppK = uppK;
nc.uppS = uppS;
nc.splithalfK = splithalfK;
nc.splithalfS = splithalfS;
nc.splithalfKpairs = splithalfKpairs;
nc.splithalfSpairs = splithalfSpairs;
nc.looRsqAdj = looRsqAdj;
nc.looRsqOrd = looRsqOrd;
nc.uppRsqAdj = uppRsqAdj;
nc.uppRsqOrd = uppRsqOrd;
nc.rdmvec = rdmvec;


end

