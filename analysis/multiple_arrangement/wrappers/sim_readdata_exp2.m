function [rdm] = sim_readdata_exp2(datapath,savefile)
%read and save Meadows MA data from json files - Experiment 2
%datapath: data directory
%savefile: data file to be saved

nstim = 65; %hard-coded

%find the datafile in the directory
files = dir(datapath);
files = {files(:).name};
files = files{contains(files, '.json')};

data = jsondecode(fileread(fullfile(datapath,files)));

%append datasets in which people didn't hit 'submit'
data = sim_appenddata(data, fullfile(datapath,'additional'));

%save all data as a .mat file
save(fullfile(datapath,'rep_data.mat'),'data')

subnames = fieldnames(data);
nsub = numel(subnames);

incompl_idx = false(nsub,1); %mark incomplete participants
exclude_idx = false(nsub,1); %mark participants excluded after QC

rdm = nan(nsub,nstim,nstim);
rdm_qc = nan(nsub,8,8); %8 stimuli per training

catch_answers = cell(nsub,3);
feedback = cell(nsub,1);
%mturk_id = cell(nsub,1);

gender = nan(nsub,1);
age = nan(nsub,1);

for isub = 1:nsub
    
    %check if MA task was finished
    datasub = getfield(data,subnames{isub});
   % mturk_id{isub} = datasub.tasks{1}.mTurkID;
    
    
    %first check that they finished the MA task
    if ~strcmp(datasub.tasks{9}.status, 'finished')
        
        incompl_idx(isub) = 1;
        
    else
        
        if isub==1 %get stimulus list in order
            stimlist = datasub.tasks{1}.stimuli;
            stimlist = {stimlist(:).name};
            stimlist = sort(stimlist);
        end
        
        %get age and gender
        pinfo = datasub.tasks{2};
        gender(isub) = strcmp(pinfo.gender,'female');
        age(isub) = str2double(pinfo.age);
        
        %display catch trials and select participants based on them
        ct = datasub.tasks{8};
        catch_answers{isub,1} = ct.Video1;
        catch_answers{isub,2} = ct.Video2;
        catch_answers{isub,3} = ct.Video3;
        feedback{isub} = datasub.tasks{10}.Feedback;
        
        fprintf('Catch answers for sub %d\n, %s\n,%s\n,%s\n', isub, ct.Video1, ct.Video2, ct.Video3);
        fprintf('\nFeedback: %s\n', feedback{isub})
        x = input('Exclude? Y/N: ', 's');
        
        %no point extracting data for excluded subjects
        if strcmp(x,'Y')
        
            exclude_idx(isub) = 1;
        
        else
            
            %training matrix
            qc = datasub.tasks{6};
            qcstim = {qc.stimuli(:).name};
            [stimlist_qc,idx] = sort(qcstim);
            rdmqcsub = squareform(qc.rdm);
            rdm_qc(isub,:,:) = rdmqcsub(idx,idx);
            
            %full matrix - sort & normalize
            df = datasub.tasks{9};
            rdm(isub,:,:) = sim_assignrdm(df,stimlist);            
            
            
        end
        
    end
    
end

%remove participants who did not complete or were excluded
idx = incompl_idx|exclude_idx;
rdm_qc(idx,:,:) = [];
rdm(idx,:,:) = [];

%save training & MA data
qc = [];
qc.stimlist = stimlist_qc;
qc.rdm = rdm_qc;

save(savefile, 'qc', 'rdm', 'exclude_idx', 'incompl_idx','age','gender', 'stimlist','catch_answers', 'feedback');%,'mturk_id')




















end