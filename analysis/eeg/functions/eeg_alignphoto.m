function [data] = eeg_alignphoto(data, toilim)
%realign trials to photodiode onset
%searches for photodiode down flanks within specified toilim
%assumes channel is labelled Photodiode
%uses a z-score threshold of -1 to detect triggers
% D.C. Dima (diana.c.dima@gmail.com) Feb 2020

%get the data into matrix format
trl = cat(3,data.trial{:});

%look for photodiode onsets within a limited time window
%to avoid finding previous/next trial triggers
time = data.time{1};
t1 = nearest(time,toilim(1));
t2 = nearest(time,toilim(2));
trl = trl(:,t1:t2,:);

ntmp = size(trl,2);
ntrl = size(trl,3);

%get and normalize photodiode data
photoidx = contains(data.label,'Photodiode');
photodat = squeeze(trl(photoidx,:,:));
% m = nanmean(photodat(1:200,:),1);
% s = nanstd(photodat(1:200,:),[],1);
% photodat = abs(photodat.\repmat(m,ntmp,1)*100);
% photodat = (photodat - repmat(m,ntmp,1))./repmat(s,ntmp,1);
photodat = (photodat - repmat(nanmean(photodat,1),ntmp,1))./repmat(std(photodat,[],1),ntmp,1);
photosmp = nan(ntrl,1);

%triggers are detected based on z-score; here adjust for photodiode
%settings that have been changed after sub8
thresh = -0.1;
subnum = str2double(data.cfg.headerfile(end-6:end-5));
if ismember(subnum, 1:7), thresh = -1; end

if subnum==13
    offsets = repmat(135,ntrl,1);
else

%here we can interactively adjust threshold based on figure - uncomment below
% figure;plot(time(t1:t2),photodat)
% t = input(sprintf('Threshold for photodiode triggers is %.1f. Change or press Enter: ', thresh));
% if ~isempty(t) && isnumeric(t), thresh = t; end 
% close

% down or up triggers
for itrl = 1:ntrl
    if thresh<=0
        photosmp(itrl) = find(photodat(:,itrl)<thresh,1);
    else
        photosmp(itrl) = find(photodat(:,itrl)>thresh,1);
    end
end

%sometimes (n=3) the photodiode triggers don't work as expected in ~20% of trials
badtrl = photosmp<300; %remove bad trigger trials
photosmp(badtrl) = mean(photosmp(~badtrl)); %these will be read in based on average offset and removed later

%get offset from 0 based on original time axis
zerotime = nearest(time(t1:t2),0);
offsets = photosmp-zerotime; %negative offset if trial began before new trigger

end

%realign the trials
cfg = [];
cfg.offset = -offsets; %the offsets are added to the current time to create new time axis
cfg.trials = 'all';
% cfg.begsample = round(offsets-0.2*data.fsample);
% cfg.endsample = round(offsets+1*data.fsample);
%cfg.overlap = 1;
data = ft_redefinetrial(cfg,data);

% %cut the epochs of interest (non-overlapping and only up to 1 s after onset)
% cfg = [];
% cfg.toilim = toilim;
% data = ft_redefinetrial(cfg,data);

%data.badtrials_photo = badtrl;

%check that the realignment worked
si = reshape(data.sampleinfo',numel(data.sampleinfo),1);
if ~isempty(find(diff(si)<0,1))
    warning('\nThere is some overlap in trials after realignment!')
end

%here we can interactively adjust threshold based on figure - uncomment below
time = data.time{1};
trl = cat(3,data.trial{:});ntmp = size(trl,2);
photoidx = contains(data.label,'Photodiode');
photodat = squeeze(trl(photoidx,:,:));
photodat = (photodat - repmat(nanmean(photodat,1),ntmp,1))./repmat(std(photodat,[],1),ntmp,1);
% figure;plot(time,photodat)
% t = input('Continue?');


end

