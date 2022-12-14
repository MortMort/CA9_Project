function towerfrq_CtrlParamChanges(path)

% towerfrq_CtrlParamChanges - _CtrlParamChanges file with tower frq's
% This function creates a _CtrlParamChanges file with correct 1st and 2nd
% tower frequencies. The function will not overwrite any existing
% _CtrlParamChanges files, but instead appends "_NEW" to the filename.
%
% Syntax:   towerfrq_CtrlParamChanges(path)
%
% Inputs:
%    path - Full path to the simulations folder which should be checked.
%
% Example: 
%    towerfrq_CtrlParamChanges('h:\3MW\MK3\V1053450.072\IEC1A\Loads\')
%
% Other m-files required:   LAC.vts.towerfrq()
% 							LAC.vts.convert()
%
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% November 2016; Last revision: 29-November-2016

%% Initiate flag(s)
flag_fast   = 0;    % flag for using ProdCtrlFast controller parameter


%% Calculate gravity corrected tower frequency and find 2nd tower frequency
path = fullfile(path,'\');
temp_path   = dir([path, 'OUT\*.out']);  	% search in path with wildcard (*) for file name
if size(temp_path, 1) == 0                  % check if any .out files are available
    error('No ".out" files available, please run at least one load case.')
                                            % throw error if none are available
end
flag        = 1;                            % initiate empty flag for .out file
i           = 0;                            % initiate iteration counter (iterating on .out files)
while flag                                  % do while flag is set high
    i = i + 1;                              % increment iteration counter
    fid     = fopen([path, 'OUT\', temp_path(i).name], 'r');	% open the first available .out file
    temp    = textscan(fid, '%s', 'delimiter', '\n');           % read text file content into cell array
    fclose(fid);                                                % close text file
    if isempty(temp{1})                     % check if file is emtpy
        flag = 1;                           % set flag high if it is
    else
        flag = 0;                           % set flag low if it isn't
    end
end

    % Calculate 1st eigenfrequency (gravity corrected)
    twr_frq1    = LAC.vts.towerfrq(path);  	% calculate tower 1st eigen frequency
    twr_frq1    = twr_frq1.corr;            % store 1st eigen frequency in dat struct

    % Find 2nd tower frequency
    key         = 'The first 8 eigenfrequencies';                           % key to search for in .out file
    iline       = find(strncmpi(key, temp{1}, length(key))==1, 1);          % line where key is found
    twr_frq2    = cell2mat(textscan(temp{1}{iline+6}, '%*f %*f %f'));   	% find and store 2nd eigen frequency in dat struct

%% Find tower frequencies set in ProdCrtl and ProdCtrlFast csv file
temp_guess  = [path, 'INPUTS\ProdCtrl_*.csv'];	% search in path with wildcard (*) for file name
temp        = dir(temp_guess);                  % get list of files matching the wildcard search
csv_norm    = [path, 'INPUTS\', temp.name];  	% path to ProdCtrl csv file
if ~exist(csv_norm, 'file')                     % check if the file exists
    error('ProdCtrl_ file not found!')          % throw error if it doesn't
else
    csv_norm_par    = LAC.vts.convert(csv_norm);    % load controller parameters if it does
end
csv_frq2b   = csv_norm_par.values(not(cellfun('isempty', strfind(csv_norm_par.parameters, 'Px_SP_SecondTowFreqFilt_fc'))));
                                                    % load 2nd eigenfrequency (second definition) as defined in controller
if isempty(csv_frq2b)                           	% check if 2nd eigenfrequency (second definition) is found, if not then it migth be found in ProdCtrlFast (newer controllers)
    temp_guess  = [path, 'INPUTS\ProdCtrlFast_*.csv'];	% search in path with wildcard (*) for file name
    temp        = dir(temp_guess);                  % get list of files matching the wildcard search
    csv_fast    = [path, 'INPUTS\', temp.name];  	% path to ProdCtrlFast csv file
    if ~exist(csv_fast, 'file')                     % check if the file exists
        error('ProdCtrlFast_ file not found!')      % throw error if it doesn't
    else
        flag_fast       = 1;                        % set flag for ProdCtrlFast being used
    end
end

%% Write _CtrlParamChanges file
load_path   = path(1:strfind(path, 'Loads\')-1); 	% specify path to folder above "Loads"
fname  		= '_CtrlParamChanges.txt';              % filename
temp_path = dir([load_path, fname]);  				% get list of existing _CtrlParamChanges files
if (size(temp_path, 1)) ~= 0						% check if a CtrlParamChanges file already exists
	fname  	= '_CtrlParamChanges_NEW.txt';          % make filename slighty different if there does
end
fid = fopen([load_path, fname], 'w');     			% create _CtrlParamChanges file
fprintf(fid, '%s %4.3f\r\n', 'Px_SP_EstimatedTowerNaturalFreq =', round(twr_frq1, 3));
													% write 1st eigenfrequency to _CtrlParamChangesFile
fprintf(fid, '%s %4.3f\r\n', 'Px_SP_EstimatedTower2ModeFreq =', round(twr_frq2, 3));
													% write 2nd eigenfrequency to _CtrlParamChangesFile
if flag_fast == 0                                   % check if the ProdCtrlFast flag is set
	fprintf(fid, '%s %4.3f', 'Px_SP_SecondTowFreqFilt_fc =', round(twr_frq2, 3));
													% write 2nd eigenfrequency to _CtrlParamChangesFile
else
	fprintf(fid, '%s %4.3f', 'Px_SPf_SecondTowFreqFilt_fc =', round(twr_frq2, 3));
													% write 2nd eigenfrequency to _CtrlParamChangesFile
end
fclose(fid);