function [idx] = plot_modelcorrs(respath1, respath2)
%plot RSA model intercorrelations for both experiments

rpath = {respath1,respath2};

%order of plotting
model_order = {'Pixel Value',...
    'Hue',...
    'Saturation',...
    'Watermark',...
    'Gist',...
    'Environment',...
    'Optic flow',...
    'Conv1',...
    'FC8',...
    'Number of agents',...
    'Sociality',...
    'Valence',...
    'Arousal',...
    'Action',...
    'Transitivity',...
    'Effectors',...
    'Action category'};
   
titles = {'Exp 1','Exp 2'};

figure

for i = 1:2
    
    load(fullfile(rpath{i},'models.mat'),'mcorrK','modelnames')
    
    [~,~,idx] = intersect(model_order,modelnames,'stable');
    mcorrK = mcorrK(idx,idx);
    
    %name formatting
    modelnames{1} = 'Pixel value';
    modelnames{8} = 'AlexNet Conv1';
    modelnames{9} = 'AlexNet FC8';
    
    subplot(1,2,i)
    
    if i==1
        plot_rdm(mcorrK,modelnames,[],0,0)
    else
        plot_rdm(mcorrK,modelnames,[],1,0)
        yticklabels([])
        c = colorbar;
        c.Label.String = 'Kendall`s {\tau}_A';
    end
    
    hold on
    colormap(viridis)
    caxis([0 0.4])
    
    %separate visual and others
    line([9.5 9.5],[0 20],'color','w','LineWidth',2)
    line([0 20], [9.5 9.5], 'color','w','LineWidth',2)
    
    set(gca,'FontSize',20)
    title(titles{i},'FontWeight','normal')
    
end












end