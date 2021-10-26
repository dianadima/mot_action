function [] = plot_varpart(respath1, respath2)
% plot cross-validated variance partitioning results
% inputs: paths to directories containing rsa_varpart.mat files for the two experiments

rng(10) %reproducible
respath = {respath1, respath2};
filename = 'rsa_varpart.mat';
figure

for i = 1:2 
    
    load(fullfile(respath{i},filename),'varpart')
     
    %two variable naming conventions
    try
        vp = varpart.rsq_adj;
    catch
        vp = varpart.var_exp;
    end
    
    %check which are above chance
    [~,~,~,pval_corr] = randomize_rho(vp');
    
    %reorder & get unique variance for models
    uv = vp([7 5 6],:); 
    labels = {'Visual','Action','Social'};
    
    %true correlation mean+/- SD
    try
        ncK = varpart.true_rsq;
    catch
        ncK = varpart.var_true;
    end
    
    nc1 = mean(ncK)-std(ncK);
    nc2 = mean(ncK)+std(ncK);
    
    %Wilcoxon tests to compare the unique variances
    [p(1),~,stats(1)] = signrank(uv(1,:),uv(2,:));
    [p(2),~,stats(2)] = signrank(uv(2,:),uv(3,:));
    [p(3),~,stats(3)] = signrank(uv(1,:),uv(3,:));
    
    %set y limits
    if i==1
        yl = [0 0.05];
    else
        yl = [-0.05 0.3];
    end
    
    %%%%%%% plot results %%%%%%%
    
    subplot(1,2,i)
    hold on
    
    rectangle('Position',[0.55 nc1 4 nc2-nc1],'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none')
    
    cfg = [];
    cfg.scatter = 0;
    if i==1
        cfg.ylabel = 'Kendall''s {\tau}_A^2';
    else
        cfg.ylabel = ' ';
    end
    cfg.color = {[0.2 0.6 0.8],[0.3 0.7 0.5],[0.6 0.6 0.8]};
    cfg.mrksize = 60;
    
    boxplot_jitter_groups(uv ,labels,cfg)
    set(gca,'FontSize',18)
    ylim(yl)
    xtickangle(90)
    set(gca,'xgrid','on')
    title(sprintf('Exp %d', i),'FontWeight','normal')
    
    %where to plot the significance lines
    if i==1, xp = 0.033; else, xp = 0.18; end
    if p(1)<0.01
        line([1 2],[xp xp], 'color','k')
        text(1.45, xp+xp/100*2,'*','FontSize',12)
    end
    if p(2)<0.01
        line([2 3],[xp+xp/100*5 xp+xp/100*5], 'color','k')
        text(2.45, xp+xp/100*7,'*','FontSize',12)
    end
    if p(3)<0.01
        line([1 3],[xp+xp/10 xp+xp/10], 'color','k')
        text(1.95, xp+xp/100*12,'*','FontSize',12)
    end
    
    %save pvalues
    pval_Wilc = p;
    stat_Wilc = stats;
    pval_Rand = pval_corr;
    
    save(fullfile(respath{i},filename),'-append','pval_Wilc','pval_Rand','stat_Wilc');
    
    
end

end

