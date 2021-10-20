function [] = sim_plotrsa(rsacorr,pval,fixedcorr,nc,modelnames,corrtype,color)
%plot RSA results
%Inputs: rsacorr, correlations between models and behavioral RDM (Nsub x Nmodels)
%        pval, pvalues corresponding to the correlations (Nmodels x 1)
%        fixedcorr, fixed-effects correlation between models and average behavioral RDM
%        nc, two-element vector containing lower & upper bound of noise ceiling
%        modelnames, cell array containing model names
%        corrtype, type of correlation for y-axis label
%        color, scatter plot colors (vector/cell array)
%
% DC Dima 2020 (diana.c.dima@gmail.com)

alpha = 0.005; %threshold p-values

nmod = numel(modelnames);

hold on
line([0.6 nmod+0.5], [nc(1) nc(1)],'LineWidth',2,'color',[0.85 0.85 0.85]);
rectangle('Position',[0.6 nc(1) nmod+1 nc(2)-nc(1)],'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none')
line([0 nmod+1], [0 0], 'color', 'k', 'LineWidth',2)

cfg = []; 
cfg.scatter = 0; 
cfg.ylabel = corrtype; 
if ~isempty(color), cfg.color = color; else, cfg.color = [0.5 0.5 0.5]; end
cfg.mrksize = 40;

boxplot_jitter_groups(rsacorr',modelnames,cfg) 
%plot(1:nmod,fixedcorr,'o','LineWidth',1,'MarkerEdgeColor','k','MarkerFaceColor',[0.9 0.9 0.9],'MarkerSize',10)
set(gca,'FontSize',18)
for m = 1:nmod
    if pval(m)<alpha
        text(m-0.05, 0.38, '*' ,'FontSize',14) %note: text position is hard-coded
    end
end

box off



end

