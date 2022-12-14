function n_dfac = edgewise_vibration_detect(prep_file, mode)

% edgewise_vibration_detect - Detects edgewise vibrations in standstill.
% This function detects edgewise vibrations in standstill cases (DLC 6.2
% and 8.2) and writes loadcase names with edgewise vibrations above a set
% threshold to a text file. This method uses FFT to find critical cases.
%
% Syntax:   edgewise_vibration_detect(path)
%
% Inputs:
%    prep_file   -  Full path to Prep Input text file name 
%    mode - Selector that determines whether to run check of standard load
%           cases (i.e. DLC 62E50 and 82E50), rotor-lock cases (i.e. DLC
%           81P) or idling position maintenance cases (i.e. DLC 81IdHLYE,
%           81IdHL, 81IdYE and 81Id). Set to 1 for standard load cases, 2 
%           for rotor-lock cases and 3 for idle maintenance cases. Specific
%           modes can also be selected by inputing a cell array with a list
%           of numbers corresponding to the DLC's that needs to be checked.
%
% Example: 
%    n_dfac = edgewise_vibration_detect('h:\3MW\MK3\V1053450.072\IEC1A\iec1a.txt', 1)
%
% Other m-files required:   LAC.timetrace.int.readint()
%                           LAC.timetrace.int.GetIntSensors()
%                           LAC.signal.fftcalc()
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% November 2016; Last revision: 29-August-2018

%% Input
file    = 'dfac_application.txt';       % file name for output text file
sens    = {'My11r', 'My21r', 'My31r'};  % sensors to read
threshold   = 300;                     	% set threshold value
DLCs    = {'62'; '82'; '65PT'; '81PT'; '81P00'; '81P30'; '81P60'; '81YE'; '81PHL'; '81IdleYdis'; '81IdleYen'; '81RoLoYdis'; '81RoLoYen'; '81FRL'; '81RLSpi00'; '81RLSpi30'; '81RLSpi60'; '81RLIpi00'; '81RLIpi30'; '81RLIpi60'; '81RLSwd'; '81RLIwd'; '81Swd'; '81Iwd'};
                                        % combined set of DLC's to check
