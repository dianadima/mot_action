function [decoding_accuracy, decoding_matrix] = eeg_decode(outpath)
% pairwise video decoding using fusionlab toolbox
% trials are averaged within folds (k-fold CV) and randomly assigned to folds using specified number of permutations
% plots average accuracy over subjects and pairs
% action perception experiment

%outputs
outfile = 'pairwise_decoding_accuracy_pseudo.mat';
[~,figfile] = fileparts(outfile);
figpath = fullfile(outpath, 'Figures'); 
if ~exist(figpath,'dir'), mkdir(figpath); end

%get the number of subjects based on files present in the data directory
subdir = dir(outpath); subdir = {subdir(3:end).name}; 
subdir = subdir(cellfun(@(x) ~isnan(str2double(x)), subdir));
nsub = numel(subdir);

%output variables
decoding_accuracy = cell(1,nsub);
decoding_matrix = [];

for isub = 1:nsub

    %get subject specific paths and filenames
    sub = sprintf('%02.f',isub);
    suboutpath = fullfile(outpath, sub);
    datafile = fullfile(suboutpath, [sub 'data.mat']);

    data = load(datafile);
    [datamatrix, condid] = eeg_preparerdm(data,0); %use 0 to keep all observations for decoding
    dec = fl_decodesvm(datamatrix,condid, 'method', 'pairwise','numpermutation',10, 'kfold',4);
    decoding_accuracy{isub} = dec;
    if size(dec.d',1)<size(decoding_matrix,2)
        d = nan(size(decoding_matrix,2),size(decoding_matrix,3)); 
        d(1:size(dec.d',1),:) = dec.d';
    else
        d = dec.d';
    end
    decoding_matrix(isub,:,:) = d; %#ok<AGROW>
end

save(fullfile(outpath,outfile),'decoding_accuracy','decoding_matrix');

figure
macc = squeeze(mean(mean(decoding_matrix,2),1));
eacc = squeeze(std(mean(decoding_matrix,2),[],1))/sqrt(nsub);
plot_time_results(macc,eacc,'time',data.time{1},'ylim',[45 75])
print(gcf,'-r300','-dpng',fullfile(figpath,figfile))

end

