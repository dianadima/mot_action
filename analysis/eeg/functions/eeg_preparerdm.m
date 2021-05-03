function [datamatrix, condid, labels] = eeg_preparerdm(data, avgflag)
%prepare EEG data for RSA or classification
%if avgflag is 1, data are reordered and averaged within condition so as to match the RSA models
%if avgflag is 0, data are reordered according to stimulus numbers so as to match the RSA models
%                 a cell array 'condid' is created for pairwise video decoding

nvid = max(data.triallist);

trial = cat(3,data.trial{:});
if avgflag
    datamatrix = nan(size(trial,1), size(trial,2), nvid);
else
    datamatrix = nan(size(trial)); 
    condid = cell(1,nvid);
    labels = nan(1,nvid);
    count = 1;
end
    
for ivid = 1:nvid
    
    tmp = trial(:,:,data.triallist==ivid);
    if avgflag
        datamatrix(:,:,ivid) = squeeze(nanmean(tmp,3));
    else
        nobs = size(tmp,3);
        if nobs>=2
            datamatrix(:,:,count:count+nobs-1) = tmp;
            labels(count:count+nobs-1) = ivid;
            condid(count:count+nobs-1) = {num2str(ivid)};
            count = count+nobs;
        end
    end
end

if ~avgflag
    condid(cellfun(@isempty,condid)) = [];
    if count<size(datamatrix,3), datamatrix(:,:,count+1:end) = []; end
end


        
    
    




end

