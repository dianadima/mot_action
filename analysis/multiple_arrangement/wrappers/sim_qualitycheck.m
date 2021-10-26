function [] = sim_qualitycheck(rdmfile)
% excludes participants with low reliability on training RDM
% plots & saves reliability using different metrics
% input: file with rdm and training data
% output: none (saves updated input file)
% DC Dima 2020 (diana.dima@gmail.com)

%load data
load(rdmfile,'rdm','qc','full')

%get path to save figures
[fpath,~,~] = fileparts(rdmfile);
fpath = fullfile(fpath,'figures');
if ~exist(fpath,'dir'), mkdir(fpath); end

%if the script is being rerun take the full rdm
if exist('full','var')
    rdm = full.rdm;
    qc = full.qc;
else
    %save the data prior to exclusions
    full.qc = qc;
    full.rdm = rdm;
end

%first check reliability of training data - use Kendall's tau-A
qc_nc = sim_reliability(qc.rdm, fpath, 'Training RDM before exclusions',[]);
qc_looK = qc_nc.looK;

%get participants with too low reliability on training data
threshold = mean(qc_looK)-2*std(qc_looK);
unreliable_idx = qc_looK<=threshold;

fprintf('\n%d participants out of %d below threshold\n', sum(unreliable_idx),size(qc.rdm,1));
qc.rdm(unreliable_idx,:,:) = [];
rdm(unreliable_idx,:,:) = [];

%final reliability plots for training data & full data
close all
qc_nc = sim_reliability(qc.rdm, fpath, 'Training RDM', [0.5 0.8 0.7]);
qc.nc = qc_nc;

nc = sim_reliability(rdm, fpath, 'Full RDM' , []);

save(rdmfile,'-append','qc','rdm','full','nc','unreliable_idx')


end