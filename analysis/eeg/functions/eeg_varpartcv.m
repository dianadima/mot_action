function [varpart] = eeg_varpartcv(rdm,model1,model2,model3)
% cross-validated variance partitioning analysis over time
% runs split-half cross-validation
% uses Kendall's tau-A squared as prediction metric
% 
% inputs: rdm (Nsub x Npairs x Ntimepoints)
%         model1, model2, model3: predictors (Nmodel x Npairs)
%
% output: varpart, structure containing
%                rsq_adj, adjusted R-squared for each combination of models
%                comb_labels, order of model combinations (i.e. abc, ab, bc, ac, a, b, c)
%                total_rsq, total variance explained by the models (adjusted R-squared)
%                noiseceil, upper and lower bounds of noise ceiling (cf. Nili et al 2014)
%
% DC Dima 2021 (diana.c.dima@gmail.com)

nsub = size(rdm,1);
nwin = size(rdm,3);
sz = floor(nsub/2);
nit = 100;

%combine predictors for hierarchical regression
comb{1} = [model1 model2 model3];
comb{2} = [model1 model2];
comb{3} = [model2 model3];
comb{4} = [model1 model3];
comb{5} = model1; comb{6} = model2; comb{7} = model3;

ncomb = length(comb);

%loop
rsq_mat = nan(ncomb,nit,nwin);
comb_labels = {'abc','ab','bc','ac','a','b','c'};

for icomb = 1:ncomb
    
    pred = comb{icomb};
    
    for it = 1:nit
        
        fprintf('Running iteration %d...\n', it);
        idx = randperm(nsub,sz);
        rdm1 = squeeze(nanmean(rdm(idx,:,:),1));
        rdm2 = rdm;
        rdm2(idx,:,:) = [];
        rdm2 = squeeze(nanmean(rdm2,1));
        
        for iw = 1:nwin
            
            lm = fitlm(pred,rdm1(:,iw));
            rpred = predict(lm,pred); %get predicted responses
            
            rsq_mat(icomb,it,iw) = (rankCorr_Kendall_taua(rpred,rdm2(:,iw)))^2; %save t-a squared
            
        end
        
    end
end

%unique variance
a = rsq_mat(1,:,:) - rsq_mat(3,:,:);
b = rsq_mat(1,:,:) - rsq_mat(4,:,:);
c = rsq_mat(1,:,:) - rsq_mat(2,:,:);

%shared variance (pairs)
bc = rsq_mat(2,:,:) - rsq_mat(5,:,:) - b;
ab = rsq_mat(4,:,:) - rsq_mat(7,:,:) - a;
ac = rsq_mat(3,:,:) - rsq_mat(6,:,:) - c;

%shared variance (abc)
abc = rsq_mat(1,:,:) - (a+b+c) - (ab+ac+bc);

var_mat = cat(3,abc,ab,bc,ac,a,b,c); %7
var_mat = permute(var_mat,[3 1 2]);

varpart.rsq_adj = var_mat;
varpart.total_rsq = rsq_mat(1,:,:);
varpart.comb_labels = comb_labels;


end

