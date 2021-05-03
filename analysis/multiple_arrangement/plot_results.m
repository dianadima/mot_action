% plot results from both experiments

addpath(genpath(pwd))

basepath = fileparts(fileparts(pwd));
respath1 = fullfile(basepath, 'results','multiple_arrangement','exp1');
respath2 = fullfile(basepath, 'results','multiple_arrangement','exp2');

%% average RDMs

plot_rdms(respath1, respath2)

%% data reliability

plot_reliability(respath1,respath2)

%% model intercorrelations

model_idx = plot_modelcorrs(respath1,respath2); %also outputs model ordeing index for next figure

%% behavior-model correlations

plot_rsa(respath1, respath2, model_idx)

%% variance partitioning

plot_varpart(respath1,respath2)



