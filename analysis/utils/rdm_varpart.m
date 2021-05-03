function [varpart] = rdm_varpart(rdm,model1,model2,model3)
% perform variance partitioning analysis (hierarchical regression with 3 predictors)
% Inputs: rdm: vectorized RDM, N subjects x N pairs
%         model1, model2, model3: predictors, N models x N pairs (each predictor can contain several columns) 
% Output: varpart, structure containing
%                rsq_adj, adjusted R-squared for each combination of models
%                comb_labels, order of model combinations (i.e. abc, ab, bc, ac, a, b, c)
%                total_rsq, total variance explained by the models (adjusted R-squared)
%                noiseceil, upper and lower bounds of noise ceiling (cf. Nili et al 2014)
% DC Dima 2020 (diana.c.dima@gmail.com)

%fixed_effects
nsub = size(rdm,1);
if nsub>1
    rdm(nsub+1,:) = nanmean(rdm,1);
end

if ~isempty(model3)
    
    comb{1} = [model1 model2 model3];
    comb{2} = [model1 model2];
    comb{3} = [model2 model3];
    comb{4} = [model1 model3];
    comb{5} = model1; comb{6} = model2; comb{7} = model3;
    
    ncomb = length(comb);
    
    %loop
    rsq_mat = nan(ncomb,nsub);
    comb_labels = {'abc','ab','bc','ac','a','b','c'};
    
    for icomb = 1:ncomb
        
        pred = comb{icomb};
        
        for isub = 1:size(rdm,1)
            
            lm = fitlm(pred,rdm(isub,:)');
            rsq_mat(icomb,isub) = lm.Rsquared.Adjusted; %save adj r-squared
            
        end
    end
    
    %unique variance
    a = rsq_mat(1,:) - rsq_mat(3,:);
    b = rsq_mat(1,:) - rsq_mat(4,:);
    c = rsq_mat(1,:) - rsq_mat(2,:);
    
    %shared variance (pairs)
    bc = rsq_mat(2,:) - rsq_mat(5,:) - b;
    ab = rsq_mat(4,:) - rsq_mat(7,:) - a;
    ac = rsq_mat(3,:) - rsq_mat(6,:) - c;
    
    %shared variance (abc)
    abc = rsq_mat(1,:) - (a+b+c) - (ab+ac+bc);
    
    var_mat = [abc;ab;bc;ac;a;b;c]; %7
    
else
    
    comb{1} = [model1 model2];
    comb{2} = model1;
    comb{3} = model2;

    ncomb = length(comb);
    
    %loop
    rsq_mat = nan(ncomb,nsub);
    comb_labels = {'ab','a','b'};
    
    for icomb = 1:ncomb
        
        pred = comb{icomb};
        
        for isub = 1:nsub+1
            
            lm = fitlm(pred,rdm(isub,:)');
            rsq_mat(icomb,isub) = lm.Rsquared.Adjusted; %save adj r-squared
            
        end
    end
    
    %unique variance
    a = rsq_mat(1,:) - rsq_mat(3,:);
    b = rsq_mat(1,:) - rsq_mat(2,:);
    
    %shared variance (ab)
    ab = rsq_mat(1,:) - a - b;
    
    var_mat = [ab;a;b]; %7xnsub+1
    
end

varpart.rsq_adj = var_mat(:,1:nsub);
varpart.total_rsq = rsq_mat(1,1:nsub);
varpart.comb_labels = comb_labels;

if nsub>1
    
    varpart.avg.rsq_adj = var_mat(:,nsub+1); %fixed effects
    varpart.avg.total_rsq = rsq_mat(1,nsub+1); %fixed effects
    
    %also put a noise ceiling on the regression
    rsq_loo = nan(nsub,1);
    rsq_upp = nan(nsub,1);
    
    for isub = 1:nsub
        
        lm = fitlm(rdm(isub,:)',rdm(nsub+1,:)');
        rsq_upp(isub) = lm.Rsquared.Adjusted;
        loordm = rdm;
        loordm(isub,:) = [];
        lm = fitlm(rdm(isub,:)', nanmean(loordm,1)');
        rsq_loo(isub) = lm.Rsquared.Adjusted;
        
    end
    
    varpart.noiseceil.low = rsq_loo;
    varpart.noiseceil.upp = rsq_upp;
    
end

end

