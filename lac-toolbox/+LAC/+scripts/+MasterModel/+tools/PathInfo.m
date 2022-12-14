function [path_info, path_funcs] = PathInfo(PathListLocation)
% Function that checks the existence of necessary data in the postlaods
% files specified in the pathlist
% Author YAYDE
% Last checked by YAYDE - 04/11/2019

% Load the list
fileList = fopen(PathListLocation,'r');
info = textscan(fileList,'%s','Delimiter','\n');
fclose(fileList);

% Build the full path to intpostd Main output file
variantPaths = info{1,1};
path_funcs.path = cellfun(@(names) fullfile(names,'\MAIN\Mainload.txt'),variantPaths,'UniformOutput',0);
% Check availability
allPaths = cellfun(@(n) exist(n,'file')==2,path_funcs.path,'UniformOutput',0);

% Return output
path_info = table(variantPaths, [allPaths{:}]', 'VariableNames',{'Paths','Availability'});























