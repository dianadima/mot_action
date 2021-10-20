function [decoding_accuracy, decoding_matrix] = eeg_decode(outpath)
% pairwise video decoding using fusionlab toolbox
% trials are averaged within folds (k-fold CV) and randomly assigned to folds using specified number of permutations
% plots average accuracy over subjects and pairs
% action perception experiment

%outputs
outfile = 'decoding_accuracy.mat';

[~,figfile] = fileparts(outfile);
figpath = fullfile(outpath, 'Figures'); 
if ~exist(figpath,'dir'), mkdir(figpath); end

%get the number of subjects based on files present in the data directory
subdir = dir(outpath); 
subdir = {subdir(3:end).name}; 
subdir = subdir(cellfun(@(x) ~isnan(str2double(x)), subdir));
nsub = numel(subdir);

%store results
decoding_accuracy = cell(1,nsub);
decoding_matrix = [];

for isub = 1:nsub
    
    %get subject specific paths and filenames
    sub = sprintf('%02.f',isub);
    suboutpath = fullfile(outpath, sub);
    datafile = fullfile(suboutpath, [sub 'data.mat']);

    data = load(datafile);
    
    [datamatrix, condid] = eeg_preparerdm(data,0); %use 0 to keep all observations for decoding

    dec = fl_decodesvm(datamatrix,condid, 'method', 'pairwise','numpermutation',10, 'kfold',2);
    
    decoding_accuracy{isub} = dec;
    decoding_matrix(isub,:,:) = dec.d';  %#ok<*AGROW>
        
end

time = data.time{1};

%stats: test decoding - chance level against 0
chancelevel = 50;
m = squeeze(nanmean(decoding_matrix,2));
m = m - chancelevel;
[~,obs,rand] = randomize_rho(m);

%cluster correction
opt = [];
opt.alpha = 0.05;
opt.clusterstatistic = 'maxsum';
cluster = find2Dclusters(obs,rand,[]);
if ~isempty(cluster.sigclusters)
    clustersig = cluster.sigtime;
end

save(fullfile(outpath,outfile),'-v7.3','decoding_accuracy','decoding_matrix','time','clustersig','cluster');

% plot accuracy
figure
macc = squeeze(nanmean(nanmean(decoding_matrix,2),1));
eacc = squeeze(nanstd(nanmean(decoding_matrix,2),[],1))/sqrt(nsub);
plot_time_results(macc,eacc,'time',time,'ylim',[47 67],'signif',time(clustersig==1),'signif_ylocation',49)
set(gca,'FontSize',18);xticks(0:0.2:1)
set(gca,'xgrid','on'); set(gca,'ticklength',[0.001 0.001])
print(gcf,'-r300','-dpng',fullfile(figpath,figfile))


end

