function [set] = make_videoset_339(loadfile, savefile)

%load indices of previous set of videos
load(savefile, 'vid152_idx')
v = 1:491;
v(vid152_idx) = [];

load(loadfile,'ratingsZ','num_agents','watermark','env','categories','categories_idx','videolist');

set.environment = env(v);
set.numagents = num_agents(v);
set.sociality = nanmean(squeeze(ratingsZ(:,v,1)),1);
set.valence = nanmean(squeeze(ratingsZ(:,v,2)),1);
set.arousal = nanmean(squeeze(ratingsZ(:,v,3)),1);
set.action = nanmean(squeeze(ratingsZ(:,v,4)),1);
set.ratingsZ = ratingsZ(:,v,:);
set.watermark = watermark (v);
set.videolist = videolist(v);

for i = 1:numel(categories)
    set.categories_idx{i} = find(contains(videolist,categories{i}));
end

