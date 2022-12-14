% getFilesFromFTP(ftpServer, userName, password, fileMask, destinationFolder, deleteAfterCopy)
%
% Copies files incrementally from an FTP server. If a file already exists
% in the destination folder with the same name as the one on the FTP server
% the same file is not downloaded again.
% Files are left on the FTP server after the copy.
%
% fptServer: string with the IP address of the server
% userName: string with the username to be used for the connection
% password: string with the password for the connection
% fileMask: selection criteria for the files wished to be copied, e.g.
%           longTerm*.dvx
% destinationFolder: string containing a valid path where to copy the files
% deleteAfterCopy: boolean to indicate wheter or not to delete files 
%
% Version 00 - 2015.08 FACAP
% 

function getFilesFromFTP(ftpServer, userName, password, fileMask, destinationFolder, deleteAfterCopy)

if nargin<6 || isempty(deleteAfterCopy)
    deleteAfterCopy = false;
end
    
disp('Opening FTP connection...')
ftpobj = ftp(ftpServer, userName, password);

remoteFiles = dir(ftpobj, fileMask);

for ii=1:length(remoteFiles)
    fprintf('%s - ', remoteFiles(ii).name);
    localFiles  = dir(fullfile(destinationFolder, remoteFiles(ii).name));
    if ~isempty(localFiles)
        fprintf('File already copied locally\n');
        continue;
    end
    fprintf('Copying');
    try
        mget(ftpobj, remoteFiles(ii).name, destinationFolder);
        fprintf(' - Done \n');
        if deleteAfterCopy
            delete(ftpobj, remoteFiles(ii).name);
            fprintf(' - Deleted \n');
        end
    catch
        fprintf(' - ERROR \n');
    end
end

close(ftpobj);
disp('Done.')