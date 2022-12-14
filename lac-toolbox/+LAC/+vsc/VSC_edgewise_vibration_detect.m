function n_damping = VSC_edgewise_vibration_detect(prep_file, varargin)
% modification of LAC.scripts.AddDamping.edgewise_vibration_detect so it works with
% the 'ExtremeStandStill' simulations in VSC model simulations;
%
% edgewise_vibration_detect - Detects edgewise vibrations in standstill 
% and writes loadcases with edgewise vibrations exceedance a static 
% peak-to-peak moment threshold of the blade to a text file. 
%
% This method uses non-consecutive peak values of the edgewise blade root
% moment of STA-files to find critical cases.
%
% Syntax:   edgewise_vibration_detect(path)
%
% Inputs:
%    prep_file   -  Full path to prep input text file.
%
% Optional inputs:     
%   sens    		sensors to read, default sens    = {'My11r', 'My21r', 'My31r'}
%   DLCs    		DLC's to be read, default DLCs    = {'62'; '82'; 81I...}
%   margin  		Gravity bending moment margin (Smom1*9.81*margin    = EV limit.
%                   Default margin = 2.0 i.e. peak-to-peak.
%   forceRead       Force-reading sta-files despite .mat file present, default forceRead   = true;
%
% Example: 
%    n_damping = edgewise_vibration_detect('MY PREPFILE.txt')
%
% Other m-files required:   LAC.vts.convert()
%                           LAC.vts.stapost()
% 
% Subfunctions: none
% MAT-files required: none

%% INPUT handles
file    = 'damping_application.txt';            % file name for output text file

% Default values
sens        = {'My11r', 'My21r', 'My31r'};          % sensors to read
DLCs    		= {'62';'82';'81SBI';'81TG';'81HSB';'81Iwd';'81RLIpi';...
                   '81RLIwd';'81RLSpi';'81RLSwd';'81Swd'}; % DLCs to be read
margin      = 2.0;                                  % [kNm] Peak-to-peak gravity bending moment  
forceRead   = true;                               % Force to read the sta files even if the already are read
while ~isempty(varargin)
    switch lower(varargin{1})
        case 'sens'
            sens            = varargin{2};
            varargin(1:2) = [];
        case 'dlcs'
            DLCs            = varargin{2};
            varargin(1:2) = [];
        case 'margin'
            margin            = varargin{2};
            varargin(1:2) = [];
        case 'forceread'
            forceRead        = varargin{2};
            varargin(1:2) = [];
        case 1
            warning('Legacy input. edgewise_vibration_detect(prep,mode) "mode" no longer needed')
            varargin(1) = [];
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
end

%% Getting DLC names and data
DLC_Azim_Ind = []; k = 0;
prepObj = LAC.vts.convert(prep_file,'REFMODEL');
for i = 1:length(DLCs)
    % index of load cases with name longer than the DLCs specify
    DLClongEnoughIdx = cellfun(@length,prepObj.LoadCaseNames)>length(DLCs{i});
    
    % getting the LoadCaseNames indexes with the specified identifier
    DLCidx = strcmpi(cellfun(@(x) x(1:length(DLCs{i})),prepObj.LoadCaseNames(DLClongEnoughIdx),'UniformOutput',0),DLCs{i});
    if any(DLCidx)
        k = 1+k;
        n_DLC(k)            = sum(DLCidx);
        DLC_name{k}         = prepObj.LoadCaseNames(DLCidx);
        loadCaseDefSplit    = cellfun(@(x) strsplit(x{3},' '),prepObj.LoadCases(DLCidx),'UniformOutput',0);
        % Index 4 is always the wind direction 
        DLC_wdir{k}         = cell2mat(cellfun(@(x) str2double(x{4}),loadCaseDefSplit,'UniformOutput',0));
        
        % Finding azim0 identifier
        DLC_azim{k}         = cell2mat(cellfun(@(x) str2double(x(find(strcmpi(x,'azim0'))+1)),loadCaseDefSplit,'UniformOutput',0));
        
        % Weird way to specify the DLC's with azimut angles
        if ~isempty(DLC_azim{k})
            DLC_Azim_Ind        = [DLC_Azim_Ind i];
        end
        
        % Save the subset of DLC's of interest
        DLC{k} = DLCs{i};
    end
end

%% Open file for writing
[path, ~, ~]    = fileparts(prep_file);                  % get path to calculation folder
fid             = fopen(fullfile(path, file), 'w'); % open new file for writing data

%% Read static blade moment
% bldFile = dir(fullfile(path,'/Loads/PARTS/BLD/*'));
bldFile = dir(fullfile(path,'/PARTS/BLD/*'));
% bladeProps = LAC.vts.convert(fullfile(path, '/Loads/PARTS/BLD/', bldFile(3).name),'BLD');
bladeProps = LAC.vts.convert(fullfile(path, '/PARTS/BLD/', bldFile(3).name),'BLD');
bladeMassProps = bladeProps.computeMass;
Smom1 = bladeMassProps.Smom1; % [kgm] Blade static moment
p2pMoment = margin*9.81*Smom1/1000; % [kNm] Peak-to-peak gravity bending moment  

fprintf('Peak-to-peak gravitational bending moment = %.1f kNm\n',p2pMoment);
%% Start looping on DLCs
n_damping          = 0;                                % initiate damping counter
for k = 1:length(DLC)                               % start looping on subset of DLC's to check
    % list of .sta-files
%     sta_path   = dir(fullfile(path, 'Loads', 'STA', [DLC{k}, '*.sta']));   % create list of STA files
    sta_path   = dir(fullfile(path,  'STA', [DLC{k}, '*.sta']));   % create list of STA files
    % Define wind direction vector and threshold value
    wdir        = unique(DLC_wdir{k});                      % get unique list of wind directions
    wdir_sort   = sort(wdir);                               % sort list of wind directions
    wdir_step   = wdir_sort(2)-wdir_sort(1);                % find step size between wind directions
    x_tick      = wdir_sort(1):wdir_step:wdir_sort(end);    % define tick mark placement on x-axis
    wdir_DLC    = zeros(length(sta_path), 1);              % initiate array for storing wind directions of each INT file
    if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))      % check if this DLC has azimuth sweeping
        azim        = unique(DLC_azim{k});                  % get unique list of azimuth positions
        n_azim      = length(azim);                         % number of unique azimuth positions
        azim_DLC    = zeros(length(sta_path), 1);          % initiate array for storing azimuth position of each INT file
    else
        n_azim = 1;                                         % set number of azimuth positions to 1 if no azimuth sweeping
    end

    if ~isempty(sta_path)                                   	% check if there are any STA files
        % read .sta-files
