%getFileList
%   Syntax:  [filelist] = getFileList(filter,filedir)
%
%   Input:   filter     file name filter e.g. '*.csv'
%            filedir    directory
%
%   Outputs: filelist   char

function filelist = getFileList(filter,filedir)

filedir = strtrim(filedir);
if filedir(end) ~= filesep
    filedir = [filedir filesep];
end

locallist = ls([filedir filter]);

filelist = [repmat(filedir,size(locallist,1),1) locallist];