function [p] = eeg_savepreproc(prcfile,isub,p)

%save artefact rejection data across participants
load(prcfile) %#ok<LOAD>
p.badchan_num(isub) = 64 - num_channels;
p.trlcatch_num(isub) = sum(catch_trl);
p.trlcatch_prc(isub) = sum(catch_trl)/numel(catch_trl);

badtrl = idx_badtrial;
badtrl(catch_trl) = 0;
p.trlbad_num(isub) = sum(badtrl);
p.trlbad_prc(isub) = sum(badtrl)/(numel(badtrl)-p.trlcatch_num(isub));

if isub~=13
    p.stimdur_avg(isub) = mean(stimdur);
    p.stimdur_std(isub) = std(stimdur);
else
    p.stimdur_avg(isub) = NaN;
    p.stimdur_std(isub) = NaN;
end

p.muscle_zval(isub) = muscle_zvalue;


end

