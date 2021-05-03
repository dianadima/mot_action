function [coord, startframe] = preprocess_video(videofile, newfilename, nframes, targetsize, varargin)
% inputs: * path to original video
%         * path to new video file
%         * number of frames to keep (at a framerate of 24fps); if empty, original number of frames and framerate are kept
%         * target size as in [height width] (in pixels)
%         * optional: cropping coordinates (upper left corner to crop from:[y,x]) and start frame (for sequence selection).
%           If empty, will be determined interactively.
% outputs: cropping coordinates and start frame. 

vid = VideoReader(videofile);
vidframes_orig = vid.read();
vidsize = size(vidframes_orig);

if vid.FrameRate<23, warning('Low framerate: %s', videofile); end

%check that this gives 300x400 for all vids
if ~isempty(targetsize)
    tgh = targetsize(1)-1;
    tgw = targetsize(2)-1;
else %default to 256X312
    tgh = 255;
    tgw = 311;
end

if sum(vidsize(1:2)==targetsize)~=2
    if vidsize(1)==vidsize(2) || (vidsize(2)+vidsize(2)*((tgh-vidsize(1))/vidsize(1)))<tgw
        if vidsize(2)~=tgw
            for vf = 1:vidsize(4)
                vidframes(:,:,:,vf) = imresize(squeeze(vidframes_orig(:,:,:,vf)),[NaN tgw]);
            end
        end
    else
        if vidsize(1)~=tgh
            for vf = 1:vidsize(4)
                vidframes(:,:,:,vf) = imresize(squeeze(vidframes_orig(:,:,:,vf)),[tgh NaN]);
            end
        end
    end
else
    vidframes = vidframes_orig;
end

if ~isempty(varargin) && ~isempty(varargin{1})
    coord = varargin{1};
else
    fprintf('\nVideo width is now %d pixels\n', size(vidframes,2))
    imshow(vidframes(:,:,:,2))
    datacursormode on
    coord = input('Upper left corner coordinates (y,x): ');
end

if ~isempty(coord) && tgh+coord(1)<=size(vidframes,1) && tgw+coord(2)<=size(vidframes,2)   
    hdiff = coord(1); wdiff = coord(2);
else %crop centrally
    hdiff = ceil((size(vidframes,1)-tgh)/2);
    wdiff = ceil((size(vidframes,2)-tgw)/2);
    coord = [hdiff wdiff];
    fprintf('\nWarning: cropping centrally\n')
end

close

newvid = VideoWriter(newfilename,'MPEG-4');

if ~isempty(nframes)
    newvid.FrameRate = 24;
    if ~isempty(varargin) && numel(varargin)>1 && ~isempty(varargin{2})
        startframe = varargin{2};
    else
        implay(videofile)
        startframe = input('Start frame: '); %avoid first frame, sometimes blank
    end
else %3 second videos at 24 fps
    nframes = 24*3; 
    startframe = 1;
    if vidsize(4)<nframes, nframes = vidsize(4); newvid.FrameRate = vid.FrameRate; %true for 3 videos
    else, newvid.FrameRate = 24; % set this to same across videos 
    end
end

if startframe>vidsize(4)-nframes+1, startframe = vidsize(4)-nframes+1; fprintf('\nWarning: start frame changed to %d\n', startframe); end
if startframe==0, startframe = 1; end

open(newvid)

for f = startframe:startframe+nframes-1
    
    frame = squeeze(vidframes(:,:,:,f));
    frame = imcrop(frame, [wdiff hdiff tgw tgh]);
    writeVideo(newvid,frame);
    
end

fprintf('\nVideo is %d by %d... Done\n', newvid.Height,newvid.Width) 
imshow(frame)
pause(1)



end