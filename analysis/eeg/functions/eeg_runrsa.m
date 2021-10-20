function [ correlation_matrix, time ] = eeg_runrsa (eeg_rdm, models, time, type)
% Run Representational Similarity RSA by comparing a MEG RDM to models over time.
% Input: eeg_rdm (features x time or features x time x space), models (features x num models)
% Output: correlation matrix (time x models or time x space x models)
%
% DC Dima 2017 (diana.c.dima@gmail.com), adapted for EEG Feb 2020

nmod = size(models,2);

if isempty(time)
    nwin = size(eeg_rdm,2);
else
    ws = 5; %10 ms - window size in timepoints
    ov = 3; %6 ms overlap
    t = 1:length(time);
    winmat = buffer(t,ws,ov);
    winmat = winmat(:,3:end-1);
    nwin = size(winmat,2);
    time = time(winmat(1,:));
end

if ismatrix(eeg_rdm) %features by time
    
    correlation_matrix = zeros(nwin, nmod);
    
    switch type
        case 'spearman'
            
            for t = 1:nwin %across time
                
                if isempty(time)
                    widx = t;
                else
                    widx = winmat(:,t);
                end
                rdm = squeeze(nanmean(eeg_rdm(:,widx),2));
                x = [rdm(:) models];
                corrmat = corr(x, 'type', 'Spearman','rows','pairwise');
                correlation_matrix(t,:) = corrmat(1,2:nmod+1);
                
            end
            
        case 'kendall'
            
            parfor t = 1:nwin %across time
                
                widx = winmat(:,t);
                rdm = squeeze(mean(eeg_rdm(:,widx),2)); %#ok<PFBNS>
               % rdm = squeeze(eeg_rdm(:,t));
                
                for m = 1:nmod       
                    correlation_matrix(t,m) = rankCorr_Kendall_taua(rdm(:),models(:,m));
                end
            end
            
    end
    
elseif ndims(eeg_rdm)==3 %features by time by space
    
    nroi = size(eeg_rdm,3);  
    correlation_matrix = zeros(nwin, nroi, nmod);
    
    switch type
        case 'spearman'
            
            for s = 1:nroi %in space
                
                for t = 1:nwin %in time
                    
                    rdm = squeeze(eeg_rdm(:,t,s));
                    x = [rdm(:) models];
                    corrmat = corr(x, 'type', 'Spearman','rows','pairwise');
                    correlation_matrix(t,s,:) = corrmat(1,2:size(models,2)+1);
                    
                end
                
            end
            
        case 'kendall'
            
            for s = 1:nroi %in space
                
                for t = 1:nwin %in time
                    
                    rdm = squeeze(eeg_rdm(:,t,s));
                    
                    for m = 1:nmod
                        correlation_matrix(t,s,m) = rankCorr_Kendall_taua(rdm(:),models(:,m));    
                    end
                    
                end
                
            end
    end
    
end

correlation_matrix = squeeze(correlation_matrix);

end