function n_damping = apply_edgewise_damping(prep_file, n_prep, delete_old, delete_INT, retain)
% add_edgewise_damping - Add edgewise damping (logarithmic decrement) to 
% DLCs defined by a text file generated by the script:
% edgewise_vibration_detect.m.
%
% A critical damping decrement of 1 is recommended. 
% If needed, damping may be applied in a prescribed order of .5, 1, 1.5
% i.e. if damping is not yet applied then .5 will be applied, 
% if .5 is applied then 1 will be applied and so on.
%
% Syntax:   apply_edgewise_damping(path, n_prep)
%
% Inputs:
%  path   -     Full path to the prepfile (or simulations folder) where 
%               the prep files and damping_application.txt file is placed.
%  n_prep -     Number of prep files to be applied to (will be selected as
%               the n_prep largest files in the directory specified by
%               path).
%  delete_old - Delete old prep file flag. Set to 1 if you don't wan't to
%               retain old prep file and 0 if you wan't to.
%  delete_INT - Delete INT file(s) flag. Set to 1 if you wan't old INT
%               files for affected DLC's to be deleted (i.e. for re-running
%               the DLC's) and 0 if you wan't them to be retained.
%  retain -     retain old files flag. Set to 1 if you want to retain the
%               damping_application file (i.e. move to _OLD folder) and the
%               damping specification plots and 0 if you don't.
%
% Example: 
%    n_damping = apply_edgewise_damping('MY PREPFILE.txt', 1, 1, 0, 1)  
%    n_damping = apply_edgewise_damping('w:\3MW\Mk3E\Calculations\005_dfac_specification\V117_3.60_IEC1B(S)_HH91.5_VDS_AAO_OFFSHORE_drafttower_4b2d4f_60b53c\V117_3.60_IEC1B(S)_HH91.5_VDS_AAO_OFFSHORE_drafttower_4b2d4f_60b53c.txt', 1, 0, 1, 1)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

