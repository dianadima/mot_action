function [] = plot_rsa(respath1, respath2, idx)
% plot behavior-feature RSA correlations for both experiments
% inputs: paths to directories containing rsa.mat results files for the two experiments
%         idx - feature ordering index

rpath = {respath1, respath2};

%colour grouping
c1 = [0.2 0.6 0.8]; %visual
c2 = [0.3 0.7 0.5]; %action
c3 = [0.6 0.6 0.8]; %social

% make a colour cell array for all feature RDMs
colour = cell(1,17); %17 feature models
colour(1:9) = {deal(c1)}; 
colour(10:13) = {deal(c2)}; 
colour(14:17) = {deal(c3)};


figure

for i = 1:2
    
    load(fullfile(rpath{i},'rsa.mat'),'Kendall','modelnames')
    
    %reorder variables for plotting
    rsacorr = Kendall.rsacorr(:,idx);  %individual RSA correlations
    pvalcor = Kendall.pvalcorr(:,idx); %omnibus-corrected p-values
    fixcorr = Kendall.avgcorr(idx);    %average RSA correlations
    nc = Kendall.noise_ceiling;        %noise ceiling range (lower and upper bounds)
    modelnames = modelnames(idx);
    corrtype = 'Kendall''s {\tau}_A';
    
    subplot(1,2,i)
    hold on
    
    sim_plotrsa(rsacorr,pvalcor,fixcorr,nc,modelnames,corrtype,colour)
    
    xtickangle(90)
    if i==2, ylabel(' '); end
    ylim([-0.2 0.4])
    title(sprintf('Exp %d',i),'FontWeight','normal')
    set(gca,'xgrid', 'on')
    
    %plot the fixed effects correlation separately for the 3 categories
  %  plot(1:9,fixcorr(1:9),'o','LineWidth',1,'MarkerEdgeColor','k','MarkerFaceColor',c1,'MarkerSize',10)
  %  plot(10:13,fixcorr(10:13),'o','LineWidth',1,'MarkerEdgeColor','k','MarkerFaceColor',c2,'MarkerSize',10)
  %  plot(14:17,fixcorr(14:17),'o','LineWidth',1,'MarkerEdgeColor','k','MarkerFaceColor',c3,'MarkerSize',10)
    
end
    
end    
    
    
    