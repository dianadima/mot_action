function [framearray_first,framearray_mid,framearray_avg,framearray_all] = extract_movie_frames(stimpath,stimuli,analysispath, varargin)
% extract frames from a list of videos and save them in cell arrays 
% Inputs: stimpath: the directory where videos are located
%         stimuli: cell array of video names
%         analysispath: directory where to save png images of frames (can be empty)
%         (optional) saving flag: if 0, images of frames + the frame arrays will NOT be saved in analysispath

fprintf('\nExtracting frames...\n')

nstim = numel(stimuli);

framearray_first = cell(1,nstim);
framearray_mid = cell(1,nstim);
framearray_avg = cell(1,nstim);
framearray_all = cell(1,nstim);

for istim = 1:length(stimuli)
    
    if strcmp(stimuli{istim}(1),'/')
        stimname = stimuli{istim}(2:end);
    else
        stimname = stimuli{istim};
    end
    obj = VideoReader(fullfile(stimpath,stimname));
    video = obj.read();
    
    %first frame
    first_frame = squeeze(video(:,:,:,1));
    if isempty(varargin) || varargin{1}~=0 %save by default
        imwrite(first_frame,fullfile(analysispath, strrep(stimname,'mp4', 'png')));
    end
    %middle frame
    mid_frame = squeeze(video(:,:,:,floor(size(video,4)/2)));
    if isempty(varargin) || varargin{1}~=0 %save by default
        imwrite(ave_frame,fullfile(analysispath, strrep(stimname,'.mp4', '_mid.png')));
    end
    
    %frame average
    ave_frame = squeeze(nanmean(video,4));
    if isempty(varargin) || varargin{1}~=0 %save by default
        imwrite(ave_frame,fullfile(analysispath, strrep(stimname,'.mp4', '_ave.png')));
    end
    
    framearray_first{istim} = first_frame;
    framearray_mid{istim} = mid_frame;
    framearray_avg{istim} = ave_frame;
    framearray_all{istim} = video;
        
end

if isempty(varargin) || varargin{1}~=0 %save by default
    save(fullfile(analysispath,'videoframes_sel.mat'),'framearray_first','framearray_mid','framearray_avg')
    save(fullfile(analysispath,'videoframes_all.mat'),'framearray_all')
end
