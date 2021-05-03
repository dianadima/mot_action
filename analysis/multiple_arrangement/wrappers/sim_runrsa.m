function [results] = sim_runrsa(rdmfile,modfile,rsafile)
%run RSA analysis
%Inputs: rdmfile, file with behavioral RDM and noise ceiling
%        modfile, file with RSA models
%        rsafile, results file to be saved

load(rdmfile,'nc','qc');
rdmvec = nc.rdmvec;

%get path to save figures
[fpath,~,~] = fileparts(rdmfile);
figpath = fullfile(fpath,'figures');

%check if the file contains RDM models
if ismember('models',who('-file',modfile))
   load(modfile,'models','modelnames')   
else
    %it just has the raw ratings, so make the models
    [models,modelnames] = sim_getrsamodels(modfile, fullfile(fpath,'models.mat'));
end

%initialize variables
nsub = size(rdmvec,1);      %number of subjects
nmod = size(models,2);      %number of models
rsacorrS = nan(nsub,nmod);  %Spearman's corr
rsacorrK = nan(nsub,nmod);  %Kendall's tau-A
rsaAdRsq = nan(nsub,1);     %var explained by all models - adjusted R^2
rsaOdRsq = nan(nsub,1);     %var explained by all models - ordinary R^2

%subject-wise RSA
for isub = 1:nsub
    
    %select the stimuli seen by this participant
    rsub = rdmvec(isub,:);
    idx = ~isnan(rsub);
    rsub = rsub(idx);
    msub = models(idx,:);
    
    %Spearman
    cmatS = corr([rsub(:) msub]);
    rsacorrS(isub,:) = cmatS(1,2:end);
    
    %Kendall
    for imod = 1:nmod
        rsacorrK(isub,imod) = rankCorr_Kendall_taua(rsub(:), msub(:,imod));       
    end
    
    %regression
    lm = fitlm(msub, rsub(:));
    rsaAdRsq(isub) = lm.Rsquared.Adjusted;
    rsaOdRsq(isub) = lm.Rsquared.Ordinary;
    
end

%stats
nperm = 5000;
[pvalS,~,~,pval_corrS] = randomize_rho(rsacorrS,'num_iterations',nperm);
[pvalK,~,~,pval_corrK] = randomize_rho(rsacorrK,'num_iterations',nperm);

%fixed-effects RSA using whole average RDM
avgrdm = nanmean(rdmvec,1);
avgcorrS = corr([avgrdm(:) models]);
avgcorrS = avgcorrS(1,2:end);
avgcorrK = nan(1,nmod);
for imod = 1:nmod
    avgcorrK(imod) = rankCorr_Kendall_taua(avgrdm(:),models(:,imod));
end
lm = fitlm(models,avgrdm(:));
avgAdRsq = lm.Rsquared.Adjusted; 
avgOdRsq = lm.Rsquared.Ordinary;

results.Spearman.rsacorr = rsacorrS;
results.Spearman.pvalraw = pvalS;
results.Spearman.pvalcorr = pval_corrS;
results.Spearman.avgcorr = avgcorrS;

results.Kendall.rsacorr = rsacorrK;
results.Kendall.pvalraw = pvalK;
results.Kendall.pvalcorr = pval_corrK;
results.Kendall.avgcorr = avgcorrK;

results.AdjRsquared.ind = rsaAdRsq;
results.AdjRsquared.avg = avgAdRsq;
results.OrdRsquared.ind = rsaOdRsq;
results.OrdRsquared.avg = avgOdRsq;

%plot Spearman and Kendall results
ncS = [mean(nc.looS) mean(nc.uppS)]; 
sim_plotrsa(rsacorrS,pval_corrS,avgcorrS,ncS,modelnames,'Spearman`s rho',[]);
print(gcf,'-r300','-dpng',fullfile(figpath,'rsaSpearman'))

ncK = [mean(nc.looK) mean(nc.uppK)];
sim_plotrsa(rsacorrK,pval_corrK,avgcorrK,ncK,modelnames,'Kendall`s tauA',[]);
print(gcf,'-r300','-dpng',fullfile(figpath,'rsaKendall'))

%store everything in one place
results.modelnames = modelnames;
results.Spearman.noise_ceiling = ncS;
results.Kendall.noise_ceiling = ncK;

save(rsafile,'-struct','results')

%use training RDM to get a more conservative noise ceiling for plotting the
%overall variance explained by models
sim_plotvar(rsaAdRsq,qc.nc)

end

