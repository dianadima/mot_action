function [] = subsample_videos(sub_idx,loadfile,loaddir,savefile,savedir)

if ~exist(savedir,'dir'),mkdir(savedir); end

nstim = length(sub_idx);
data = load(loadfile); 
nvid = length(data.videolist);
vars = fieldnames(data);

for v = 1:numel(vars)
    
        tmp = data.(vars{v});
        idx = find(size(tmp)==nvid);
        if isempty(idx)
            fprintf('\nSkipping %s...', vars{v});
        else
            if idx==2
                if ismatrix(tmp)
                    data.(vars{v}) = tmp(:,sub_idx);
                else
                    data.(vars{v}) = tmp(:,sub_idx,:);
                end
            elseif idx==1
                if ismatrix(tmp)
                    data.(vars{v}) = tmp(sub_idx,:);
                else
                    data.(vars{v}) = tmp(sub_idx,:,:);
                end
            end
        end
end

%create a new index corresponding to the new videolist
for c = 1:length(data.categories)
    data.categories_idx{c} = find(contains(data.videolist,data.categories{c}));
end

save(savefile,'-struct','data')

for s = 1:nstim
    if isfield(data,'fullvideolist')
        vidname = data.fullvideolist{s};
        if contains(vidname,'Videoset1'), [~,vidname] = fileparts(strrep(vidname,'.mp4','_1'));
        elseif contains(vidname,'Videoset2'), [~,vidname] = fileparts(strrep(vidname, '.mp4', '_2'));
        end
    else
        vidname = data.videolist{s};
    end
    copyfile(fullfile(loaddir,vidname), fullfile(savedir, vidname))

end

end

