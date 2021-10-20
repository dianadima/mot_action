function [] = eeg_ploterp(timelock, sub, figpath)
%plot the topography and global field power/EEG timecourses
%for averaged event-related responses (action perception experiment)
% D.C. Dima (diana.c.dima@gmail.com) Feb 2020

%time window of interest
toi = [-0.2 1];

%get the colorbar limits from the timelock data
zmin = min(min(timelock.avg));
zmax = max(max(timelock.avg));

%% topoplot
cfg = [];
cfg.layout = 'acticap-64ch-standard2';
cfg.xlim = toi(1):0.2:toi(2);
cfg.avgovertime = 'yes';
cfg.zlim = [zmin zmax];
cfg.comment = 'xlim';
cfg.commentpos = 'title';
try
    cfg.colormap = viridis;
catch
    cfg.colormap = 'parula';
end

figure
ft_topoplotER(cfg,timelock)

%add colorbar
pos = get(gca,'Position');
colorbar('Position', [pos(1)+pos(3)+0.03  pos(2)  0.03  pos(2)+pos(3)])

%save
if ~isempty(figpath)
    print(gcf,'-dpng','-r300',fullfile(figpath, [sub '_erp_topo']))
end

%% butterfly plot with GFP
cfg = [];
gfp = ft_globalmeanfield(cfg,timelock);

figure; hold on
rectangle('Position',[0 zmin-5 0.5 abs(zmin-5)+abs(zmax+5)], 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'none') 
plot(gfp.time,timelock.avg,'color',[0.3 0.3 0.3])
plot(gfp.time,gfp.avg, 'r', 'LineWidth', 1.5)
xlim(toi)
ylim([zmin-5 zmax+5])
set(gca,'FontSize',12)
xlabel('Time (s)')
ylabel('Amplitude (\muV)')

if ~isempty(figpath)
    print(gcf,'-dpng','-r300',fullfile(figpath,[sub '_erp_gfp']))
end

end

