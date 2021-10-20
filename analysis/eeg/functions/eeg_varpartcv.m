function [varpart] = eeg_varpartcv(rdm,time,reg,model1,model2,model3,varargin)
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
sz = floor(nsub/2);
nit = 100;

% get sliding time windows
[winmat,time,nwin] = eeg_timewindows(time,size(rdm,3));

split_idx = nan(nit,sz);

%combine predictors for hierarchical regression
if ~isempty(model3) && (isempty(varargin) || isempty(varargin{1}))
    
    comb{1} = [model1 model2 model3];
    comb{2} = [model1 model2];
    comb{3} = [model2 model3];
    comb{4} = [model1 model3];
    comb{5} = model1; comb{6} = model2; comb{7} = model3;
    
    comb_labels = {'abc','ab','bc','ac','a','b','c'};
    
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
    
    comb_labels = {'abcd','abc','acd','abd','bcd','ab','bc','ac','ad','bd','cd','a','b','c','d'};
    
end

ncomb = numel(comb);
%loop
rsq_mat = nan(ncomb,nit,nwin);
truecorrsq = nan(nit,nwin);

parfor it = 1:nit
    
    fprintf('Running iteration %d...\n', it);
    idx = randperm(nsub,sz);
    split_idx(it,:) = idx;
    
    rdm2 = squeeze(nanmean(rdm(idx,:,:),1));
    rdm1 = rdm;
    rdm1(idx,:,:) = [];
    rdm1 = squeeze(nanmean(rdm1,1));
    
    for iw = 1:nwin
        
        widx = winmat(:,iw);
        r1 = mean(rdm1(:,widx),2);
        r2 = mean(rdm2(:,widx),2);
        % r1 = rdm1(:,iw);
        % r2 = rdm2(:,iw);
        
        truecorrsq(it,iw) = (rankCorr_Kendall_taua(r1,r2))^2; %true correlation
        
        for icomb = 1:ncomb
            
            pred = comb{icomb};
            
            if ~reg
                lm = fitlm(pred,r1);
            else
                lm = fitrlinear(pred,r1);
            end
            rpred = predict(lm,pred); %get predicted responses
            
            rsq_mat(icomb,it,iw) = (rankCorr_Kendall_taua(rpred,r2))^2; %save t-a squared
    
        end
        
    end
end

if ~isempty(model3) && (isempty(varargin) || isempty(varargin{1}))
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
    
    var_mat = cat(1,abc,ab,bc,ac,a,b,c); %7
    
elseif ~isempty(model3) && ~isempty(varargin) && ~isempty(varargin{1})
    
    %unique variance
    a = rsq_mat(1,:,:) - rsq_mat(5,:,:);
    b = rsq_mat(1,:,:) - rsq_mat(3,:,:);
    c = rsq_mat(1,:,:) - rsq_mat(4,:,:);
    d = rsq_mat(1,:,:) - rsq_mat(2,:,:);
    
    %shared variance (pairs)
    ab = rsq_mat(3,:,:) - rsq_mat(11,:,:) - a;
    ac = rsq_mat(4,:,:) - rsq_mat(10,:,:) - a;
    ad = rsq_mat(2,:,:) - rsq_mat(7,:,:) - a;
    bc = rsq_mat(4,:,:) - rsq_mat(9,:,:) - b;
    bd = rsq_mat(2,:,:) - rsq_mat(8,:,:) - b;
    cd = rsq_mat(2,:,:) - rsq_mat(6,:,:) - c;
    
    %shared variance (triplets)
    abc = rsq_mat(1,:,:) - rsq_mat(15,:,:) + rsq_mat(9,:,:) + rsq_mat(10,:,:) + rsq_mat(11,:,:) - rsq_mat(4,:,:) - rsq_mat(3,:,:) - rsq_mat(5,:,:);
    abd = rsq_mat(1,:,:) - rsq_mat(14,:,:) + rsq_mat(8,:,:) + rsq_mat(7,:,:) + rsq_mat(11,:,:) - rsq_mat(2,:,:) - rsq_mat(3,:,:) - rsq_mat(5,:,:);
    acd = rsq_mat(1,:,:) - rsq_mat(13,:,:) + rsq_mat(6,:,:) + rsq_mat(7,:,:) + rsq_mat(10,:,:) - rsq_mat(2,:,:) - rsq_mat(4,:,:) - rsq_mat(5,:,:);
    bcd = rsq_mat(1,:,:) - rsq_mat(12,:,:) + rsq_mat(6,:,:) + rsq_mat(8,:,:) - rsq_mat(9,:,:) - rsq_mat(2,:,:) - rsq_mat(4,:,:) - rsq_mat(3,:,:);
    
    %shared variance (abcd)
    abcd = rsq_mat(12,:,:) + rsq_mat(13,:,:) + rsq_mat(14,:,:) + rsq_mat(15,:,:) - rsq_mat(6,:,:) - rsq_mat(8,:,:) - rsq_mat(9,:,:) - ...
        - rsq_mat(7,:,:) - rsq_mat(10,:,:) - rsq_mat(11,:,:) + rsq_mat(2,:,:) + rsq_mat(4,:,:) + rsq_mat(3,:,:) + rsq_mat(5,:,:) - rsq_mat(1,:,:);
    
    var_mat = cat(1,abcd, abc, acd, abd, bcd, ab, bc, ac, ad, bd, cd, a, b, c, d, rsq_mat(12:15,:,:));
    comb_labels(16:19) = {'orig a','orig b', 'orig c', 'orig d'};

end

    varpart.rsq_adj = var_mat;
    varpart.total_rsq = squeeze(rsq_mat(1,:,:));
    varpart.comb_labels = comb_labels;
    varpart.true_rsq = truecorrsq;
    varpart.time = time;
    varpart.split_idx = split_idx;

    if reg
        varpart.regularize = 'ridge';
    end

end

