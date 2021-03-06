function [tile_pos] = showTiles(start_directory, display)
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% [tile_pos] = showTiles(start_directory, display)
% SHOWTILES shows acquired positions from run, based on info.xml file generated by Zeiss
% ZEN (2013 only?)
%
% INPUT:
% start_directory    directory containing "meta.xml" file with XY positions
% display            (optional) flag to specify whether to show aquired positions on a 
%                        2-D plot (assumes FOV of 40x magnification on a Coolsnap camera)
%
% OUTPUT:
% tile_pos           all X- and Y-positions of aquired fields of view
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

if nargin<2
    display = 1;
end

info_files = dir(fullfile(start_directory,'*meta.xml'));
if isempty(info_files)
    error(['No meta.xml found not found in target directory ''', start_directory,''''])
end

% Read full file, pull out section pertaining to positions
if display
    disp('Reading meta.xml...')
end
all_settings = xml2struct(fullfile(start_directory,info_files(1).name));
expmt_settings = all_settings.ImageMetadata.Experiment.ExperimentBlocks.AcquisitionBlock;
if isfield(expmt_settings,'SubDimensionSetups')
    tile_settings = expmt_settings.SubDimensionSetups.TimeSeriesSetup.SubDimensionSetups...
        .RegionsSetup.SampleHolder.SingleTileRegions.SingleTileRegion;
elseif isfield(expmt_settings,'TilesSetup')
     tile_settings = expmt_settings.TilesSetup.SampleHolder.SingleTileRegions.SingleTileRegion;
else
    error('meta.xml doesn''t have ''SubDimensionSetups'' or ''TilesSetup'' field');
end

% Pull out individual tile positions, convert to number
tile_pos = zeros(length(tile_settings),2);
for i = 1:length(tile_settings)
    tile_pos(i,1) = str2double(tile_settings{i}.X.Text);
    tile_pos(i,2) = str2double(tile_settings{i}.Y.Text);
end
% Round to nearest 50 um
stepsize = 50;
tile_pos2 = round(tile_pos/stepsize)*stepsize;

if display
    % Create positional array
    x_vect = min(tile_pos2(:,1))-(stepsize*20) : stepsize : max(tile_pos2(:,1))+(stepsize*20);
    y_vect = min(tile_pos2(:,2))-(stepsize*20) : stepsize : max(tile_pos2(:,2))+(stepsize*20);
    all_pos = zeros(length(y_vect),length(x_vect));


    for i = 1:length(tile_settings)
        all_pos((tile_pos2(i,2)-min(y_vect))/stepsize,(tile_pos2(i,1)-min(x_vect))/stepsize)  = i;
    end

    disp_colormap = jet(length(tile_pos2));
    disp_colormap = cat(1, [1 1 1], disp_colormap);

    figure,imagesc(imdilate(all_pos,ones(7,5))), axis image, colormap(disp_colormap)
    set(gca, 'XTickLabel',''), set(gca, 'YTickLabel',''), title('Aquired positions during experiment')
    colorbar
end