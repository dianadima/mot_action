function [] = plot_rdm(rdm,categories,categories_idx,colbar,textflag)
% plot the lower triangle of a symmetric matrix 
% Inputs: rdm, symmetric matrix or vectorized lower/upper triangle
%         categories, names of data categories if present (otherwise [])
%         categories_idx, grouping cell array with category indices
%         colbar, colorbar (1/true or 0/false)
%         textflag, add values to matrix cells (1/true or 0/false)
%
% DC Dima 2020 (diana.c.dima@gmail.com)


%transform into matrix if needed
if isvector(rdm), rdm = squareform(rdm); end

%each category is one cell
if isempty(categories_idx)
    categories_idx = repmat(1:size(rdm,1),2,1)';
end

if iscell(categories_idx)
    categ_idx = nan(length(categories_idx),2);
    for i = 1:length(categories_idx)
        categ_idx(i,1) = categories_idx{i}(1);
        categ_idx(i,2) = categories_idx{i}(end);
    end
    categories_idx = categ_idx;
end

%mask upper triangle
mask = tril(ones(size(rdm)),-1);
mask(mask==0) = NaN;

%plot
imagesc(rdm,'AlphaData',mask)
try colormap(viridis); catch, colormap(parula); end
hold on

%draw lines to divide groups of stimuli
xlimpos = get(gca,'xlim');
if categories_idx(:,1)~=categories_idx(:,2) % do not print lines
    for i = 1:length(categories_idx)
        pos = categories_idx(i,2)+0.5; %to get to the end of the pixel, add 0.5
        line([pos pos], xlimpos, 'color','w');hold on
        line(xlimpos, [pos pos], 'color', 'w')
    end
end

%set axis limits to avoid diagonal cells
xlim([xlimpos(1) xlimpos(2)-1])
ylim([xlimpos(1)+1 xlimpos(2)])

%set ticks and labels
tickpos = mean(categories_idx,2);
xticks(tickpos)
xticklabels(categories);
yticks(tickpos)
yticklabels(categories);
if ~isempty(categories) && iscell(categories(1)) && length(categories{1})>3
    xtickangle(90)
end

set(gca,'TickLength',[0.001 0.001])
set(gca,'FontSize',18)

%draw colorbar if required
if colbar
    c = colorbar;
    c.Label.String = 'Euclidean distance';
end

if textflag
    rdm(isnan(mask)) = NaN;
    for mi = 1:size(rdm,1)
        for mj = 1:size(rdm,2)
            if ~isnan(rdm(mi,mj)) && rdm(mi,mj)>=0.1
                text(mj,mi, sprintf('%.02f',rdm(mi,mj)),'Color','w','FontSize',10,'HorizontalAlignment','center');
            end
        end
    end
end


box off



end