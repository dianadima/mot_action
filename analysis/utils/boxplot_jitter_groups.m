function [] = boxplot_jitter_groups(data,labels,cfg)
% plot grouped data using scatterplots overlaid with boxplots
% Inputs: data: 2d matrix of size N categories x N observations
%         labels: cell array or vector containing category labels
%         cfg: additional options
%               scatter: default 0, add jitter to scatterplots
%               ylabel: default [], label y-axis
%               color: default [0.5 0.5 0.5], color of scatter points (can
%                      be cell array for different category colors)
%               mrksize, default 30, size of scatter points
% DC Dima 2021 (diana.c.dima@gmail.com)


if isfield(cfg,'scatter') && cfg.scatter, sc = 1; else, sc = 0; end
if isfield(cfg,'ylabel'), yl = cfg.ylabel; else, yl = []; end
if isfield(cfg,'color'), cl = cfg.color; else, cl = [0.5 0.5 0.5]; end
if isfield(cfg,'mrksize'), ms = cfg.mrksize; else, ms = 30; end

nobs = size(data,2);
ncat = size(data,1);

njitter = 0.005*nobs/2;
jittermat = -njitter:0.005:njitter-0.001; %create jitter matrix
    
hold on
for istim = 1:ncat
    
    if isfield(cfg,'color')&&iscell(cfg.color), cl = cfg.color{istim}; end

    if sc
        scatter(jittermat(:)+istim*ones(nobs,1), data(istim,:), 'MarkerEdgeColor','w','MarkerFaceColor',cl,'SizeData',ms);
    else
        scatter(istim*ones(nobs,1), data(istim,:), 'MarkerEdgeColor','w','MarkerFaceColor',cl,'SizeData',ms);
    end

end

h=boxplot(data', 'Positions',1:ncat,'Colors','k','Symbol','');
set(h,{'linew'},{1.2});
xticklabels(labels)
xtickangle(90)
box off
set(gca,'TickLength',[0.001 0.001])
set(gca,'FontSize',18)

ylabel(yl)

ylim([min(min(data))-0.1 max(max(data))+0.15])

ax = gca; ax.YGrid = 'on';

end