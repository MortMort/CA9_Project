function [parameterPathList,TimeStamp] = getCTRparameterPathList(CTRpath)
% [parameterPathList,TimeStamp] = getCTRparameterPathList(CTRpath)
% Function to get the parameter files from the CTR file
% NIWJO 2019

delimiter = '';
formatSpec = '%q%*s%*s%*s%*s%[^\n\r]';
fileID = fopen(CTRpath,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fclose(fileID);
FileInfo = dir(CTRpath);
TimeStamp = FileInfo.date;
AuxDLLlist = dataArray{1}(contains(dataArray{1},'AuxDLL'));
K = 0;
for II = 1:length(AuxDLLlist)
    if ~isempty(strfind(AuxDLLlist{II},'.dll'))
        K = K+1;
        parameterPathList{K} = AuxDLLlist{II}(strfind(AuxDLLlist{II},'.dll')+5:strfind(AuxDLLlist{II},'Initialize Controller')-2);
    end
end
end
