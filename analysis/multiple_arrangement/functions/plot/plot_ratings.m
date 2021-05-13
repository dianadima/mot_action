function [] = plot_ratings(datapath)

colours = [0.5 0.5 0.8; 0.5 0.7 0.6];;
metrics = {'Sociality', 'Transitivity', 'Valence', 'Arousal', 'Action'};
m = cell(5,2); %read ratings in cell array

for i = 1:2
    
    if i==1
        load(fullfile(datapath,'videoset_152.mat'),'ratingsZ','transitivity');
    else
        load(fullfile(datapath,'videoset_65.mat'),'ratingsZ','transitivity');
    end
    
    %read and reorder ratings
    for ii = 1:4
        
        r = squeeze(ratingsZ(ii,:,:));
        if ii==1
            m{ii,i} = nanmean(r,2);
        else
            m{ii+1,i} = nanmean(r,2);
        end
    end
    
    m{2,i} = nanmean(transitivity,2);
    
end

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













end