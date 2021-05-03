function [prcvar] = sim_plotvar(varexp,nc)
%plot % of variance explained by all models
%inputs: variance explained, noise ceiling structure

uppRsq = mean(nc.uppRsqAdj);
prcvar = (varexp./uppRsq)*100;
color = [0.5 0.7 0.6];

figure
raincloud_plot(prcvar,'color', color,'box_on',1)
set(gca,'FontSize',18)
xlabel('% variance explained')
yticks([])
box off





end

