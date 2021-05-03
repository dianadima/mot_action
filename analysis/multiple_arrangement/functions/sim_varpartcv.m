function [varpart] = sim_varpartcv(rdm,model1,model2,model3,exp)
% cross-validated variance partitioning analysis
% runs split-half cross-validation (pairwise: Exp1, subjectwise: Exp2)
% uses Kendall's tau-A squared as prediction metric
% 
% inputs: rdm (vectorized, Nsub x Npairs)
%         model1, model2, model3: predictors (Nmodel x Npairs); model3 can be empty
%         exp, 1 or 2 (for pairwise vs subjectwise CV)
%
% DC Dima 2021 (diana.c.dima@gmail.com)

nsub = size(rdm,1);
sz = floor(nsub/2);
nit = 100;

rdmnan = ~isnan(rdm);
rdmsum = squeeze(sum(rdmnan,1));

if ~isempty(model3)
    
    %combine predictors for hierarchical regression
    comb{1} = [model1 model2 model3];
    comb{2} = [model1 model2];
    comb{3} = [model2 model3];
    comb{4} = [model1 model3];
    comb{5} = model1; comb{6} = model2; comb{7} = model3;
    
    ncomb = length(comb);
    
    %loop
    rsq_mat = nan(ncomb,nit);
    comb_labels = {'abc','ab','bc','ac','a','b','c'};
    
    for icomb = 1:ncomb
        
        pred = comb{icomb};
        
        for it = 1:nit
                
            if exp==1 %pairwise
              
              npairs = numel(rdmsum);
              rdm1 = nan(npairs,1); 
              rdm2 = nan(npairs,1);
              
              for iv = 1:numel(rdmsum)
                  
                  idx = randperm(rdmsum(iv),floor(rdmsum(iv)/2));
                  tmp = rdm(:,iv);
                  tmp = tmp(~isnan(tmp));
                  rdm1(iv) = nanmean(tmp(idx),1);
                  tmp(idx) = [];
                  rdm2(iv) = nanmean(tmp,1);
                  
              end
                      
            elseif exp==2 %subjectwise
                
                idx = randperm(nsub,sz);
                rdm1 = nanmean(rdm(idx,:),1)';
                rdm2 = rdm; 
                rdm2(idx,:) = [];
                rdm2 = nanmean(rdm2,1)';
                
            end
            
            lm = fitlm(pred,rdm1);
            rpred = predict(lm,pred); %get predicted responses
            
            rsq_mat(icomb,it) = (rankCorr_Kendall_taua(rpred,rdm2))^2; %save t-a squared
            
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
        
        for it = 1:nsub
            
            rdm1 = rdm;
            rdm1(it,:) = [];
            rdm2 = rdm(it,:);
            
            lm = fitlm(pred,nanmean(rdm1,1)');
            rpred = predict(lm,pred);
            
            rsq_mat(icomb,it) = (rankCorr_Kendall_taua(rpred,rdm2'))^2; %save t-a squared
            
        end
    end
    
    %unique variance
    a = rsq_mat(1,:) - rsq_mat(3,:);
    b = rsq_mat(1,:) - rsq_mat(2,:);
    
    %shared variance (ab)
    ab = rsq_mat(1,:) - a - b;
    
    var_mat = [ab;a;b]; %7xnsub+1
    
end

varpart.rsq_adj = var_mat;
varpart.total_rsq = rsq_mat(1,:);
varpart.comb_labels = comb_labels;



end
