function [magn, ornt, of_x, of_y] = get_optic_flow(videolist, inputsize)
%extract optic flow from a set of videos (Horn-Shunck algorithm)
%save magnitude, orientation, Vx and Vy, averaged across frames
%Inputs: videolist = cell array of video paths to load
%        inputsize = frame size to reduce videos to (to speed up calculation)
%DC Dima 2020 (diana.c.dima@gmail.com)


nvid = numel(videolist);
ornt = nan(nvid, prod(inputsize)); %orientation
magn = nan(nvid, prod(inputsize)); %magnitude
of_x = nan(nvid, prod(inputsize)); %x component
of_y = nan(nvid, prod(inputsize)); %y component

%video loop
for v = 1:nvid
    
    vid = VideoReader(videolist{v});
    oF = opticalFlowHS;
    
    or = nan(prod(inputsize),ceil(vid.FrameRate*vid.Duration));
    mg = or; ox = or; oy = or;
    count = 0;
    
    %frame loop
    while hasFrame(vid)
        count = count+1;
        frameRGB = readFrame(vid);
        if size(frameRGB,1)~=inputsize(1) || size(frameRGB,2)~=inputsize(2)
            frameRGB = imresize(frameRGB, inputsize);
        end
            
        frameGray = rgb2gray(frameRGB);
        flow = estimateFlow(oF,frameGray); %flow object, contains Orientation & Magnitude, size h x w
        or(:,count) = flow.Orientation(:);
        mg(:,count) = flow.Magnitude(:);
        ox(:,count) = flow.Vx(:);
        oy(:,count) = flow.Vy(:);

    end
    
    of_x(v,:) = squeeze(nanmean(ox,2)); 
    of_y(v,:) = squeeze(nanmean(oy,2)); 
    ornt(v,:) = squeeze(nanmean(or,2)); 
    magn(v,:) = squeeze(nanmean(mg,2)); 
    
end
    


end

