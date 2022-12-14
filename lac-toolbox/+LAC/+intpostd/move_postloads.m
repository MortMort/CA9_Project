function move_postloads(path)

% move_postloads - Corrects paths in the files in the postloads folder.
% For use when a postloads folder have been moved and the paths in the
% individual files need to be corrected to the current paths. The function
% takes a load path as an input and automatically corrects the paths in all
% postloads files in that loads folders.
%
% Syntax:   move_postloads(path)
%
% Inputs:
%    path - Full path to the Postloads folder which should be changed.
%
% Example: 
%    move_postloads('h:\3MW\MK3\V1053450.072\IEC1A\Loads\Postloads\')
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% July 2016; Last revision: 11-July-2016

% List of files to alter
files = {'BLD\BLDload'
    'DRT\DRTload'
    'DRT\RotorLockLoads'
    'FND\FNDload'
    'HUB\BRGload'
    'HUB\PitchLockLoads'
    'HUB\PITload'
    'MAIN\MainLoad'
    'TWR\TWRload'
    'User\Loads\USERload'
    'VSC\VSCLoad'};

% Check if path includes a \ at the end
if ~strcmp(path(end), '\')              % check if last char is a "\"
    path = [path, '\'];                 % add one if it isn't
end

% Find reduced path (i.e. path to "Loads" folder)
n_ch        = strfind(path, '\');       % find indices of "\" in path
path_red    = path(1:n_ch(end-1));      % reduce path to the second last "\"

% Loop on files and start altering
for i = 1:length(files)                 % start looping on files to alter
    movefile([path, files{i}, '.txt'], [path, files{i}, '.old'])    % rename existing file
    fid_in  = fopen([path, files{i}, '.old'], 'r');                 % open existing file (read)
    fid_out = fopen([path, files{i}, '.txt'], 'w');                 % create and open new file (write)
    j = 1;                              % initiate line counter
    tline = '';                         % initiate line content string
    while ischar(tline)                 % loop while line content is still a string (i.e. until EOF)
        tline = fgetl(fid_in);          % get content of line
        if j > 12 && j < 17             % check if between line 12 and 17 (line 13 to 16 contain paths)
            n_ch = strfind(tline, '\Loads\');                       % find indice of "\Loads\" in path
            n_ch = n_ch + 7;            % add 7 to the indice (i.e. to get to the char after "\Loads\")
            fprintf(fid_out, '%s\r\n', [tline(1:27), path_red, tline(n_ch:end)]);
                                        % write reduced input path and end of line from existing file to new file
        else
            fprintf(fid_out, '%s\r\n', tline);                      % directly write line from existing file to new file (i.e. copy)
        end
        j = j + 1;                      % update line counter
    end
    fclose(fid_in);                     % close input file (i.e. existing)
    fclose(fid_out);                    % close output file (i.e. new)
    delete([path, files{i}, '.old'])    % delete input file (i.e. existing)
end