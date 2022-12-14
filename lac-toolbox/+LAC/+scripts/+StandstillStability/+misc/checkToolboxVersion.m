function  result = checkToolboxVersion(path2Directory)
%toolboxVersion = checkToolboxVersion
% Checks if the current version of the toolbox is the same as the version
% that created this setup 
if nargin < 1
     [path2Directory, ~, ~] = fileparts(mfilename('fullpath'));
end

result = 0;
%Calculate hash of all m-files in
md5Hash = LAC.scripts.StandstillStability.misc.calcDirectoryMD5;
md5HashOld = fileread('toolboxHash');
if(~strcmp(md5Hash,md5HashOld))
    commitInfo = fileread('toolboxCommitId');
    warning(['The Standstill stability toolbox you are running with is not the same as the one this folder is generated with. The commit ID of the original checked out toolbox version is: ' commitInfo ])

    commitInfo = fileread('toolboxCommitId');

    %Write new hash file
    md5HashCurrent = [];
    fileCurrentHash = 'toolboxHashCurrent';
    result = 1;   
    if(exist(fileCurrentHash,'file'))
        md5HashCurrent = fileread(fileCurrentHash);
    end
    if(~strcmp(md5Hash,md5HashCurrent))
        result = 2;
        warning('The Standstill stability toolbox is also different from the one it was last run with.')
        fid = fopen(fullfile(pwd,fileCurrentHash),'w');
        fprintf(fid,'%s',md5Hash);
        fclose(fid);
    end
end


