function [varpart] = rdm_varpart(rdm,model1,model2,model3,varargin)
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

if ~isempty(model3) && (isempty(varargin) || isempty(varargin{1}))
    
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
        
        %variance inflation factor
        if icomb==1
            R0 = corrcoef(pred);
            vif = diag(inv(R0))';
        end
        
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
 
elseif ~isempty(model3) && ~isempty(varargin) && ~isempty(varargin{1})
    
    model4 = varargin{1};
    
    comb{1}  = [model1 model2 model3 model4];
    
    comb{2}  = [model1 model2 model3];
    comb{3}  = [model1 model3 model4];
    comb{4}  = [model1 model2 model4];
    comb{5}  = [model2 model3 model4]; 
    
    comb{6}  = [model1 model2];
    comb{7}  = [model2 model3];
    comb{8}  = [model1 model3];
    comb{9}  = [model1 model4];
    comb{10} = [model2 model4];
    comb{11} = [model3 model4];
    
    comb{12} = model1;
    comb{13} = model2;
    comb{14} = model3;
    comb{15} = model4;

    ncomb = length(comb);
    
    %loop
    rsq_mat = nan(ncomb,nsub);
    comb_labels = {'abcd','abc','acd','abd','bcd','ab','bc','ac','ad','bd','cd','a','b','c','d'};
    %comb_labels = {1234,123,134,124,234,12,23,13,14,24,34, 1, 2, 3, 4};
    %idx =          [1    2   3   4   5   6  7  8  9 10 11 12 13 14 15];
    
    for icomb = 1:ncomb
        
        pred = comb{icomb};
        
        %variance inflation factor
        if icomb==1
            R0 = corrcoef(pred);
            vif = diag(inv(R0))';
        end
        
        for isub = 1:size(rdm,1)
            
            lm = fitlm(pred,rdm(isub,:)');
            rsq_mat(icomb,isub) = lm.Rsquared.Adjusted; %save adj r-squared
            
        end
    end
    
    %unique variance
    a = rsq_mat(1,:) - rsq_mat(5,:);
    b = rsq_mat(1,:) - rsq_mat(3,:);
    c = rsq_mat(1,:) - rsq_mat(4,:);
    d = rsq_mat(1,:) - rsq_mat(2,:);
    
    %shared variance (pairs)
    ab = rsq_mat(3,:) - rsq_mat(11,:) - a;    
    ac = rsq_mat(4,:) - rsq_mat(10,:) - a;
    ad = rsq_mat(2,:) - rsq_mat(7,:) - a;
    bc = rsq_mat(4,:) - rsq_mat(9,:) - b;
    bd = rsq_mat(2,:) - rsq_mat(8,:) - b;
    cd = rsq_mat(2,:) - rsq_mat(6,:) - c;
    
    %shared variance (triplets)
    abc = rsq_mat(1,:) - rsq_mat(15,:) + rsq_mat(9,:) + rsq_mat(10,:) + rsq_mat(11,:) - rsq_mat(4,:) - rsq_mat(3,:) - rsq_mat(5,:);
    abd = rsq_mat(1,:) - rsq_mat(14,:) + rsq_mat(8,:) + rsq_mat(7,:) + rsq_mat(11,:) - rsq_mat(2,:) - rsq_mat(3,:) - rsq_mat(5,:);
    acd = rsq_mat(1,:) - rsq_mat(13,:) + rsq_mat(6,:) + rsq_mat(7,:) + rsq_mat(10,:) - rsq_mat(2,:) - rsq_mat(4,:) - rsq_mat(5,:);
    bcd = rsq_mat(1,:) - rsq_mat(12,:) + rsq_mat(6,:) + rsq_mat(8,:) - rsq_mat(9,:) - rsq_mat(2,:) - rsq_mat(4,:) - rsq_mat(3,:);
    
    %shared variance (abcd)
    abcd = rsq_mat(12,:) + rsq_mat(13,:) + rsq_mat(14,:) + rsq_mat(15,:) - rsq_mat(6,:) - rsq_mat(8,:) - rsq_mat(9,:) - ...
        - rsq_mat(7,:) - rsq_mat(10,:) - rsq_mat(11,:) + rsq_mat(2,:) + rsq_mat(4,:) + rsq_mat(3,:) + rsq_mat(5,:) - rsq_mat(1,:);

    
    var_mat = [abcd;abc;acd;abd;bcd;ab;bc;ac;ad;bd;cd;a;b;c;d;rsq_mat(12:15,:)];
    comb_labels(16:19) = {'orig a','orig b', 'orig c', 'orig d'};
    
    
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
varpart.vif = vif;

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

