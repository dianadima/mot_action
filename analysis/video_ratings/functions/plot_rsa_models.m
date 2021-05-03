function [] = plot_rsa_models(models,modelnames,grouptitle, categories, categories_idx)

% categories = {'C','E','W','S','F','N'};
% categories_idx = [1 10; 11 20; 21 30; 31 40; 41 45; 46 50]; %start and end index of each category

% %abbreviate categories
% for i = 1:length(categories)
%     categories{i} = categories{i}(1:5);
% end

nmodels = size(models,2);
nsp1 = floor(sqrt(nmodels));
nsp2 = ceil(nmodels/nsp1);

figure('color','w')
f = gcf;
f.Units = 'centimeters';
f.Position = [0 0 5*nsp2 5*nsp1];
f.PaperUnits = 'centimeters';
f.PaperPosition = [0 0 5*nsp2 5*nsp1];

for m = 1:nmodels
    
    mtmp = models(:,m);
    subplot(nsp1,nsp2,m) 
    plot_rdm(mtmp,categories,categories_idx,0,0)
    title(modelnames{m},'FontWeight','normal')
    set(gca,'FontSize',10)
    
end

if isempty(grouptitle), grouptitle = 'Model RDMs'; end
suptitle(grouptitle)

end

