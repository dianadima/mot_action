function [] = eeg_plotrsa(res, plotpath)
% plot subject-wise and average RSA results over time
nmod = numel(res.modelnames);

figure
sp = ceil(nmod/2);

for m = 1:nmod

    mcorr = squeeze(mean(res.subcorr(:,:,m),1));
    mcerr = squeeze(std(res.subcorr(:,:,m),[],1))/sqrt(size(res.subcorr,1));
    sig = time(res.pval(:,m)<0.005);
    
    subplot(2,sp,m)
    plot_time_results(mcorr,mcerr,'time',time,'chance',0,'ylim',[-0.1 0.1],'signif',sig,'signif_ylocation',-0.05);
    
    title(res.modelnames{m});
    
    xticks(res.cfg.analysis_window(1):0.2:res.cfg.analysis_window(end))
    set(gca,'FontSize',12)
    box off
    
    if ismember(m,[1 sp+1])
        if strcmp(res.cfg.type,'spearman')
            ylabel('Spearman`s rho')
        else
            ylabel('Kendall`s tau-A')
        end
    else
        ylabel([])
    end
    if m<sp+1
        xlabel([])
    end
    set(gca,'xgrid','on')
end
print(gcf,'-dpng','-r300',fullfile(plotpath,sprintf('subrsa_%s_%s',res.cfg.method,res.cfg.type)));

figure
for m = 1:nmod
    
    mcorr = squeeze(res.avgcorr(:,m));
    
    subplot(2,sp,m)
    hold on
    
    line(res.cfg.analysis_window, [0 0], 'color', [0.7 0.7 0.7])
    plot(res.time,mcorr,'k','LineWidth',1.5);
    
    ylim([-0.15 0.15])
    xlim(res.cfg.analysis_window)
    title(res.modelnames{m});
    set(gca,'FontSize',12)
    box off
    
    if ismember(m,[1 sp+1])
        if strcmp(res.cfg.type,'spearman')
            ylabel('Spearman`s rho')
        else
            ylabel('Kendall`s tau-A')
        end
    else
        ylabel([])
    end
    if m<sp+1
        xlabel([])
    end
end
print(gcf,'-dpng','-r300',fullfile(plotpath,sprintf('avgrsa_%s_%s',res.cfg.method,res.cfg.type)))




end

