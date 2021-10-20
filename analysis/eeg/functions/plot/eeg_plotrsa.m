function [] = eeg_plotrsa(res, plotpath)
% plot RSA results over time + feature correlation onsets

nmod = numel(res.modelnames);

ncupp = mean(res.nc.low,1)+std(res.nc.low,[],1)/sqrt(size(res.nc.low,1));
nclow = mean(res.nc.low,1)-std(res.nc.low,[],1)/sqrt(size(res.nc.low,1));

%individual plots
for m = 1:nmod

    figure
    hold on

    l = patch([res.time fliplr(res.time)], [ncupp fliplr(nclow)], [0.4 0.7 0.8],'EdgeColor', 'none');
    hasbehavior(l, 'legend', false);
    
    mcorr = squeeze(mean(res.subcorr(:,:,m),1));
    mcerr = squeeze(std(res.subcorr(:,:,m),[],1))/sqrt(size(res.subcorr,1));
    sig = res.time(logical(res.clustersig(:,m)));

    plot_time_results(mcorr,mcerr,'time',res.time,'chance',0,'ylim',[-0.05 0.21],'signif',sig,'signif_ylocation',-0.02,'legend',res.modelnames{m});

    xticks(res.cfg.analysis_window(1):0.2:res.cfg.analysis_window(end))
    set(gca,'FontSize',18)
    box off
 
    if strcmp(res.cfg.type,'spearman')
        ylabel('Spearman''s {\rho}')
    else
        ylabel('Kendall''s {\tau}_A')
    end

    set(gca,'xgrid','on')
    
    if ~isempty(plotpath)
        print(gcf,'-dpng','-r300',fullfile(plotpath,sprintf('rsa_%s_%s_%s',res.modelnames{m},res.cfg.method,res.cfg.type)));
        print(gcf,'-dtiff','-r300',fullfile(plotpath,sprintf('rsa_%s_%s_%s',res.modelnames{m},res.cfg.method,res.cfg.type)));
    end
end

% plot onsets - only for models that correlate
idx = [11 12 2 1 10 9 8 7 5 6 3]; %model RDM order
onsets = res.onsets(:,idx);
modelnames = res.modelnames(:,idx);
colors = [0.6 0.6 0.6; repmat([0.2 0.6 0.8],3,1); repmat([0.3 0.7 0.5],4,1); repmat([0.6 0.6 0.8],3,1)];

figure
hold on

%get 90% CIs to plot
for i = 1:11
    ons = onsets(:,i);
    onsci = prctile(ons, [5 95]);
    rectangle('Position',[onsci(1) i-0.25 onsci(2) 0.5],'FaceColor',[colors(i,:) 0.5],'EdgeColor','none');
    g(i,:) = ~isnan(ons); %#ok<AGROW>
end

h = boxplot(onsets,1:11,'Colors','k','Symbol','','Orientation','horizontal');

set(h,{'linew'},{2});
box off
set(gca,'TickLength',[0.001 0.001])
set(gca,'FontSize',18)
ylim([0 12])
xlabel('Time (s)')
yticklabels(modelnames)
set(gca,'xgrid','on')
xlim([-0.2 1])
xticks(0:0.2:1)


end