DLC_Azim_Ind = [4:8, 11:12, 15:22];     % Specify the DLC indexes for which Azimuth angles needs to be determined
if ~iscell(mode) && length(mode) == 1	% check if mode selection is a cell array (i.e. whether specific modes are selected)
    if mode == 1                     	% check if mode 1 (i.e. standard LC's) is chosen
        DLC     = DLCs(1:2);           	% set subset of DLC's to check
    elseif mode == 2                   	% check if mode 2 (i.e. standard rotor-lock LC's) is chosen
        DLC     = DLCs(2:9);           	% set subset of DLC's to check
    elseif mode == 3                   	% check if mode 3 (i.e. idle mode LC's) is chosen
        DLC     = DLCs(10:13);       	% set subset of DLC's to check
    elseif mode == 4                   	% check if mode 4 (i.e. full rotor lift LC's) is chosen
        DLC     = DLCs(14);             % set subset of DLC's to check
    elseif mode == 5                   	% check if mode 5 (i.e. Odin maintenance) is chosen
        DLC     = DLCs([2, 15:24]);   	% set subset of DLC's to check
    end
elseif iscell(mode)
    mode = cell2mat(mode);              % convert input cell array to a normal array
    DLC = DLCs(mode);                   % set subset of DLC's to check (from specified list of modes)
else
    error('Input: "mode" not specified correctly. Please read header of function.')
                                        % throw error if mode isn't specified correctly
end

%% Read prep file
fid         = fopen(prep_file);              % open prep file for reading
prep_cont   = textscan(fid, '%s', 'delimiter', '\n');
                                        % read prep content
prep_cont   = prep_cont{1};             % skip first "superflous" layer of cell array
fclose(fid);                            % close prep file
i           = find(~cellfun(@isempty, strfind(prep_cont, 'LOAD CASES')));
                                        % find line in prep file where load case definitions begin
n_DLC       = zeros(length(DLC), 1);  	% initiate array for storing number of load cases for each DLC
DLC_name    = cell(length(DLC), 1);  	% initiate array for storing DLC names
DLC_wdir    = cell(length(DLC), 1);  	% initiate array for storing wind directions in each DLC
DLC_azim    = cell(length(DLC), 1);   	% initiate array for storing start azimuth angles for each DLC
flag_82 = true;
while i < length(prep_cont)             % start looping until reaching the end of the prep file
    i       = i + 1;                   	% increment line counter
    if length(prep_cont{i}) >= 2        % check if line contains more or exactly 2 characters
        temp    = false;               	% initiate temporary variable
        i_DLC   = 0;                  	% initiate DLC index counter
        while ~temp && i_DLC < length(DLC)                          % start looping until a mathing load case is found or when the end of the DLC list is reached
            i_DLC   = i_DLC + 1;                                    % increment DLC index counter
            temp    = any(strfind(prep_cont{i}, DLC{i_DLC}) == 1);	% check if the current DLC from the DLC list matches the DLC specified in the prep file
        end
        if i_DLC && temp                                                            % check if a match has been found
            if strcmp(DLC{i_DLC}, '82') && flag_82
                if strcmp(prep_cont{i}(1:6), '82LTRL')
                    flag_82 = false;
                    DLC_Azim_Ind = [DLC_Azim_Ind, 2];
                end
            end
            n_DLC(i_DLC)    = n_DLC(i_DLC) + 1;                                     % increment load case counter (i.e. for each DLC)
            str             = textscan(prep_cont{i}, '%s', 'delimiter', ' ');       % read line content
            DLC_name{i_DLC}{n_DLC(i_DLC)}       = str{1}{1};                        % get INT filename
            i               = i + 2;                                                % increment line counter by 2 (i.e. skip 1 line)
            str             = textscan(prep_cont{i}, '%s', 'delimiter', ' ');       % read line content
            DLC_wdir{i_DLC}(n_DLC(i_DLC))       = str2double(str{1}{4});            % get wind direction for current DLC
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(i_DLC))))                  % check if this DLC has azimuth sweeping
                i_azi       = find(~cellfun(@isempty, strfind(str{1}, 'azim0')));   % find location (in line/string) of azimuth specification
                DLC_azim{i_DLC}(n_DLC(i_DLC))   = str2double(str{1}{i_azi + 1});    % read azimuth position
            end
        end
    end
end

%% Open file for writing
[path, ~, ~]    = fileparts(prep_file);                  % get path to calculation folder
fid             = fopen(fullfile(path, file), 'w'); % open new file for writing data

%% Start looping on DLC's
n_dfac          = 0;                                % initiate dfac counter
Settings.SensorListConfig = 'Auto Detection';       % setting for reading INT sensor info
for k = 1:length(DLC)                               % start looping on subset of DLC's to check

    % Get list of INT files
    temp_path   = dir(fullfile(path, 'Loads', 'INT', [DLC{k}, '*.int']));   % create list of INT files

    % Define wind direction vector and threshold value
    wdir        = unique(DLC_wdir{k});                      % get unique list of wind directions
    wdir_sort   = sort(wdir);                               % sort list of wind directions
    wdir_step   = wdir_sort(2)-wdir_sort(1);                % find step size between wind directions
    x_tick      = wdir_sort(1):wdir_step:wdir_sort(end);    % define tick mark placement on x-axis
    wdir_DLC    = zeros(length(temp_path), 1);              % initiate array for storing wind directions of each INT file
    if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))      % check if this DLC has azimuth sweeping
        azim        = unique(DLC_azim{k});                  % get unique list of azimuth positions
        n_azim      = length(azim);                         % number of unique azimuth positions
        azim_DLC    = zeros(length(temp_path), 1);          % initiate array for storing azimuth position of each INT file
    else
        n_azim = 1;                                         % set number of azimuth positions to 1 if no azimuth sweeping
    end

    % Start loading INT files
    if ~isempty(temp_path)                                     	% check if there are any INT files

        max_FFT     = zeros(3, size(temp_path, 1));             % initiate array for storing max FFT values
      	max_FFT_LC  = zeros(3, length(wdir), n_azim);         	% initiate array for storing max FFT values (for each load case)

        for i = 1:size(temp_path, 1)                           	% start looping on INT files
        
            % Find wind direction of current INT file
            idx_DLC             = ~cellfun(@isempty, strfind(DLC_name{k}, temp_path(i).name(1:length(DLC_name{k}{1}))));
                                                                % find index of load cases matching the current INT file
            wdir_DLC(i)         = DLC_wdir{k}(idx_DLC);         % get wind direction for INT file
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
                azim_DLC(i)     = DLC_azim{k}(idx_DLC);         % save azimuth angle for INT file
            end
            
            % Start reading INT file
            fprintf('DLC %s (%d out of %d) - INT file %d out of %d (%.0f%%)\n', DLC{k}, k, length(DLC), i, size(temp_path, 1), i/size(temp_path, 1)*100)
                                                              	% print status to command window
            [GenInfo, Xdata, Ydata, ~]  = LAC.timetrace.int.readint(fullfile(path, 'Loads', 'INT', temp_path(i).name), 1, [], [], []);
                                                               	% read INT file

            % Find sensor index's if this is the first INT file
            if i == 1                                         	% check if this is the first INT file
                [~, ~, AddOut]  = LAC.timetrace.int.GetIntSensors(fullfile(path, 'Loads', 'INT', temp_path(i).name), GenInfo, Settings);
                                                               	% read sensor info for INT file
                sens_idx        = zeros(1, length(sens));    	% initiate array for storing sensor numbers
                for j = 1:length(sens)                       	% start looping on sensors
                    sens_idx(j) = find(strcmp(AddOut.Name, sens{j}), 1);
                                                                % find index of current sensor
                end
            end

            % Calculate FFT for data
            for j = 1:length(sens)                           	% start looping on sensors
                [f, FFTY, ~, ~, ~, ~]	= LAC.signal.fftcalc(Xdata, Ydata(:, sens_idx(j)), 2^nextpow2(length(Xdata)));
                                                              	% calculate FFT for data

                % Find index of 0.5 Hz in frequency vector (lowest frequency value to find max of FFT for)
                if i == 1                                       % check if this is the first INT file
                    [~, idx_ran]        = min(abs(0.5-f));     	% find index of 0.5 Hz in frequency vector
                end

                % Find max FFT value for current blade
                max_FFT(j, i)   = max(FFTY(idx_ran:end));       % find max of FFT output
            end
        end
        
        % Find max value for each load case
        for i = 1:length(wdir)                                  % start looping on wind directions
           	idx_wdir = wdir_DLC == wdir(i);                     % find index of INT files with correct wind direction
            for j = 1:length(sens)                              % start looping on sensors
                if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))                      % check if this DLC has azimuth sweeping
                    for l = 1:n_azim                                                    % start looping on azimuth positions if it does
                        idx_azim            = azim_DLC == azim(l);                      % find index of INT files with correct azimuth position
                        max_FFT_LC(j, i, l) = max(max_FFT(j, and(idx_wdir, idx_azim))); % find max FFT value for load case
                    end
                else
                    max_FFT_LC(j, i, 1) = max(max_FFT(j, wdir_DLC == wdir(i)));         % find max FFT value for load case
                end
            end
        end

        % Plot max_FFT for all wind directions
        for i = 1:n_azim                                        % start looping on azimuth positions
            fig = figure('position', [100, 100, 1000, 650]);    % open figure
            bar(wdir, max_FFT_LC(:, :, i)')                     % plot bar graph
            hold on                                             % hold plot (for multiple plot commands)
            legend('Blade 1', 'Blade 2', 'Blade 3')             % add legend to plot
            plot([min(wdir) - wdir_step, max(wdir) + wdir_step], [threshold, threshold], 'r')
                                                                % plot red line at threshold value
            hold off                                            % hold plot off
            lim_max     = max([max(max(max_FFT_LC(:, :, i))), threshold]);
                                                                % find max FFT value for plot
            axis([min(wdir) - wdir_step, max(wdir) + wdir_step, 0, lim_max*1.05])
                                                                % set axis limits
            set(gca, 'xtick', x_tick)                           % set x-axis ticks
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
            	title(['Max FFT for DLC ', DLC{k}, ' (azim0 = ', num2str(azim(i), '%d'),')'])
                                                                % add title to plot
            else
            	title(['Max FFT for DLC ', DLC{k}])             % add title to plot
            end
            xlabel('Wind direction [deg]')                      % add label to x-axis
            ylabel('max(FFT) []')                               % add label to y-axis
            
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
                print(fullfile(path, ['max_FFT_DLC', DLC{k}, '_azim0_', num2str(azim(i), '%d')]), '-dpng')
                                                                % save figure as png
            else
                print(fullfile(path, ['max_FFT_DLC', DLC{k}]), '-dpng')
                                                                % save figure as png
            end
            close(fig)                                          % close figure
        end

        % Write txt file with DLC specifications
        for i = 1:length(wdir)                                  % start looping on wind directions
           	idx_wdir    = wdir_DLC == wdir(i);                 	% find index of INT files with correct wind direction
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
                for j = 1:length(azim)                          % start looping on azimuth positions
                    idx_azim = azim_DLC == azim(j);             % find index of INT files with correct azimuth position
                    idx_comb = find(and(idx_wdir, idx_azim), 1);
                                                                % find index of first INT file with both correct wind direction and azimuth position
                    if sum(max_FFT_LC(:, i, j)>threshold)       % check if the FFT max value of any blade is above threshold for the current wdir
                        fprintf(fid, '%s\r\n', temp_path(idx_comb).name(1:length(temp_path(idx_comb).name)-7));
                                                                % add load case name to the text file if it is
                        n_dfac = n_dfac + 1;                    % increment dfac counter
                    end
                end
            else
                idx_comb = find(idx_wdir, 1);                   % find index of first INT file with correct wind direction 
                if sum(max_FFT_LC(:, i, 1)>threshold)           % check if the FFT max value of any blade is above threshold for the current wdir
                    fprintf(fid, '%s\r\n', temp_path(idx_comb).name(1:length(temp_path(idx_comb).name)-7));
                                                                % add load case name to the text file if it is
                    n_dfac = n_dfac + 1;                        % increment dfac counter
                end
            end
        end
    elseif strcmp(DLC{k}, DLCs{1})                              % check if this is DLC 62
        warning('No DLC 62 INT files found. Please check that turbine is supposed to have YPB (Yaw Power Backup).');
                                                                % print warning to check for YPB if it is
    else
        error('Missing INT files.');                            % throw error in any other case
    end
end
fclose(fid);	% close text file