%% plot results from both multiple arrangement experiments
%DC Dima 2021 (diana.c.dima@gmail.com)

addpath(genpath(pwd))

basepath = fileparts(fileparts(pwd));
respath1 = fullfile(basepath, 'results','multiple_arrangement','exp1'); %path to exp1 results
respath2 = fullfile(basepath, 'results','multiple_arrangement','exp2'); %path to exp2 results
datapath = fullfile(basepath, 'results','video_ratings');               %path to video features

% OSF paths
% basepath = pwd; %CHANGE
% respath1 = fullfile(basepath,'beh','results','exp1','results');
% respath2 = fullfile(basepath,'beh','results','exp2','results');
% datapath = fullfile(basepath, 'vid', 'video_info');

%% average behavioral RDMs

plot_rdms(respath1, respath2)

%% data reliability (leave-one-out correlations)

plot_reliability(respath1,respath2)

%% behavioral rating distributions

plot_ratings(datapath)

%% feature RDM intercorrelations

model_idx = plot_modelcorrs(respath1,respath2); %also outputs model ordering index for next figure

%% behavior-feature correlations

plot_rsa(respath1, respath2, model_idx)

%% variance partitioning

plot_varpart(respath1,respath2)






