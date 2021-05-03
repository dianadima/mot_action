function [badtrl] = eeg_badtrialidx(art,rawdata)
%get trial indices based on FT artefact definition structure and original data
%helper function

badtrl = [];
if ~isempty(art)   
    for i = 1:size(art,1)
        badtrl = [badtrl; find(rawdata.sampleinfo(:,1)<=art(i,1)&rawdata.sampleinfo(:,2)>=art(i,2))];
    end
end

end

