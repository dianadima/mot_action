function [] = plot_rainclouds(datamatrix,labels,metric)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

nvar = size(datamatrix,2);
data = cell(nvar,1);
labels = fliplr(labels); %label correctly

for i = 1:nvar

    data{i} = datamatrix(:,i);
    
end
    
figure

rp = rm_raincloud(data,[0.7 0.7 0.7],1);

set(gca,'FontSize',20)
yticklabels(labels)
set(gca,'TickLength',[0.001 0.001])
xlabel(metric)

colours = viridis(nvar+1);

for c = 1:2
    rp.p{c}.CData(1,:,:) = colours(c,:);
    rp.s{c}.MarkerFaceColor = colours(c,:);
end

set(gca,'xgrid', 'on')
clear rp

end

