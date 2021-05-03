function [bigrdm] = sim_assignrdm(data, stimlist)
%place individual subjects' data into the full stimulus set RDM
%input: data (struct) and stimlist (cell array of all stimulus names)

rdm = data.rdm;
stim = {data.stimuli(:).name};

rdm = (rdm - min(rdm))./(max(rdm)-min(rdm));
rdm = squareform(rdm);

nstim = numel(stimlist);
nset = size(rdm,1);
bigrdm = nan(nstim,nstim);

idx = nan(nset,1);

for i = 1:nset
    idx(i) = find(contains(stimlist,stim{i}));
end

bigrdm(idx,idx) = rdm;



end