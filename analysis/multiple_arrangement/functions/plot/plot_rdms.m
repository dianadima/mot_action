function [] = plot_rdms(respath1,respath2)

rpath = {respath1,respath2};
figure

for i = 1:2
    
    load(fullfile(rpath{i}, 'rdm.mat'),'rdm')
    
    pathparts = strsplit(respath1,'/');
    datapath = fullfile(strjoin(pathparts(1:end-3),'/'),...
        'data','multiple_arrangement',sprintf('exp%d',i));
    load(fullfile(datapath,'video_features.mat'),'categories','categories_idx')
    
    subplot(1,2,i)
    
    rdm = squeeze(nanmean(rdm,1));
    plot_rdm(rdm,categories,categories_idx,0,0)
    
    title(sprintf('Exp %d',i),'FontWeight','normal')
    set(gca,'FontSize',20)
    xticklabels([])
    colormap(bone)
    caxis([0 0.8])
    
    if i==2
        
        c = colorbar;
        c.Label.String = 'Euclidean distance';
    end
    
end








end