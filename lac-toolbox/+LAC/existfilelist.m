function [status, nMiss, missing] = existfilelist(filelist,folder)

statuslist = true(1,length(filelist));
for iFile = 1:length(filelist)   
    if ~exist(fullfile(folder,filelist{iFile}),'file')
        statuslist(iFile) = false;
    end
end
nMiss = sum(~statuslist);
missing = filelist(~statuslist);
status = min(statuslist);