function [names,mturk_id] = sim_mturkid(mturkdatafile)
%make lists of Meadows participant IDs and mturk IDs so as to be able to match them
%input: file downloaded from mTurkID task on Meadows

[fpath,~,~] = fileparts(mturkdatafile);

d = jsondecode(fileread(mturkdatafile));
names = fieldnames(d);
mturk_id = cell(numel(names),1);

for i = 1:numel(names)
    datasub = getfield(d,names{i});
    mturk_id{i} = datasub.mTurkID;
end

save(fullfile(fpath,'mturk_ids.mat'),'names','mturk_id')






end