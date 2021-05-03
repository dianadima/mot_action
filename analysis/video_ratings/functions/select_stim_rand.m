function [results] = select_stim_rand(loadfile, rsafile, nstim, niter, distribute)

rng(10)

d = load(loadfile,'categories*');

ncat = length(d.categories);
nstim_orig = sum(cellfun(@length,d.categories_idx));

if distribute==1 %equal number of videos across categories
    
    nstim_categ = 4;%ceil(nstim/ncat);
    nstim = ncat*nstim_categ; %allow for more stimuli
    
    sub_idx = nan(niter,nstim);
    
    for it = 1:niter
        
        idx = cell(1,ncat);
        
        for ic = 1:ncat
            
            catidx = d.categories_idx{ic};
            catidx = catidx(randperm(length(catidx)));
            idx{ic} = catidx(1:nstim_categ);
        end
        
        idx = [idx{:}];
        sub_idx(it,:) = idx(:);
    end
    
elseif distribute==2 %sample proportionally
    
    nstim_categ_orig = cellfun(@length,d.categories_idx);
    nstim_categ = floor(nstim_categ_orig/3);
    nstim = sum(nstim_categ); %allow for more stimuli
    
    sub_idx = nan(niter,nstim);
    
    for it = 1:niter
        
        idx = cell(1,ncat);
        
        for ic = 1:ncat
            
            catidx = d.categories_idx{ic};
            catidx = catidx(randperm(length(catidx)));
            idx{ic} = catidx(1:nstim_categ(ic));
        end
        
        idx = [idx{:}];
        sub_idx(it,:) = idx;
    end
    
else
    
    sub_idx = nan(niter,nstim);
    
    for it = 1:niter
        idx = randperm(nstim_orig);
        sub_idx(it,:) = idx(1:nstim);
    end
    
end

r = load(rsafile,'model*');
nmod = size(r.models,2);
sqmodels = nan(nstim_orig,nstim_orig,nmod);

for im = 1:nmod
    sqmodels(:,:,im) = squareform(squeeze(r.models(:,im)));
end

sub_mcorrs_sq = nan(nmod,nmod,niter);
sub_mcorrs_vc = nan(nmod*(nmod-1)/2,niter);

for it = 1:niter
    
    sub_sqmodels = sqmodels(sub_idx(it,:),sub_idx(it,:),:);
    sub_models = nan(nstim*(nstim-1)/2,nmod);
    for im = 1:nmod
        sub_models(:,im) = squareform(squeeze(sub_sqmodels(:,:,im)));
    end
    sub_mcorrs = corr(sub_models,'type','Spearman','rows','pairwise');
    sub_mcorrs_sq(:,:,it) = sub_mcorrs;
    sub_mcorrs_vc(:,it) = sub_mcorrs(tril(true(size(sub_mcorrs)),-1));
    
end

msoc = contains(r.modelnames,'Social');
mnag = contains(r.modelnames,'Num');

[mincorr, idx_mincorr] = min(mean(sub_mcorrs_vc,1));
[mincorr_soc,idx_mincorr_soc] = min(squeeze(sub_mcorrs_sq(msoc,mnag,:)));

fprintf('\nMinimum overall correlation of %f in subset %d', mincorr, idx_mincorr);
fprintf('\nMinimum correlation between sociality and num agents of %f in subset %d', mincorr_soc, idx_mincorr_soc);

%get models for subset with lowest sociality vs num agents correlation
subsoc = sub_idx(idx_mincorr_soc,:)';
subsocmodels = sqmodels(subsoc,subsoc,:);
sub_models = nan(nstim*(nstim-1)/2,nmod);
for im = 1:nmod
    sub_models(:,im) = squareform(squeeze(subsocmodels(:,:,im)));
end

results.subset_idx = sub_idx;
results.models = sub_models;
results.mcorrs = sub_mcorrs_sq;
results.modelnames = r.modelnames;
results.idx_mincorr_all = idx_mincorr;
results.idx_mincorr_soc = idx_mincorr_soc;

%get models for subset with lowest overall correlation
suball = sub_idx(idx_mincorr,:)';
suballmodels = sqmodels(suball,suball,:);
sub_models = nan(nstim*(nstim-1)/2,nmod);
for im = 1:nmod
    sub_models(:,im) = squareform(squeeze(suballmodels(:,:,im)));
end

results.subset_idx = sub_idx;
results.models = sub_models;
results.mcorrs = sub_mcorrs_sq;
results.modelnames = r.modelnames;
results.idx_mincorr_all = idx_mincorr;
results.idx_mincorr_soc = idx_mincorr_soc;




end

