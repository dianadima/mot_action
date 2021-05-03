function [ rdm, rdm_tril ] = eeg_makerdm( data, varargin)
% Creates Euclidean distance EEG RDM from FT data or 3D matrix (channel x time x trial). Can create a time-resolved or spatiotemporally resolved RDM
% Input: data (trial x channel/source x time)
% Optional arguments in name-value pairs: 
%          'channels', channel set (string or cell array of strings; default: 'all').
%          'analysis_window' in this case, RSA analysis window (limits; default: [] - all timepoints). In  sampled time points (OR in seconds - only if you also provide time axis).
%          'window_length' (in sampled time points; default: 1).
%          'time', time axis, if you want to give the decoding window in seconds, you also need to provide a time axis, matching the second dimension of the data).
%          'sensor_idx', default [], sensor neighbours structure or cell array with source space searchlights/ROIs
%
%Output: Time-resolved E/MEG RDM in matrix and vector formats. (Feature x space x time, OR feature x time)
%
%DC Dima 2017 (diana.c.dima@gmail.com), adapted for EEG Feb 2020

p = inputParser;
addParameter(p, 'time',[]);
addParameter(p, 'analysis_window',[]);
addParameter(p, 'window_length',1);
addParameter(p, 'channels', 'all');
addParameter(p, 'sensor_idx', []); 
parse(p, varargin{:});
rsa_args = p.Results;
clear p

if isstruct(data)
    data = cat(3,data.trial{:});
end

%create time axis
if ~isempty(rsa_args.time)
    time = rsa_args.time;
elseif ~isempty(rsa_args.sensor_idx) && isfield(rsa_args.sensor_idx, 'time')
    time = rsa_args.sensor_idx.time;
else
    time = 1:size(data,2);
end


%time limits for analysis window
if ~isempty(rsa_args.analysis_window)
    lims(1) = nearest(time,rsa_args.analysis_window(1));
    lims(2) = nearest(time,rsa_args.analysis_window(2));  
else
    lims = [1 size(data,2)];
end

%here can simply include all possibilities of spatial selection 
%i.e. sensor sets, searchlight, AAL & source indices
if ~isempty(rsa_args.sensor_idx)
    if isstruct (rsa_args.sensor_idx) %the sensor-space case
        chan_idx = arrayfun(@(i) find(ismember({sensor_idx.label},[sensor_idx(i).label; sensor_idx(i).neighblabel])), 1:length(sensor_idx), 'UniformOutput', false); %store all searchlight idx in a cell array
    else
        chan_idx = source_idx; %the source-space case
    end
    
    %here write the searchlight itself
    tp = lims(1):rsa_args.window_length:lims(2)-rsa_args.window_length+1;
    
    rdm = zeros(size(data,3), size(data,3), length(chan_idx), length(tp));
    rdm_tril = zeros((size(data,3)*(size(data,3)-1))/2, length(chan_idx), length(tp)); %lower triangular part of matrix for correlations
    
    for c = 1:length(chan_idx)
        
        for t = 1:length(tp)
            
            Dtmp = reshape(data(chan_idx{c},tp(t):tp(t)+rsa_args.window_length-1,:),length(chan_idx{c})*rsa_args.window_length, size(data,3));
            D = pdist(Dtmp');
            D = (D-min(D(:)))./(max(D(:))-min(D(:)));
            rdm_tril(:,c,t) = D;
            rdm(:,:,c,t) = squareform(D);
            
        end
    
    end
       
else
    if isempty(rsa_args.channels) || strcmp(rsa_args.channels,'all')     
        chan_idx = 1:size(data,1);
    else
        chan_idx = rsa_args.channels;
    end
    
    data = data(chan_idx, :,:);
    tp = lims(1):rsa_args.window_length:lims(2)-rsa_args.window_length+1;
    
    rdm = zeros(size(data,3), size(data,3),length(tp));
    rdm_tril = zeros((size(data,3)*(size(data,3)-1))/2, length(tp));
    
    for t = 1:length(tp)
        Dtmp = reshape(data(chan_idx,tp(t):tp(t)+rsa_args.window_length-1,:),size(data,1)*rsa_args.window_length, size(data,3));
        D = pdist(Dtmp');
        D = (D-min(D(:)))./(max(D(:))-min(D(:)));
        rdm_tril(:,t) = D;
        rdm(:,:,t) = squareform(D); 
    end

    
end

    
end
