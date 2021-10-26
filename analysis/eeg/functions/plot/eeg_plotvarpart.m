function [] = eeg_plotvarpart(vp)
% plot EEG variance partitioning results
% Figure 1: timecourse of unique contributions + their onsets
% Figure 2: timecourse of differences between unique contributions
% Figure 3: timecourse of shared variance between features
%
% input: variance partitioning structure

%% plot unique variance timecourses

%read unique variance in plotting order (vis, soc, act)
idx = [7 5 6];

try
    uv = vp.rsq_adj(idx,:,:); 
catch
    uv = vp.var_exp(idx,:,:); 
end

colors = {[0.2 0.6 0.8],[0.3 0.7 0.5],[0.6 0.6 0.8]};
labels = {'Visual','Action','Social'};

if isfield(vp,'true_rsq')
    nc = vp.true_rsq;
elseif isfield(vp,'var_true')
    nc = vp.var_true;
end

if ~isnan(sum(vp.stats.clustersig(:)))
    sigmat = logical(vp.stats.clustersig(idx,:));
else
    sigmat = [];
end
time = vp.time;

figure
if isfield(vp,'onsets'),subplot(2,1,1); end
hold on

if exist('nc','var')
    l = patch([time fliplr(time)], [mean(nc,1) fliplr(zeros(size(time)))], [0.7 0.7 0.7],'EdgeColor', 'none');
    hasbehavior(l, 'legend', false);
end

for i = 1:3

    uv_tmp = squeeze(uv(i,:,:));
    if any(size(uv_tmp)==1)
        uv_avg = uv_tmp;
        uv_std = zeros(1,numel(uv_avg));
    else
        uv_avg = mean(uv_tmp,1);  
        uv_std = std(uv_tmp,1)/sqrt(10);
    end
    
    if ~isempty(sigmat)
        sig = time(sigmat(i,:));
    else
        sig = [];
    end
    
    plot_time_results(uv_avg,uv_std,'time',time,'ylim',[-0.005 0.02],'chance',0,'color',colors{i},'legend',labels{i},...
         'linewidth',2,'ylabel','Kendall''s {\tau}_A^2','signif',sig,'signif_ylocation',-0.0015-0.0005*i);
    
end

ylim([-0.005 0.02])
yticks([0 0.01])
yticklabels ([0. 0.01])
set(gca,'FontSize',18)
set(gca,'TickLength',[0.001 0.001])
set(gca,'xgrid','on')

% plot effect onsets if available
if isfield(vp,'onsets')
    
    xlabel(' ');
    
    subplot(2,1,2);
    hold on
    
    for i = 1:3
        
        ons = vp.onsets(:,idx(i));
        onsci = prctile(ons, [5 95]);
        rectangle('Position',[onsci(1) i-0.25 onsci(2) 0.5],'FaceColor',[colors{i} 0.5],'EdgeColor','none');
        g(i,:) = ~isnan(ons);
   
    end
    
    h = boxplot(vp.onsets(:,idx),1:3,'Colors','k','Symbol','','Orientation','horizontal');
    set(h,{'linew'},{2});
    
    box off
    set(gca,'TickLength',[0.001 0.001])
    set(gca,'FontSize',18)
    ylim([0.5 3.5])
    xlabel('Time (s)')
    yticklabels(labels)
    set(gca,'xgrid','on')
    xlim([-0.2 1])
    ylabel(' ')
end


% plot differences
if isfield(vp.stats,'compclustersig')
    
    idx = [3 1; 3 2; 1 2];
    labels = {'Soc - Vis'; 'Soc - Act'; 'Vis - Act'};
    colors = {[0.6 0.6 0.8],[0.7 0.7 0.95],[0.5 0.7 0.5]};
    
    dv = nan(size(uv));
    for i = 1:3
        dv(i,:,:) = uv(idx(i,1),:,:) - uv(idx(i,2),:,:);
    end
    
    sigmat = logical(vp.stats.compclustersig);
    
    figure
    hold on
    set(gca,'ylim',[-0.025 0.025])
        
    for i = 1:3
        
        dv_tmp = squeeze(dv(i,:,:));
        dv_avg = mean(dv_tmp,1);
        dv_std = std(dv_tmp,1)/sqrt(10);
        
        sig = time(sigmat(i,:));
        
        if i==1
            sigy = -0.022;
        elseif i==2
            sigy = -0.021;
        else
            sigy = 0.022;
        end
        
        plot_time_results(dv_avg,dv_std,'time',time,'ylim',[],'chance',0,'color',colors{i},'legend',labels{i},...
            'linewidth',2,'ylabel',[],'signif',sig,'signif_ylocation',sigy);
        
    end
    
    yticks([-0.01 0 0.01])
    yticklabels([-0.01 0 0.01])
    xticks(0:0.2:0.8)
    set(gca,'FontSize',18)
    xlabel('Time (s)')
    ylabel('Kendall''s {\tau}_A^2')
end


%% plot shared variance timecourses

try
    uv = vp.rsq_adj([1 2 3 4],:,:); %read in plotting order
catch
    uv = vp.var_exp([1 2 3 4],:,:);
end

% plot unique variance timecourses

colors = {[0.6 0.6 0.6],[0.5 0.5 0.7],[0.6 0.7 0.8],[0.8 0.5 0.5]};
labels = {'Vis+Soc+Act','Soc+Act','Soc+Vis','Act+Vis'};

if ~isnan(sum(vp.stats.clustersig(:)))
    sigmat = logical(vp.stats.clustersig([1 2 3 4],:));
else
    sigmat = [];
end
time = vp.time;

figure
hold on

for i = 1:4
    uv_tmp = squeeze(uv(i,:,:));
    if any(size(uv_tmp)==1)
        uv_avg = uv_tmp;
        uv_std = zeros(1,numel(uv_avg));
    else
        uv_avg = mean(uv_tmp,1);  
        uv_std = std(uv_tmp,1)/sqrt(10);
    end
    
    if ~isempty(sigmat)
        sig = time(sigmat(i,:));
    else
        sig = [];
    end
    
    plot_time_results(uv_avg,uv_std,'time',time,'ylim',[-0.005 0.01],'chance',0,'color',colors{i},'legend',labels{i},...
         'linewidth',2,'ylabel','Kendall''s {\tau}_A^2','signif',sig,'signif_ylocation',-0.0015-0.0005*i);
    
end

ylim([-0.005 0.01])
yticks([0 0.01])
yticklabels ([0. 0.01])
set(gca,'FontSize',18)



end