function [] = scatter_ci(x,y, varargin) 
% scatter plot with confidence interval around regression line
% DC Dima 2019 (diana.c.dima@gmail.com)

label1 = 'x';
label2 = 'y';
if ~isempty(varargin)
    label1 = varargin{1};
    label2 = varargin{2};
end

xyrho = corr(x(:),y(:),'rows','complete');

mdl = fitlm(x,y);
Xnew = linspace(min(x)-1, max(x)+1, 1000)';
[Ypred,Yci] = predict(mdl, Xnew);

% figure('Color','w')
% fig = gcf;
% fig.Units = 'centimeters';
% fig.Position = [10 10 12 10];
% fig.PaperUnits = 'centimeters';
% fig.PaperPosition = [0 0 12 10];
hold on

patch([Xnew' fliplr(Xnew')], [Yci(:,2)' fliplr(Yci(:,1)')],[0.7 0.7 0.7], 'EdgeColor', 'none'); alpha 0.25
plot(Xnew, Ypred, 'color','k', 'LineWidth',2)
scatter(x, y, 50, 'k', 'filled')
box off
text(Xnew(1)+0.1, max(Yci(:)), sprintf('r = %.02f',xyrho),'FontSize',12);

ylabel(label2); 
xlabel(label1);

set(gca,'FontSize',14);
xlim([min(x)-1 max(x)+1]); 

%% export fig
%print(fig,'-dpng','-r300',[label1 '_' label2])

end