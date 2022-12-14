function md5Hash = calcDirectoryMD5(path2Directory)
%MD5HASH = CALCDIRECTORYMD5()
% Calculates the MD5 hash of all *.m files in the same folder where this
% function is placed
%MD5HASH = CALCDIRECTORYMD5(path2Directory)
%Calculates th MD5 hash of all *.m files in the input directory


if(nargin < 1)
    [path2Directory, ~, ~] = fileparts(mfilename('fullpath'));
end
files2Analyse = what(path2Directory); %Find matlab files

disp(['Hashing ' num2str(length(files2Analyse.m)) ' files from directory: ' path2Directory    ]);


tic
mddigest   = java.security.MessageDigest.getInstance('MD5');
%Read all *.m files into one array
fileContents = [];
for ii = 1:length(files2Analyse.m)
    fileName = fullfile(path2Directory,files2Analyse.m{ii});
    fileContents = [fileContents fileread(fileName)];
    %Use this to read if file is not a txtfile
    %fid = fopen(fileName,'r'); fileContents = [fileContents ; fread(fid,'*uint8')]; fclose(fid); 
end

%Calculate hash
mddigest.update(typecast(uint16(fileContents(:)), 'uint8'));
md5Hash=reshape(dec2hex(typecast(mddigest.digest(),'uint8'))',1,[]);


toc;


