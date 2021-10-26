function [] = sim_combinedata(file1,file2,savefile)
% combine two batches of multiple arrangement data (Exp 1) and save them in a combined file
% inputs: file1, file2, filename to save

d1 = load(file1);
d2 = load(file2);

%concatenate everything
rdm = cat(1,d1.rdm,d2.rdm);
exclude_idx = [d1.exclude_idx;d2.exclude_idx];
incompl_idx = [d1.incompl_idx;d2.incompl_idx];
catch_answers = cat(1,d1.catch_answers,d2.catch_answers);
feedback = [d1.feedback;d2.feedback];
mturk_id = [d1.mturk_id;d2.mturk_id];

qc.rdm = cat(1,d1.qc.rdm,d2.qc.rdm);
qc.stimlist = d1.qc.stimlist;

clear d1 d2
save(savefile, '-v7.3','rdm','exclude_idx','incompl_idx','catch_answers','feedback','mturk_id','qc','file1','file2')



end