%         if exist(fullfile(path,'Loads',[DLC{k} '.mat']),'file') == 2 && ~forceRead
        if exist(fullfile(path,[DLC{k} '.mat']),'file') == 2 && ~forceRead
            fprintf('LC %s statistics already saved to .mat-file. Loading....\n',DLC{k})
            load(fullfile(path,[DLC{k} '.mat']));
%             load(fullfile(path,'Loads',[DLC{k} '.mat']));
        else
            fprintf('\nReading LC %s statistics \n', DLC{k})
%             obj      = LAC.vts.stapost(fullfile(path,'Loads'));
            obj      = LAC.vts.stapost(fullfile(path));    
            stafiles = struct2cell(sta_path)';
            sta      = obj.readfiles(stafiles(:,1));
            save(fullfile(path,[DLC{k} '.mat']),'sta');
%             save(fullfile(path,'Loads',[DLC{k} '.mat']),'sta');
        end

        max_Moment     = zeros(3, size(sta_path, 1));            % initiate array for storing max root moment values
      	max_Moment_LC  = zeros(3, length(wdir), n_azim);         % initiate array for storing max root moment values (for each load case)

        for i = 1:size(sta_path, 1)                           	% start looping on STA files
        
            % Find wind direction of current STA file
            idx_DLC             = ~cellfun(@(x) isempty(strfind(x, sta_path(i).name(1:length(x)))),DLC_name{k});
                                                                % find index of load cases matching the current STA file
            wdir_DLC(i)         = DLC_wdir{k}(idx_DLC);         % get wind direction for STA file
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
                azim_DLC(i)     = DLC_azim{k}(idx_DLC);         % save azimuth angle for STA file
            end
           
            % sta sensors
            sens_idx        = zeros(1, length(sens));    	% initiate array for storing sensor numbers
            for j = 1:length(sens)                       	% start looping on sensors
                    sens_idx(j) = find(strcmp(sta.sensor, sens{j}), 1);    % find index of current sensor
            end       

            % Calculate maximum static root moment (non-consecutive peaks) 
            for j = 1:length(sens)                                
                Smax = sta.max(sens_idx(j),i);
                Smin = sta.min(sens_idx(j),i);
  
                max_Moment(j, i)   = abs(Smax-Smin);       % find max of root moment output
            end
        end
        
        % Find max value for each load case
        for i = 1:length(wdir)                                  % start looping on wind directions
           	idx_wdir = wdir_DLC == wdir(i);                     % find index of STA files with correct wind direction
            for j = 1:length(sens)                              % start looping on sensors
                if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))                      % check if this DLC has azimuth sweeping
                    for l = 1:n_azim                                                    % start looping on azimuth positions if it does
                        idx_azim            = azim_DLC == azim(l);                      % find index of STA files with correct azimuth position
                        indices = and(idx_wdir, idx_azim);
                        if any(indices)
                            max_Moment_LC(j, i, l) = max(max_Moment(j, indices)); % find max root moment value for load case
                        end
                    end
                else
                    max_Moment_LC(j, i, 1) = max(max_Moment(j, wdir_DLC == wdir(i)));         % find max root moment value for load case
                end
            end
        end

        % Plot max_root moment for all wind directions
        for i = 1:n_azim                                        % start looping on azimuth positions
            fig = figure('position', [100, 100, 1000, 650]);    % open figure
            bar(wdir, max_Moment_LC(:, :, i)')                  % plot bar graph
            hold on                                             % hold plot (for multiple plot commands)
            plot([min(wdir) - wdir_step, max(wdir) + wdir_step], [p2pMoment, p2pMoment], 'r') % plot red line at threshold value
            grid on
            legend('Blade 1', 'Blade 2', 'Blade 3','Static p2p moment')             % add legend to plot
                                                                
            hold off                                            % hold plot off
            lim_max     = max([max(max(max_Moment_LC(:, :, i))), p2pMoment]);
                                                                % find max root moment value for plot
            axis([min(wdir) - wdir_step, max(wdir) + wdir_step, 0, lim_max*1.05])
                                                                % set axis limits
            set(gca, 'xtick', x_tick)                           % set x-axis ticks
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
            	title(['Peak-2-peak Egewise Root Moment for LC ', DLC{k}, ' (azim0 = ', num2str(azim(i), '%d'),')'])
                                                                % add title to plot
            else
            	title(['Peak-2-peak Egewise Root Moment for LC ', DLC{k}])             % add title to plot
            end
            xlabel('Yaw error [deg]')                      % add label to x-axis
            ylabel('Abs. p2p Edgewise Root Moment (non-consecutive peaks) [kNm]')                               % add label to y-axis
            
            if any(cellfun(@any, strfind(DLCs(DLC_Azim_Ind), DLC(k))))  % check if this DLC has azimuth sweeping
                print(fullfile(path, ['p2p_Smom_DLC', DLC{k}, '_azim0_', num2str(azim(i), '%d')]), '-dpng')
                                                                % save figure as png
            else
                print(fullfile(path, ['p2p_Smom_DLC', DLC{k}]), '-dpng')
                                                                % save figure as png
            end
            close(fig)                                          % close figure
        end

        % Write txt file with DLC specifications        
           AddDampingLoadCases = unique(cellfun(@(x) x(1:end-7),...
               {sta_path(logical(sum(max_Moment>p2pMoment))).name},'UniformOutput',false)');           
           fprintf(fid,'%s\n', AddDampingLoadCases{:});
           n_damping = n_damping + length(AddDampingLoadCases);
    elseif strcmp(DLC{k}, DLCs{1})                              % check if this is DLC 62
        warning('No DLC 62 INT, STA files found. Please check that turbine is supposed to have YPB (Yaw Power Backup).');
                                                                % print warning to check for YPB if it is
    else
        error('Missing INT, STA files.');                            % throw error in any other case
    end
end
fclose(fid);	% close text file
