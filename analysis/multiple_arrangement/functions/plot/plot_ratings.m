function [] = plot_ratings(datapath)
% plot distributions of behavioral video ratings
% input: path to directory containing files with video ratings for both experiments

filesuffix = [152,65];
colours = [0.5 0.5 0.8; 0.5 0.7 0.6];
metrics = {'Transitivity', 'Activity', 'Valence', 'Arousal', 'Sociality'};
rating_idx = [5 4 2 3 1]; % reorder ratings for plotting

m = cell(5,2); %read ratings in cell array
k = cell(5,2); %reliability in same format

% calculate reliability

for i = 1:2
    
    % two file conventions (original and OSF renamed files)
    try
        % ratings are in a ratingsZ variable
        load(fullfile(datapath,sprintf('videoset_%d.mat',filesuffix(i))),'ratingsZ','transitivity');
    catch
        % ratings are in separate variables
        load(fullfile(datapath,sprintf('video_features%d.mat',i)),'sociality','valence','arousal','activity','transitivity');
        ratingsZ = cat(3,sociality,valence,arousal,activity);
        ratingsZ = permute(ratingsZ, [3 1 2]);
    end
   
    %reliability
    looK = nan(5,size(ratingsZ,3));
    
    %read and reorder ratings
    for ii = 1:4
        
        r = squeeze(ratingsZ(ii,:,:));
        m{ii,i} = nanmean(r,2);
        
        %exclude people who rated fewer than 5 videos out of the set - this happens in exp 2 (since only 65 vids)
        ns = sum(~isnan(r),1);
        r(:,ns<5) = [];
        
        %get leave-one-out reliability  
        for ip = 1:size(r,2)
            
            idx = ~isnan(r(:,ip));
            r1 = r(idx,ip);
            r2 = r(idx,:);
            r2(:,ip) = [];
            r2 = nanmean(r2,2);
            looK(ii,ip) = rankCorr_Kendall_taua(r1,r2);
            
        end
        
        k{ii,i} = looK(ii,:);

    end
    
    % transitivity ratings were collected separately
    m{5,i} = nanmean(transitivity,2);
    
    for ip = 1:size(transitivity,2)
        
        tl = transitivity;
        tl(:,ip) = [];
        tl = nanmean(tl,2);
        looK(5,ip) = rankCorr_Kendall_taua(transitivity(:,ip),tl);
    end
    
    k{5,i} = looK(5,:);
    
    % run anova on reliabilities
    [~,ratings_reliability.stats] = anova1(looK');
    ratings_reliability.looK = looK;
    
    try
      save(fullfile(datapath,sprintf('videoset_%d.mat',filesuffix(i))),'-append','ratings_reliability');
    catch
      save(fullfile(datapath,sprintf('video_features%d.mat',i)),'-append','ratings_reliability');  
    end
    
end

%reorder ratings for plotting
m = m(rating_idx,:);
k = k(rating_idx,:);

%compare feature distributions across experiments using Mann-Whitney tests
distrib_pval = nan(1,5); 
distrib_zval = nan(1,5);
for i = 1:5
    [p,~,stats] = ranksum(m{i,1},m{i,2});
    distrib_pval(i) = p;
    distrib_zval(i) = stats.zval;
end

%save the stats to the 2nd file
ratingsMannWhitney = [distrib_pval;distrib_zval];
save(fullfile(datapath,sprintf('videoset_%d.mat',filesuffix(2))),'-append','ratingsMannWhitney');

% plot distributions

figure
rm_raincloud(m,colours,1)

f = get(gca,'Children');
legend([f(4),f(2)],'Exp 1','Exp 2')
legend boxoff

box off
metrics = fliplr(metrics);
yticklabels(metrics)
set(gca,'TickLength',[0.001 0.001])
xlabel('Z-score')
xlim([-3 3.2])
xticks(-3:1:3)
set(gca,'FontSize',20)

% plot rating reliability

figure
rm_raincloud(k,colours,1)

f = get(gca,'Children');
legend([f(4),f(2)],'Exp 1','Exp 2')
legend boxoff

box off
yticklabels(metrics)
set(gca,'TickLength',[0.001 0.001])
xlabel('Kendall''s {\tau}_A')
xlim([-0.75 1.1])
xticks(-0.5:0.25:1)
set(gca,'FontSize',20)




end