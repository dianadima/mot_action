function [] = plot_reliability(respath1,respath2)

rpath = {respath1,respath2};

colours = [0.5 0.5 0.8; 0.5 0.7 0.6]; %experiment colours
labels = {'Exp 1', 'Exp 2'};
labels = fliplr(labels);

rel = cell(2,1);

for i = 1:2
    
    load(fullfile(rpath{i},'rdm.mat'),'nc')
    rel{i} = nc.looK;
    
end
    
figure

rp = rm_raincloud(rel,[0.7 0.7 0.7],1);

set(gca,'FontSize',20)
yticklabels(labels)
set(gca,'TickLength',[0.001 0.001])
xlabel('Kendall''s {\tau}_A')

for c = 1:2
    rp.p{c}.CData(1,:,:) = colours(c,:);
    rp.s{c}.MarkerFaceColor = colours(c,:);
end

set(gca,'XTick',-0.2:0.1:0.5);
xlim([-0.2 0.5])
set(gca,'xgrid', 'on')
y = get(gca,'ylim');
ylim([y(1)-1 y(2)])
clear rp


end