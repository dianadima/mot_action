function [varpart] = eeg_varpartavg(rdm,time,m1,m2,m3,varargin)

rdm = squeeze(nanmean(rdm,1));

if ~isempty(varargin)
    m4 = varargin{1};
else
    m4 = [];
end

ws = 5; %10 ms - window size in timepoints
ov = 3; %6 ms overlap

t = 1:601;
winmat = buffer(t,ws,ov);
winmat = winmat(:,3:end-1);
nwin = size(winmat,2);
time = time(winmat(1,:)); %save starting timepoints of windows

nprm = 1000;
randidx = nan(nprm,size(rdm,1));

rsq_adj = nan(ncomb,nwin);
rsq_tot = nan(1,nwin);
rsq_rnd = nan(ncomb,nprm,nwin);

for ip = 1:nprm
    randidx(ip,:) = randperm(size(rdm,1));
end

for w = 1:nwin
    fprintf('\nWin %d\n', w)
    
    widx = winmat(:,iw);
    r = mean(rdm(:,widx),2);
    
    vp = rdm_varpart(r(:),m1,m2,m3,m4);
    
    rsq_adj(:,w) = vp.rsq_adj;
    rsq_tot(w) = vp.total_rsq;
    
    for ip = 1:nprm
        randrdm = rdm(randidx(ip,:),w);
        vprand = rdm_varpart(randrdm',sel_mod{1},sel_mod{2},sel_mod{3});
        rsq_rnd(:,ip,w) = vprand.rsq_adj;
    end
end

varpart.rsq_adj = rsq_adj;
varpart.rsq_tot = rsq_tot;
varpart.rsq_rnd = rsq_rnd;
varpart.vif = vp.vif; %this does not change across time
varpart.comb_labels = vp.comb_labels;
varpart.time = time;
    



end

