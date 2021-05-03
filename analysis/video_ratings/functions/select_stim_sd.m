function [results] = select_stim_sd(loadfile, rsafile, nstim, distribute)

rng(10)

d = load(loadfile,'categories*','ratingsZ');

ratings = squeeze(nanmean(d.ratingsZ,1)); %average across 4 rating types
sdvid = nanstd(ratings,[],2); 

ncat = length(d.categories);
nstim_orig = sum(cellfun(@length,d.categories_idx));

if distribute %equal number of videos across categories
    
    nstim_categ = ceil(nstim/ncat);
    nstim = ncat*nstim_categ; %allow for more stimuli   

    idx = cell(1,ncat);    
        for ic = 1:ncat
            
            catidx = d.categories_idx{ic};
            catsd = sdvid(catidx);
            [~,sortidx] = sort(catsd,'ascend');
            idx{ic} = catidx(sortidx(1:nstim_categ));
        end
        
        sub_idx = [idx{:}];

else   
    
    [~,idx] = sort(sdvid,'ascend');
    sub_idx = idx(1:nstim);
    
    
end

r = load(rsafile,'model*');
nmod = size(r.models,2);
sqmodels = nan(nstim_orig,nstim_orig,nmod);

for im = 1:nmod
    sqmodels(:,:,im) = squareform(squeeze(r.models(:,im)));
end

sub_sqmodels = sqmodels(sub_idx,sub_idx,:);
sub_models = nan(nstim*(nstim-1)/2,nmod);
for im = 1:nmod
    sub_models(:,im) = squareform(squeeze(sub_sqmodels(:,:,im)));
end
sub_mcorrs_sq = corr(sub_models,'type','Spearman');
sub_mcorrs_vc = sub_mcorrs_sq(tril(true(size(sub_mcorrs_sq)),-1));


msoc = contains(r.modelnames,'Social');
mnag = contains(r.modelnames,'Num');

fprintf('\nMean correlation of %f', mean(sub_mcorrs_vc));
fprintf('\nCorrelation between sociality and num agents of %f', sub_mcorrs_sq(msoc,mnag,:));

results.subset_idx = sub_idx;
results.models = sub_models;
results.mcorrs = sub_mcorrs_sq;
results.modelnames = r.modelnames;


end

