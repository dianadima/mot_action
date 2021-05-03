function [] = plot_varpart(respath1, respath2)
%plot cross-validated variance partitioning results

figure

for i = 1:2 
    
    if i==1
        load(fullfile(respath1,'rsa_varpart.mat'),'varpart')
        load(fullfile(respath1,'rdm.mat'),'nc')
    else
        load(fullfile(respath2,'rsa_varpart.mat'),'varpart')
        load(fullfile(respath2,'rdm.mat'),'nc')
    end
    
vp = varpart.rsq_adj;
uv = vp([7 6 5],:); %reorder - get unique variance for models
labels = {'Visual','Social','Action'};

%noise ceilings calculated using different methods
if i==1
    ncK = (nc.splithalfKpairs).^2;
else
    ncK = (nc.splithalfK).^2;
end

%noise ceiling range - mean+/-SD
nc1 = mean(ncK)-std(ncK);
nc2 = mean(ncK)+std(ncK);

%Wilcoxon tests to compare the unique variances
p(1) = signrank(uv(1,:),uv(2,:));
p(2) = signrank(uv(2,:),uv(3,:));
p(3) = signrank(uv(1,:),uv(3,:));

%y limits
if i==1
    yl = [0 0.05];
else
    yl = [-0.05 0.3];
end

%%%%%%% plot results %%%%%%%

subplot(1,2,i)
hold on

rectangle('Position',[0.6 nc1 4 nc2-nc1],'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none')

cfg = []; 
cfg.scatter = 0; 
cfg.ylabel = 'Kendall`s tau-A^2';
cfg.color = {[0.2 0.6 0.8],[0.6 0.6 0.8],[0.3 0.7 0.5]};
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

end

end

