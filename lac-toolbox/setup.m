currentpath = cd(fileparts(mfilename('fullpath')));
addpath(currentpath);
addpath(genpath(fullfile(currentpath,'External')));
fprintf('Succesfully added paths for LACtoolbox to matlab:\n%s\n%s\n',currentpath,genpath(fullfile(currentpath,'External')));

folders = dir(fullfile(currentpath,'Programs'));
folderNames = {folders([folders.isdir]).name}';
folderNames = folderNames(cellfun(@isempty,regexp(folderNames,'^(\.|\.\.)$')));

selection = listdlg('PromptString','Select a Program:',...
                'ListString',folderNames,'ListSize',[200 100],'Name','Programs');
for folder_i = 1:length(selection)
   addpath(genpath(fullfile(currentpath,'Programs',folderNames{selection(folder_i)})));
   fprintf('Added program ''%s'' to path\n',folderNames{selection(folder_i)});
end

clear currentpath folders folderNames selection folder_i