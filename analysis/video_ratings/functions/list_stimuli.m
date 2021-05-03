function [videolist, categories, categories_idx] = list_stimuli(stimpath)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

videolist = {};
categories = dir(stimpath); 
categories = {categories(3:end).name}; %remove first 2 which are not subdirectories
for c = 1:length(categories)
    categlist = dir(fullfile(stimpath,categories{c}));
    videolist = [videolist {categlist(3:end).name}]; %#ok<AGROW>
end
videolist = videolist';
videolist(contains(videolist, '.DS')) = []; %remove hidden .DSstore files

%get categories_idx variable
categories_idx = cell(1,length(categories));
for c = 1:length(categories_idx)
    categories_idx{c} = find(contains(videolist,categories{c}));   
end
end

