function fileList=dir(searchStr)


[path, file, ext]=fileparts(searchStr);
jFile = java.io.File(path);
allTracksJ = char(jFile.list);
regStr = ['^',strrep(strrep([file ext],'?','.'),'*','.{0,}'),'$'];
starts = regexpi(cellstr(allTracksJ), regStr);
idxFiles = ~cellfun(@isempty, starts);
fileList = cellstr(allTracksJ(idxFiles,:));