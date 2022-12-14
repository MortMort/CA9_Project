function converttoPSA(prep, etm_mult, etm_max, change_BLD, change_CTR)

% converttoPSA - Converts a standard prep file to run PSA
% This function will take a standard prep file (found in [1]) and produce
% an identical prep file which is converted to run PSA (changes include new
% controller, different BLD file, and longer initialization time for all
% load cases running NTM and ETM). It furthermore adds a line to the
% _CtrlParamChanges file found in the same folder as the input prep file
% which enables PSA. Note that the function currently only works for V117
% (new controllers need to be added for other WTG's).
%
% [1] h:\3MW\MK3\official_models\
%
% Syntax:   converttoPSA(file, etm_mult, etm_max, change_BLD, change_CTR)
%
% Inputs:
%   prep 	 -   Input prep file which should be used as a template for
%                creating the PSA prep file.
%   etm_mult -   Multiplier for number of seeds in 1.3 ETM cases.
%   etm_max  -   Maximum number of seeds for 1.3 ETM cases. Is hardcoded to
%                48 if not overwritten by the user.
%   change_BLD - Flag to specify whether blade should be changed or not.
%   change_CTR - Flag to specify whether controller should be changed or
%                not.
%
% Example:
%  	converttoPSA('h:\3MW\MK3\V1173450.116\T3III351.IEC2A.VDS.005\V117_3.45_IEC2A_HH116.5_VDS_T3III351.txt', 4, 48, 0, 0)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% February 2017; Last revision: 14-August-2017

%% Define output filename
file_in = prep;                                                     % define input file as the prep file specified
[path, name, ext] = fileparts(prep);                                % split input file path into file parts
file_out = fullfile(path, [name(1:5), 'PSA_', name(6:end), ext]);   % generate output file name

%% Define maximum number of ETM seeds if not defined by user
if ~exist('etm_max', 'var')                     % check if maximum number of seeds for 1.3 ETM cases is already defined
    etm_max = 48;                               % set to 48 seeds if not
end

%% Read file and add text
fid_in      = fopen(file_in, 'r+');             % open input file
fid_out     = fopen(file_out, 'w');             % create and open output file
lines       = cell(3, 1);                       % initiate line cell array
while ~feof(fid_in)                             % loop until reaching end of file
    lines       = circshift(lines, [1, 0]);     % shift lines one step (i.e. make room for new line)
    lines{1}    = fgetl(fid_in);                % get new line
    if ~isempty(lines{1})
        gen_state   = textscan(lines{1}, '%s', 'delimiter', ' ');
                                              	% read content of newest line
        if length(gen_state{1}) >= 2           	% check if length of output is higher than or equal to 2
            gen_state	= str2double(gen_state{1}{2});
                                                % take second value (i.e. generator state) and convert to double
        else
            gen_state   = 3;                	% set gen_state to 3 (arbitrary value) if value is not specified
        end
    end
    
    if any(strfind(lines{1}, 'BLD')) == 1 && change_BLD	% check if BLD are the first three letters in the line
        parts = textscan(lines{1}, '%s', 'delimiter', ' ');
                                                % read line using whitespace as the delimiter
        parts = parts{1};                       % skip first (superflous) layer of cell array
        fprintf(fid_out, '%s %s\r\n', parts{1}, [parts{2}(1:end-4), '_PSA', parts{2}(end-3:end)]);
                                                % print BLD designation and blade filename (with "_PSA" added to the filename)
    elseif any(strfind(lines{1}, 'CTR') == 1) && change_CTR     % check if CTR are the first three letters in the line
        ctr = findCTR(name);                    % find controller for turbine
        fprintf(fid_out, '%s %s\r\n', 'CTR', ctr);
                                                % print CTR designation and absolute path to controller file
    elseif strfind(lines{1}, 'Time') == 1       % check if Time are the first four letters in the line
        parts = textscan(lines{1}, '%s', 'delimiter', ' ');
                                                % read line using whitespace as the delimiter
        parts = parts{1};                       % skip first (superflous) layer of cell array
      	parts = parts(~cellfun('isempty', parts));
                                                % remove empty cells
        fprintf(fid_out, '%-10s %-4s %-3s %-2s %-11s %-2s %-7s %-4s %-2s\r\n', parts{1}, parts{2}, parts{3}, parts{4}, '2000', parts{6}, parts{7}, parts{8}, parts{9});
                                                % print new time definitions with changed initialization time (i.e. 2000 sec.)
        time_spec = sprintf('time %s %s %s %s', parts{2}, parts{3}, parts{4}, parts{5});
                                                % save default time specification
    elseif any(strfind(lower(lines{2}), '13') == 1) && any(strfind(lower(lines{1}), 'etm') == 1) && exist('etm_mult', 'var')
                                                % check if this a DLC 13 case and whether ETM seed multiplier is specified
        parts = textscan(lines{1}, '%s', 'delimiter', ' ');
                                                % read line using whitespace as the delimiter
        parts = parts{1};                       % skip first (superflous) layer of cell array
      	parts = parts(~cellfun('isempty', parts));
                                                % remove empty cells
        parts{4} = num2str(min([etm_max, str2double(parts{4})*etm_mult]), '%d');
                                                % multiply number of seeds by etm_mult parameter
        for i = 1:length(parts)-1               % start looping on words/specifications in line
            fprintf(fid_out, '%s ', parts{i});  % print string with a whitespace at the end
        end
       	fprintf(fid_out, '%s\r\n', parts{end}); % print last string, but with a CRLF instead of a whitespace
    elseif any(strfind(lower(lines{1}), 'time')) && (any(strfind(lower(lines{2}), 'ntm')) || any(strfind(lower(lines{2}), 'etm'))) && isstrprop(lines{3}(1), 'digit')
                                                % check if current line has simulation time hardcoded and whether the DLC uses NTM/ETM
        parts = textscan(lines{1}, '%s', 'delimiter', ' ');
                                                % read line using whitespace as the delimiter
        parts = parts{1};                       % skip first (superflous) layer of cell array
      	parts = parts(~cellfun('isempty', parts));
                                                % remove empty cells
        ix = strfind(cellfun(@lower, parts, 'uniformoutput', false), 'time');
                                                % find index of time specification in cell array
        ix = find(~cellfun(@isempty, ix)) + 4;  % find index from outputted cell array (i.e. find non-empty cell)
        t_ini = str2double(parts{ix});          % convert original initialization time to a number (from string)
        parts{ix} = num2str((ceil((2000 - t_ini)/10))*10+t_ini, '%.2f');
                                                % calculate new initialization time (needs to be minimum 2000 seconds but still maintain azimuth averaging specific time)
        for i = 1:length(parts)-1               % start looping on strings in load cases definition line (except the last string)
            fprintf(fid_out, '%s ', parts{i});  % print string with a whitespace at the end
        end
       	fprintf(fid_out, '%s\r\n', parts{end}); % print last string, but with a CRLF instead of a whitespace
    elseif ~any(strfind(lower(lines{1}), 'time')) && gen_state == 0 && isstrprop(lines{3}(1), 'digit')
                                                % check if current line has simulation time hardcoded and whether the generator state is 0 (i.e. generator disconnected) 
        fprintf(fid_out, '%s %s\r\n', lines{1}, time_spec);
                                                % simply write new line to file, with added default time specification
    else
        fprintf(fid_out, '%s\r\n', lines{1});   % simply write new line to file if any other case
    end
end

fclose(fid_in);     % close input file
fclose(fid_out);    % close output file

%% Add "enable PSA" option to _CtrlParamChanges file or create a new file
if exist(fullfile(path, '_CtrlParamChanges.txt'), 'file')   % check if the folder contains a _CtrlParamChanges file
    [~, name, ext] = fileparts('_CtrlParamChanges.txt');    % get parts of filename
    copyfile(fullfile(path, [name, ext]), fullfile(path, [name, '_PSA', ext]));
                                                            % copy the original _CtrlParamChanges file (adding _PSA to the filename)
    fid = fopen(fullfile(path, [name, '_PSA', ext]), 'a');  % open the just copied new _CtrlParamChanges file (for appending text)
    fprintf(fid, '\r\nPx_LDO_PSA_EnablePSA = 1');           % add "enable PSA" option
    fclose(fid);                                            % close file
else
    h = msgbox('No _CtrlParamChanges file found. A new one will be created.');
                                                            % put a messagebox on the screen, informing the user that no _CtrlParamChanges file was found 
    waitfor(h);                                             % wait until user closes the messagebox
    fid = fopen(fullfile(path, '_CtrlParamChanges.txt'), 'w');
                                                            % open a new _CtrlParamChanges file (with write permission)
    fprintf(fid, 'Px_LDO_PSA_EnablePSA = 1');               % print "enable PSA" option
    fclose(fid);                                            % close file
end
end

%% Function for finding controller file
function ctr = findCTR(name)
    if strfind(lower(name), 'v117')
        if strfind(lower(name), 'hh80')         % check if this is a hub height 80 variant
            ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3A_V117_3.45MW_104.7_hh091\TowerConf\Towers\CTR_Mk3A_V117_3.45MW_104.7_004_Tfrq0.263_hh80.txt';
                                                % controller file for hub height 80
        elseif strfind(lower(name), 'hh91')     % check if this is a hub height 91.5 variant
            ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3A_V117_3.45MW_104.7_hh091\TowerConf\Towers\CTR_Mk3A_V117_3.45MW_104.7_004_Tfrq0.258_hh91.txt';
                                                % controller file for hub height 91.5
        elseif strfind(lower(name), 'hh116')    % check if this is a hub height 116.5 variant
            ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3A_V117_3.45MW_104.7_hh091\TowerConf\Towers\CTR_Mk3A_V117_3.45MW_104.7_004_Tfrq0.179_hh116.txt';
                                                % controller file for hub height 116.5
        else
            error('Variant not found!')         % print out error if no controller is found for the variant
        end
    elseif strfind(lower(name), 'v136')
        if any(strfind(lower(name), 'iec2b')) || any(strfind(lower(name), 'iecs'))
            if strfind(lower(name), 'hh82')         % check if this is a hub height 82 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.277_hh82_IEC2B.txt';
                                                    % controller file for hub height 82
            elseif strfind(lower(name), 'hh112')   	% check if this is a hub height 112 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.211_hh105_IEC2B.txt';
                                                    % controller file for hub height 112
            elseif strfind(lower(name), 'hh132')  	% check if this is a hub height 132 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.181_hh132_IEC2B_LDST.txt';
                                                    % controller file for hub height 132
            else
                error('Variant not found!')         % print out error if no controller is found for the variant
            end
        else
            if strfind(lower(name), 'hh82')         % check if this is a hub height 82 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.277_hh82.txt';
                                                    % controller file for hub height 82
            elseif strfind(lower(name), 'hh105')   	% check if this is a hub height 105 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.211_hh105.txt';
                                                    % controller file for hub height 105
            elseif strfind(lower(name), 'hh112')   	% check if this is a hub height 112 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.211_hh105.txt';
                                                    % controller file for hub height 112
            elseif strfind(lower(name), 'hh132')   	% check if this is a hub height 132 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.181_hh132_LDST.txt';
                                                    % controller file for hub height 132
            elseif strfind(lower(name), 'hh142')   	% check if this is a hub height 142 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.149_hh142.txt';
                                                    % controller file for hub height 142
            elseif strfind(lower(name), 'hh149')   	% check if this is a hub height 149 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.151_hh149_LDST.txt';
                                                    % controller file for hub height 149
            elseif strfind(lower(name), 'hh166')   	% check if this is a hub height 166 variant
                ctr = 'h:\Control\Projects\3MW_MK3AB\015\Mk3B_V136_3.45MW_126.0_hh132\TowerConf\Towers\CTR_Mk3B_V136_3.45MW_126.0_005_Tfrq0.145_hh166_LDST.txt';
                                                    % controller file for hub height 166
            else
                error('Variant not found!')         % print out error if no controller is found for the variant
            end
        end
    end
end