%% Set default values for input
[sim_path,FileName,Ext] = fileparts(prep_file);      % separate the file name and simulation folder path
sim_path = [sim_path '\'];
% FileName = [FileName Ext];
optargs = [1, 0, 1, 1];     % set of defaul settings
switch nargin               % switch on number of inputs
    case 1
        n_prep      = optargs(1);
        delete_old  = optargs(2);
        delete_INT  = optargs(3);
        retain      = optargs(4);
    case 2
        delete_old  = optargs(2);
        delete_INT  = optargs(3);
        retain      = optargs(4);
    case 3
        delete_INT  = optargs(3);
        retain      = optargs(4);
    case 4
        retain      = optargs(4);
end

%% Inputs
damping_edgewise_BLD_DOF1 = [2*pi]; % damping application (2*pi correspond to critical levels), use [1 5 10] structure to dampen in levels (not recommended)
damping_edgewise_BLD_DOF2 = 0.5.*damping_edgewise_BLD_DOF1;
clearPrevDamping = false; % clear previous damping in prepfile (to avoid errors)

%% Read DLC specifications
fid         = fopen([sim_path '/damping_application.txt'], 'r');
                                                        % open damping application text file
DLC         = textscan(fid, '%s\n');                  % read 
DLC         = DLC{1, 1};                                % store DLC list in cell array
fclose(fid);                                            % close damping application text file
date_str    = datestr(now, 'yy_mm_dd_HH_MM_SS');        % get date in string to use as a unique identifier for renaming the original prep files and damping_application.txt file
if retain                                               % check if old files should be retained
    folder  = ['_OLD_', date_str];                      % get folder name
   	mkdir(fullfile(sim_path, folder));                      % create directory
    movefile(fullfile(sim_path, 'damping_application.txt'), fullfile(sim_path, folder, 'damping_application.txt'));
                                                        % move original damping_application.txt file
    temp    = dir([sim_path, 'p2p_Smom_DLC*.png']);        	% find all png images with max FFT values
    for i = 1:length(temp)                              % start looping on png files
        movefile(fullfile(sim_path, temp(i).name), fullfile(sim_path, folder, temp(i).name));
                                                        % move figure
    end
end
n_damping      = length(DLC);                              % number of DLC's to be changed

%% Read blade edge DOFs for damping
OUTpath = [sim_path '/Loads/OUT/'];
outfiles = dir(OUTpath);

fid = fopen([OUTpath outfiles(3).name],'r');
line = fgets(fid);
edgewise_BLD_DOF1 = []; edgewise_BLD_DOF2 = [];
while ischar(line) 
    if strfind(line,'Blade edgewise mode 1')
        lineparts = strsplit(line);
        edgewise_BLD_DOF1(end+1) = str2double(lineparts(2));
    end
    if strfind(line,'Blade edgewise mode 2')
        lineparts = strsplit(line);
        edgewise_BLD_DOF2(end+1) = str2double(lineparts(2));
    end
    line = fgets(fid);
end
fclose(fid); 

%% Find files and sort by size
temp        = dir([sim_path, '*.txt']);                     % get list of text files in path
idx = [];
for ii = 1:length(temp)                                 % start looping to find the prep input text file
    if strcmp([FileName Ext], temp(ii).name) || strcmp([FileName '_SubSet' Ext], temp(ii).name)
        idx(end+1) = ii;
    end
    
    if strcmp([FileName '_SubSet' Ext], temp(ii).name)
        n_prep = 2;
    end
end

%% Read file(s) and add damping
for i = 1:n_prep                                        % start looping on prep files to be changed

    % Move existing prep file if it shouldn't be deleted
    if ~delete_old
        if ~retain                                      % check if other files are retained
            folder  = ['_OLD_', date_str];              % get folder name and ...
            mkdir(fullfile(sim_path, folder));              % create directory if they aren't
        end
        copyfile(fullfile(sim_path, temp(idx(i)).name), fullfile(sim_path, folder, temp(idx(i)).name));
                                                        % copy existing prep file
    end

    % Rename existing prep file
    movefile(fullfile(sim_path, temp(idx(i)).name), fullfile(sim_path, [temp(idx(i)).name(1:end-4), '.old'])); % rename the original prep file
    
    % create temporary local files for read, writing
    tmpFile_new = tempname;
    tmpFile_old = tempname;
    
    % copy files to temp
    copyfile(fullfile(sim_path, folder, temp(idx(i)).name),tmpFile_new) 
    copyfile(fullfile(sim_path, [temp(idx(i)).name(1:end-4), '.old']),tmpFile_old)
    
    % open temporary files
    fid_new = fopen(tmpFile_new,'w');
    fid_old = fopen(tmpFile_old,'r');
                                                         
    % Start copying from original prep file and add damping where specified
    line1       = 0;                % initiate new line
    while ~feof(fid_old)            % loop until reaching end of input file
        line2   = line1;            % set old line to previous step new line
        line1   = fgetl(fid_old);   % get new line
        
        if clearPrevDamping % if flagged
            line1 = regexprep(line1,'(dd\s+\d+\s+\d+(\.\d+)\s*)+','');
        end
        
        cond1 = or(strcmp('', line1) && strcmp('', line2),strcmp(' ', line1) && strcmp(' ', line2));   % check if both lines are empty or ' ' if generated with subset
        cond2 = or(strcmp('', line2),strcmp(' ', line2)) && DLC_in_list(line1, DLC);   % check if both lines are empty       
        if cond1   % check if both lines are empty
            fprintf(fid_new, '\r\n');               % write new line to output file if they are
        elseif cond2                                % check if old line is empty and first characters of new line is equal to the specified DLC number
            fprintf(fid_new, '%s\r\n', line1);      % write new line to output file
            line2   = fgetl(fid_old);               % get new line to old line placeholder
            fprintf(fid_new, '%s\r\n', line2);      % write line to output file
            line1   = fgetl(fid_old);               % get new line
            
            if clearPrevDamping % if flagged
                line1 = regexprep(line1,'(dd\s+\d+\s+\d+(\.\d+)\s*)+','');
            end
            
            if isempty(regexp(line1,'(dd\s+\d+\s+\d+(\.\d+)\s*)+', 'once'))%isempty(strfind(line1, 'dd '))      % check if damping is not applied for this DLC isempty(regexp(line1,'(dd\s+\d+\s+\d+(\.\d+)\s*)+', 'once'))
                fprintf(fid_new, '%s\r\n', [line1, sprintf(' dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', ...
                    edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(1), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(1), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(1), edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(1), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(1), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(1))]); % write line to output file with damping added
            
            elseif ~clearPrevDamping && length(damping_edgewise_BLD_DOF1)>1 % if damping is applied then                                               
                j       = 0;                        % initiate iteration counter
                flag    = 1;                      	% initiate while loop exit flag
                while flag                        	% start looping until exit flag is set false
                    j   = j + 1;                  	% increment iteration counter
                    if j > length(damping_edgewise_BLD_DOF1)          % check if required damping level exceeds predetermined list
                        error('No more levels of damping available. Check your model.')	% throw error if it does
                    end
                    if ~isempty(strfind(line1, sprintf('dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(j))))
                                                  	% check if the j'th damping level is applied
                        flag        = 0;           	% set exit flag to false (i.e. exit next while loop)
                        str_len     = length(sprintf('dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(j)))+1;
                                                   	% get length of damping application string
                        idx_damping    = strfind(line1, sprintf('dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(j), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(j),  edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(j), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(j)))-1;
                                                    % find start index of old damping command
                      	if idx_damping+str_len > length(line1)
                                                    % check if damping command is placed at the end of the line
                            fprintf(fid_new, '%s\r\n', [line1(1:idx_damping), sprintf('dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(j+1), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(j+1), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(j+1))]);
                                                  	% write line to output file with updated damping levels
                        else
                            fprintf(fid_new, '%s\r\n', [line1(1:idx_damping), sprintf('dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f dd %d %.1f', edgewise_BLD_DOF1(1), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF1(2), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF1(3), damping_edgewise_BLD_DOF1(j+1), edgewise_BLD_DOF2(1), damping_edgewise_BLD_DOF2(j+1), edgewise_BLD_DOF2(2), damping_edgewise_BLD_DOF2(j+1), edgewise_BLD_DOF2(3), damping_edgewise_BLD_DOF2(j+1), line1(idx_damping+str_len:end))]);
                                                   	% write line to output file with updated damping levels
                        end
                    end
                end
            else
                fprintf(fid_new, '%s\r\n', line1);      % write new line to output file
            end
        else
            fprintf(fid_new, '%s\r\n', line1);      % simply write new line to file if any other case
        end
    end
    
    fclose(fid_new); fclose(fid_old); % close new, old prep file
    
    % copy tempfiles onto real files
    copyfile(tmpFile_new,fullfile(sim_path, temp(idx(i)).name));
    copyfile(tmpFile_old,fullfile(sim_path, [temp(idx(i)).name(1:end-4), '.old']));
    
    % delete temps and original prepfile
    delete(tmpFile_new); delete(tmpFile_old); 
    delete(fullfile(sim_path, [temp(idx(i)).name(1:end-4), '.old'])); % delete original prep file

end

%% Delete INT files for re-run
if delete_INT                                   % check if delete INT flag is set
    temp    = dir([sim_path, 'Loads\INT\*.int']);   % get list of INT files in folder
    for i = 1:length(temp)                      % start looping on files in INT folder
        for j = 1:length(DLC)                   % start looping on strings in DLC input
            if length(DLC{j}) > length(temp(i).name)                % check if length of string specifying DLC is longer than DLC name (do nothing if it is)
            elseif strcmp(DLC{j}, temp(i).name(1:length(DLC{j})))   % compare string specifying DLC to file name
                delete([[sim_path, 'Loads\INT\'], temp(i).name]);       % delete file if they match
            end
        end
    end
end
end

%% Function for checking if a DLC is in a cell-array list of DLC's
function tf = DLC_in_list(tline, DLC)
    
    % Loop over cell elements in cell array and find out whether they match
    res = zeros(length(DLC), 1);    % create array for storing results of each comparison (i.e. with each string in DLC)
    for i = 1:length(DLC)           % start looping on strings in DLC
        if length(tline) > length(DLC{i, 1})
            res(i) = strcmpi(tline(1:length(DLC{i, 1})), DLC{i, 1});    % compare tline and string in DLC
        end
    end
    if sum(res) == 0                % check if all elements are zero (i.e. no match)
        tf = 0;                     % set output to 0
    else
        tf = 1;                     % else, set output to 1
    end
end