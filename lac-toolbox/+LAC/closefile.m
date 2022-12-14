function [status] = closefile(filename)
% This function closes the file named filename if previously open in Matlab.
%
% [status] = closefile(filename)
%
% filename: name of the file to be closed
% status: 0 if the file was not open, 1 if the file was found open and then was closed

status = 0;

%get list of open files
list = fopen('all');

for i=1:length(list)
    fileInList = fopen(list(i));
    if strcmp(fileInList, filename)
        fclose(list(i));
        status = 1;
    end
end
