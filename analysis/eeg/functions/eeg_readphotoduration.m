function [stimdur] = eeg_readphotoduration(hdrfile,eegfile,prcfile)
%determine actual stimulus durations based on photodiode triggers

%define trials and read in raw data
cfg = [];
cfg.headerfile = hdrfile;
cfg.datafile   = eegfile;
cfg.trialdef.eventtype = 'Stimulus';
cfg.trialdef.eventvalue = 'S  1';    %align trials to video onset
cfg.trialdef.prestim = 0.2;
cfg.trialdef.poststim = 1.2;         %read in larger epochs to help with alignment to photodiode triggers
cfg = ft_definetrial(cfg);  
data = ft_preprocessing(cfg);

%where to look for start and end triggers
toilims = {[-0.2 0.5]; [0.5 0.8]};
viddur = 500;

%get the data into matrix format
trial = cat(3,data.trial{:});
time = data.time{1};

ntrl = size(trial,3);
offsets = nan(ntrl,2);

for t = 1:2
    
    toilim = toilims{t};
       
    %look for photodiode onsets within a limited time window
    t1 = nearest(time,toilim(1));
    t2 = nearest(time,toilim(2));
    trl = trial(:,t1:t2,:);
    ntmp = size(trl,2);
 
    %get and normalize photodiode data
    photoidx = contains(data.label,'Photodiode');
    photodat = squeeze(trl(photoidx,:,:));
    photodat = (photodat - repmat(nanmean(photodat,1),ntmp,1))./repmat(std(photodat,[],1),ntmp,1);
    photosmpt = nan(ntrl,1);
    
    %triggers are detected based on z-score; here adjust for photodiode
    %settings that have been changed after sub8
    subnum = str2double(data.cfg.headerfile(end-6:end-5));
    if t==1 %look for down triggers (start)
        thresh = -0.1;
        if ismember(subnum, 1:7), thresh = -1; end
    else %look for up triggers (end)
        thresh = 0.1;
        if ismember(subnum, 1:7), thresh = 1; end
    end
    
    % detect timepoints
    for itrl = 1:ntrl
        if thresh<=0
            photosmpt(itrl) = find(photodat(:,itrl)<thresh,1);
        else
            photosmpt(itrl) = find(photodat(:,itrl)>thresh,1);
        end
    end
    
    %sometimes (n=3) the photodiode triggers don't work as expected in ~20% of trials
    if t==1
        badtrl = photosmpt<300; %remove bad trigger trials
    else
        badtrl = photosmpt<100 | photosmpt>200;
    end
    photosmpt(badtrl) = mean(photosmpt(~badtrl)); %these will be read in based on average offset and removed later

    
    %get offset from 0 based on original time axis
    zerotime = nearest(time(t1:t2),0); %this will return offset from 500 ms for t=2 
    offsets(:,t) = photosmpt-zerotime; %negative offset if trial began before new trigger


end

stimdur = viddur + offsets(:,2) - offsets(:,1);
save(prcfile,'-append','stimdur')

end

    