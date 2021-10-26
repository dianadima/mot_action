function [data] = sim_appenddata(data, datapath)
% append additional files to the main dataset
% these are files downloaded individually for participants who did not hit
% 'complete' at the end but did complete the main task in Meadows

%find the datafile in the directory
files = dir(datapath);
files = {files(:).name};
files = files(contains(files, '.json'));

for isub = 1:numel(files)
    
    %get subject name from filename
    subname = files{isub}(strfind(files{isub},'_v_v')+6:strfind(files{isub},'_tree')-1);
    subname = strrep(subname,'-','_');
    
    d = jsondecode(fileread(fullfile(datapath,files{isub})));
    data.(subname) = d;
    
end











end