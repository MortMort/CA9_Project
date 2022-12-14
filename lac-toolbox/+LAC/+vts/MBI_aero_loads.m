function MBI_aero_loads(path, write_int, PLF)

% MBI_aero_loads - Reads INT files and output loads at BLD CoG.
% Reads INT files simulated with LC specifications from
% "MBI_AeroLoads_LC.m". This functions reads loads (forces and moments) at
% the blade root (hub coordinate system) and converts/transforms these to
% loads at the blade CoG. Loads are both reported in a coordinate system
% aligned with blade coordinate system and in a system aligned with x
% coinciding with the wind direction. Furthermore the function plots loads
% as function of inflow angle (only for loads in the wind aligned system).
% The function can write INT files with the converted/transformed data.
%
% Syntax:   MBI_aero_loads(path, write_int, PLF)
%
% Inputs:
%   path -      Folder where the simulations are performed (i.e. the Loads
%               folder).
%   write_int - Flag to indicate whether to write INT files with converted
%               data or not (1 = writes INT files, 0 = does not).
%  PLF -        PLF (partial load factor) to apply to loads.
%
% Example:
%    MBI_aero_loads_LC('h:\3MW\MK3\V1053450.072\IEC1A\', [10, 15, 20, 25], [-25:25, 155:205], 6)
%
% Other m-files required:   LAC.vts.convert()
%                           LAC.timetrace.int.readint()
%                           LAC.timetrace.int.GetIntSensors()
%                           LAC.timetrace.int.intwrite()
% Subfunctions: none
% MAT-files required: none

% Author: MIFAK, Mike Fonnesbæk Jensen
% December 2016; Last revision: 14-June-2017
% Updated by SRRMA to print average loads and coefficients on 26-July-2017

%% Read blade data
temp        = struct2cell(dir([path, '\Parts\BLD\*']));     % get list of files matching the wildcard search for BLD parts files
temp_size   = size(temp, 2);                                % number of files resulting from the search
for i = 1:temp_size                                         % start looping on the files
    ind = temp_size-i+1;                                    % index of current file (starting from the end of the list)
    if strcmp(temp{1, ind}, '.') || strcmp(temp{1, ind}, '..')
                                                            % check if file name is '.' or '..'
        temp(:, ind) = [];                                  % delete file from list if it is
    end
end
if size(temp, 2) > 1                                        % check if there are multiple BLD parts files
    error('Multiple BLD parts files, please select the proper one!')
                                                            % print error if more than one
end
BLD_part    = [path, 'PARTS\BLD\', temp{1}];                % full path to the BLD part file
BLD_dat     = LAC.vts.convert(BLD_part, 'BLD');             % read BLD part file
BLD_dat     = struct(BLD_dat);                              % convert blade data class to struct

%% Calculate blade CoG
BLD_dat.SectionTable.m_sec  = zeros(length(BLD_dat.SectionTable.m), 1);
                                                            % initiate vector for storing blade section masses (i.e. mass at each blade section)
BLD_dat.SectionTable.s_mom  = zeros(length(BLD_dat.SectionTable.m), 1);
                                                            % initiate vector storing static moment for each section
BLD_dat.SectionTable.A_sec  = zeros(length(BLD_dat.SectionTable.m), 1);
                                                            % initiate vector for storing projected area of each section
for i = 1:length(BLD_dat.SectionTable.m)                    % start looping on blade sections
    if i == 1                                               % check if first section
        BLD_dat.SectionTable.m_sec(i)   = BLD_dat.SectionTable.m(i)*(BLD_dat.SectionTable.R(i + 1) - BLD_dat.SectionTable.R(i))*0.5;
                                                            % calculate section mass
        BLD_dat.SectionTable.A_sec(i)   = BLD_dat.SectionTable.C(i)*(BLD_dat.SectionTable.R(i + 1) - BLD_dat.SectionTable.R(i))*0.5;
                                                            % calculate section area
    elseif i == length(BLD_dat.SectionTable.m)              % check if last section
        BLD_dat.SectionTable.m_sec(i)   = BLD_dat.SectionTable.m(i)*(BLD_dat.SectionTable.R(i) - BLD_dat.SectionTable.R(i - 1))*0.5;
                                                            % calculate section mass
        BLD_dat.SectionTable.A_sec(i)   = BLD_dat.SectionTable.C(i)*(BLD_dat.SectionTable.R(i) - BLD_dat.SectionTable.R(i - 1))*0.5;
                                                            % calculate section area
    else
        BLD_dat.SectionTable.m_sec(i)   = BLD_dat.SectionTable.m(i)*(BLD_dat.SectionTable.R(i + 1) - BLD_dat.SectionTable.R(i - 1))*0.5;
                                                            % calculate section mass
        BLD_dat.SectionTable.A_sec(i)   = BLD_dat.SectionTable.C(i)*(BLD_dat.SectionTable.R(i + 1) - BLD_dat.SectionTable.R(i - 1))*0.5;
                                                            % calculate section area
    end
    BLD_dat.SectionTable.s_mom_x(i)    	= BLD_dat.SectionTable.m_sec(i)*BLD_dat.SectionTable.Xcog(i);
                                                            % calculate static moment for section (x-direction)
    BLD_dat.SectionTable.s_mom_z(i)    	= BLD_dat.SectionTable.m_sec(i)*BLD_dat.SectionTable.R(i);
                                                            % calculate static moment for section (z-direction)
end
BLD_dat.mass    = sum(BLD_dat.SectionTable.m_sec);          % calculate total blade mass
BLD_dat.area    = sum(BLD_dat.SectionTable.A_sec);          % calculate total blade projected area
BLD_dat.s_mom_x = sum(BLD_dat.SectionTable.s_mom_x);        % calculate total blade static moment (x-direction)
BLD_dat.s_mom_z = sum(BLD_dat.SectionTable.s_mom_z);        % calculate total blade static moment (z-direction)
BLD_dat.CoGx    = BLD_dat.s_mom_x/BLD_dat.mass;             % calculate blade CoG position (x-direction)
BLD_dat.CoGz    = BLD_dat.s_mom_z/BLD_dat.mass - BLD_dat.SectionTable.R(1);
                                                            % calculate blade CoG position (z-direction) wrt. blade root
CoG         	= [BLD_dat.CoGx, 0, BLD_dat.CoGz];          % create vector of CoG coordinates
BLD_dat.CoG_chord = BLD_dat.SectionTable.C(abs(BLD_dat.SectionTable.R-BLD_dat.CoGz) == min(abs(BLD_dat.SectionTable.R-BLD_dat.CoGz))); % Finding the chord which is close to the Cg

%% Read INT files
sens            = {'Fx21h', 'Fy21h', 'Fz21h', '-Mx21h', 'My21h', 'Mz21h'};
                                                            % sensor names to find in INT files 
sens_indx       = zeros(length(sens), 1);                   % initiate vector for storing sensor indexes
sens_pit        = 'Pi2';                                    % pitch sensor name to find in INT files

    % Names and designations for plots and text file output
    name_plot       = {'F_x', 'F_y', 'F_z', 'M_x', 'M_y', 'M_z'};
    unit1           = {'kN', 'kN', 'kN', 'kNm', 'kNm', 'kNm'};
    unit2           = {'[kN]', '[kN]', '[kN]', '[kNm]', '[kNm]', '[kNm]'};
    name1           = {'FxCoG', 'FyCoG', 'FzCoG', 'MxCoG', 'MyCoG', 'MzCoG'};
    name2           = {'FxCoG_rot', 'FyCoG_rot', 'FzCoG_rot', 'MxCoG_rot', 'MyCoG_rot', 'MzCoG_rot'};
    coeff1          = {'CD', 'CL','CZ','CMx','CMy','CMz'};
    coeff_desc      = {'[Drag]', '[Lift]', '[Side Force]','[Roll Mom]','[Yaw Mom]','[Pitch Mom]'};

temp            = dir([path, 'INT\*.int']);                 % get list of all INT files
ts_data         = zeros(2, length(temp));                   % initiate vector for storing wind speed and inflow angle for each INT file
data_max1       = zeros(length(sens), length(sens), length(temp));  % array for storing max loads (time coherent sets) for each INT file (in the blade CSYS)
data_min1       = zeros(length(sens), length(sens), length(temp));  % array for storing min loads (time coherent sets) for each INT file (in the blade CSYS)
data_avg1       = zeros(length(sens), length(temp));        % array for storing average loads for each INT file (in the blade CSYS)
data_max2       = zeros(length(sens), length(sens), length(temp));  % array for storing max loads (time coherent sets) for each INT file (in the wind CSYS)
data_min2       = zeros(length(sens), length(sens), length(temp));  % array for storing min loads (time coherent sets) for each INT file (in the wind CSYS)
data_avg2       = zeros(length(sens), length(temp));        % array for storing average loads for each INT file (in the wind CSYS)
settings.SensorListConfig   = 'Auto Detection';             % settings for reading sensor file
pit             = zeros(length(temp), 1);                   % initiate vector for storing pitch angle in each INT file
inflow          = zeros(length(temp), 1);                   % initiate vector for storing inflow angle in each INT file
for i = 1:length(temp)                                      % start looping on INT files
    fprintf('Reading INT file %d out of %d (%.1f%%)\n', i, length(temp), i/length(temp)*100)
                                                            % print status to command window
    if i == 1                                               % check if this is the first file
        [geninfo, t, data_temp, ~]  = LAC.timetrace.int.readint([path, 'INT\', temp(i).name], 1, [], [], []);
                                                            % read INT file
        [~, ~, add_out]             = LAC.timetrace.int.GetIntSensors([path, 'INT\', temp(i).name], geninfo, settings);
                                                            % read sensor information
        for j = 1:length(sens)                              % start looping on sensors
            sens_indx(j)            = find(strcmpi(sens{j}, add_out.Name), 1);
                                                            % find sensor index
        end
        sens_indx_pit               = find(strcmpi(sens_pit, add_out.Name), 1);
                                                            % find sensor index for pitch sensor
    else
        try
            [~, ~, data_temp, ~]   	= LAC.timetrace.int.readint([path, 'INT\', temp(i).name], 1, [], [], []);
                                                            % read INT file
        catch
            uiwait(msgbox(sprintf('Rerun %s', [path, 'INT\', temp(i).name]), 'Error'));
                                                            % initiate message box and wait for user input, if unable to read INT file
            [~, ~, data_temp, ~]   	= LAC.timetrace.int.readint([path, 'INT\', temp(i).name], 1, [], [], []);
                                                            % try to read INT file again
        end
    end
    str_con                         = textscan(temp(i).name(1:end-7), 'MBI_AeroLoads_Wsp%02d_Inflow%03d');
                                                            % get data from file name (i.e. intended wind speed and inflow angle)
    ts_data(1, i)                   = str_con{1};           % store wind speed
    ts_data(2, i)                   = str_con{2};           % store inflow angle
    int_data1                       = data_temp(:, sens_indx)*PLF;
                                                            % store loads in array and multiply by PLF
    int_data1(:, 4)                 = -int_data1(:, 4);     % invert flap moment (it is stored as -Mx and therefore needs to be inverted to get Mx)
    pit(i)                          = round(mean(data_temp(:, sens_indx_pit)), 3);
                                                            % read pitch angle from INT file
    pit_rad                         = pit(i)*pi/180;        % calculate pitch angle in radians (i.e. convert from degrees)
    inflow(i)                       = 90 - pit(i);          % calculate inflow angle from pitch angle
    if inflow(i) < 0                                        % check if inflow is below 0
        inflow(i) = inflow(i) + 360;                        % convert to be within the interval [0, 360]
    end
    if abs(inflow(i) - ts_data(2, i)) > 10^-3               % check if pitch angle in INT file corresponds with intended inflow angle
        error('Pitch angle in INT file does not correspond to inflow angle, please check PIT parts file.')
                                                            % throw error if they don't
    end

    % Convert/transform loads
    rot                     = [cos(-pit_rad), sin(-pit_rad), 0; -sin(-pit_rad), cos(-pit_rad), 0; 0, 0, 1];
                                                            % rotation matrix for rotating into blade coordinate system
    int_data1(:, 1:3)       = (rot*int_data1(:, 1:3)')';    % rotate coordinate system - Forces (hub oriented to blade oriented)
    int_data1(:, 4:6)       = (rot*int_data1(:, 4:6)')';    % rotate coordinate system - Moments (hub oriented to blade oriented)
  	int_data1(:, 4:6)       = int_data1(:, 4:6) + cross(repmat(-CoG, size(int_data1, 1), 1), int_data1(:, 1:3));
                                                            % move to csys centered at blade CoG

    rot                     = [cos(pit_rad-pi/2), sin(pit_rad-pi/2), 0; -sin(pit_rad-pi/2), cos(pit_rad-pi/2), 0; 0, 0, 1];
                                                            % rotation matrix for rotating into wind coordinate system
    int_data2(:, 1:3)       = (rot*int_data1(:, 1:3)')';    % rotate coordinate system - Forces (blade oriented to wind oriented)
    int_data2(:, 4:6)       = (rot*int_data1(:, 4:6)')';    % rotate coordinate system - Moments (blade oriented to wind oriented)

    % Find max, min and mean values
    for j = 1:length(sens)                                  % start looping on sensors
        [~, ind_max]        = max(int_data1(:, j));         % find index of time step where sensor reaches max value (in blade CSYS)
        [~, ind_min]        = min(int_data1(:, j));         % find index of time step where sensor reaches min value (in blade CSYS)
        data_max1(j, :, i)  = int_data1(ind_max, :);        % store time coherent set of sensor values for time step
        data_min1(j, :, i)  = int_data1(ind_min, :);        % store time coherent set of sensor values for time step

        [~, ind_max]        = max(int_data2(:, j));         % find index of time step where sensor reaches max value (in wind CSYS)
        [~, ind_min]        = min(int_data2(:, j));         % find index of time step where sensor reaches min value (in wind CSYS)
        data_max2(j, :, i)  = int_data2(ind_max, :);        % store time coherent set of sensor values for time step
        data_min2(j, :, i)  = int_data2(ind_min, :);        % store time coherent set of sensor values for time step
    end
    data_avg1(:, i)         = mean(int_data1, 1);           % find average sensor values for INT file (in blade CSYS)
    data_avg2(:, i)         = mean(int_data2, 1);           % find average sensor values for INT file (in wind CSYS)

    % Write INT file with CoG centered and blade oriented loads
    if write_int                                            % check if write INT flag is set
        if ~exist([path, 'INT\CoG_centered'], 'dir')        % check if a "CoG_centered" subfolder already exists
            mkdir([path, 'INT\CoG_centered'])               % add subfolder if it doesn't
        end
        LAC.timetrace.int.intwrite([path, 'INT\CoG_centered\', temp(i).name], t(2)-t(1), [int_data1(:, :), int_data2(:, :)])
                                                            % write data to INT

        % Write sensor file
        if i == 1                                           % check if this is the first file written
            fid = fopen([path, 'INT\CoG_centered\sensor'], 'w');
                                                            % open sensor file for writing sensor info to
            wi  = [3, 8, 8, 9, 9, 8, 15, 35];               % width of columns in sensor file
            fprintf(fid, 'Sensor list for: int files with CoG centered blade reactions\r\n');
                                                            % write header to sensor file
            fprintf(fid, ['%', num2str(wi(1)), 's%', num2str(wi(2)), 's%', num2str(wi(3)), 's%', num2str(wi(4)), 's%', num2str(wi(5)), 's %-', num2str(wi(6)), 's%-', num2str(wi(7)), 's%-', num2str(wi(8)), 's\r\n'], 'No', 'forst', 'offset', 'korr. c', 'Volt', 'Unit', 'Navn', 'Beskrivelse');
                                                            % write column headers to sensor file
            for j = 1:6;                                    % start looping on sensors for blade CSYS loads
                fprintf(fid, ['%', num2str(wi(1)), 'd%', num2str(wi(2)), '.4f%', num2str(wi(3)), '.4f%', num2str(wi(4)), '.2f%', num2str(wi(5)), '.2f %-', num2str(wi(6)), 's%-', num2str(wi(7)), 's%-', num2str(wi(8)), 's\r\n'], j, 1, 0, 0, 1, unit1{j}, name1{j}, 'CoG centered and blade oriented');
                                                            % write data for blade CSYS loads
            end
            for j = 1:6;                                    % start looping on sensors for wind CSYS loads
                fprintf(fid, ['%', num2str(wi(1)), 'd%', num2str(wi(2)), '.4f%', num2str(wi(3)), '.4f%', num2str(wi(4)), '.2f%', num2str(wi(5)), '.2f %-', num2str(wi(6)), 's%-', num2str(wi(7)), 's%-', num2str(wi(8)), 's\r\n'], j, 1, 0, 0, 1, unit1{j}, name2{j}, 'CoG centered and blade oriented');
                                                            % write data for wind CSYS loads
            end
            fclose(fid);                                    % close sensor file
        end
    end
end

%% Find overall max values and plot load components as function of inflow angle
ts_data(2, ts_data(2, :)>270)   = ts_data(2, ts_data(2, :)>270) - 360;
                                                            % convert inflow angle values from fourth quadrant (i.e. from 270 to 360 degrees) to lie in negative first quadrant instead (i.e. -90 to 0 degrees)
Wsp                 = sort(unique(ts_data(1, :)));          % get unique and sorted list of wind speeds
alpha               = sort(unique(ts_data(2, :)));          % get unique and sorted list of inflow angles
j                   = 1;                                    % initiate counter for counting "ranges" in inflow angle vector
for i = 2:length(alpha)                                     % start looping on unique inflow angle vector
    if ~(abs(alpha(i) - alpha(i-1)) == abs(alpha(2) - alpha(1)))
                                                            % check if there is an inconsiste jump in inflow angle
        j = j + 1;                                          % increment counter
    end
end
alpha_plot          = reshape(alpha, [length(alpha)/j, j])';                            % create a reshaped inflow angle array for use in plots
data_max_Wsp1       = zeros(length(sens), length(sens), length(alpha), length(Wsp));    % initiate array for storing max data sorted by inflow angle and wind speed (blade CSYS)
data_min_Wsp1       = zeros(length(sens), length(sens), length(alpha), length(Wsp));    % initiate array for storing min data sorted by inflow angle and wind speed (blade CSYS)
data_avg_Wsp1       = zeros(length(sens), length(alpha), length(Wsp));                  % initiate array for storing average data sorted by inflow angle and wind speed (blade CSYS)
data_max_Wsp2       = zeros(length(sens), length(sens), length(alpha), length(Wsp));    % initiate array for storing max data sorted by inflow angle and wind speed (wind CSYS)
data_min_Wsp2       = zeros(length(sens), length(sens), length(alpha), length(Wsp));    % initiate array for storing min data sorted by inflow angle and wind speed (wind CSYS)
data_avg_Wsp2       = zeros(length(sens), length(alpha), length(Wsp));                  % initiate array for storing average data sorted by inflow angle and wind speed (wind CSYS)
plot_max            = zeros(size(alpha_plot, 1), size(alpha_plot, 2), length(sens), length(Wsp));   % initiate array for storing max data used in plots (wind CSYS)
plot_min            = zeros(size(alpha_plot, 1), size(alpha_plot, 2), length(sens), length(Wsp));   % initiate array for storing min data used in plots (wind CSYS)
plot_avg            = zeros(size(alpha_plot, 1), size(alpha_plot, 2), length(sens), length(Wsp));   % initiate array for storing average data used in plots (wind CSYS)
if ~exist([path, 'MBI_AeroLoad_figures\'], 'dir')           % check if figure folder already exists
    mkdir([path, 'MBI_AeroLoad_figures\']);                 % create it if it doesn't
end
for i = 1:length(Wsp)                                       % start looping on wind speeds
  	indx_Wsp        = Wsp(i) == ts_data(1, :);              % find indexes of INT files with correct wind speed
    for j = 1:size(alpha_plot, 1)                           % start looping on inflow angle "ranges"
        for k = 1:size(alpha_plot, 2)                       % start looping on inflow angles in "range"
            indx_alpha	= alpha_plot(j, k) == ts_data(2, :);    % find indexes of INT files with correct inflow angle
            indx_comb	= and(indx_Wsp, indx_alpha);        % find indexes of INT files with both correct wind speed and inflow angle
            data_avg_Wsp1(:, (j-1)*size(alpha_plot, 2) + k, i)	= mean(data_avg1(:, indx_comb), 2);
                                                            % store average sensor values for current combination of wind speed and inflow angle (blade CSYS)
            data_avg_Wsp2(:, (j-1)*size(alpha_plot, 2) + k, i)	= mean(data_avg2(:, indx_comb), 2);
                                                            % store average sensor values for current combination of wind speed and inflow angle (wind CSYS)

            for l = 1:length(sens)                          % start looping on sensors
                plot_max(j, k, l, i)	= max(data_max2(l, l, indx_comb), [], 3);   % store max sensor value for current combination of wind speed and inflow angle, for use in plots
                plot_min(j, k, l, i)	= min(data_min2(l, l, indx_comb), [], 3);   % store min sensor value for current combination of wind speed and inflow angle, for use in plots
                plot_avg(j, k, l, i)	= mean(data_avg2(l, indx_comb), 2);         % store average sensor value for current combination of wind speed and inflow angle, for use in plots

                temp                    = data_max1(l, l, :);                       % get temporary vector with sensor values for all INT files (only current sensor - blade CSYS)
                temp(~indx_comb)     	= NaN;              % set value for all INT file that doesn't have the correct wind speed or inflow angle to NaN
                [~, ind_max]         	= max(temp);        % find index of max value in remaining INT files
                [~, ind_min]           	= min(temp);        % find index of min value in remaining INT files
                data_max_Wsp1(l, :, (j-1)*size(alpha_plot, 2) + k, i)	= data_max1(l, :, ind_max);
                                                            % store time coherent set of values for current combination of wind speed and inflow angle (blade CSYS)
                data_min_Wsp1(l, :, (j-1)*size(alpha_plot, 2) + k, i)   = data_min1(l, :, ind_min);
                                                            % store time coherent set of values for current combination of wind speed and inflow angle (blade CSYS)

                temp                	= data_max2(l, l, :);                       % get temporary vector with sensor values for all INT files (only current sensor - blade CSYS)
                temp(~indx_comb)      	= NaN;              % set value for all INT file that doesn't have the correct wind speed or inflow angle to NaN
                [~, ind_max]          	= max(temp);        % find index of max value in remaining INT files
                [~, ind_min]           	= min(temp);        % find index of min value in remaining INT files
                data_max_Wsp2(l, :, (j-1)*size(alpha_plot, 2) + k, i)   = data_max2(l, :, ind_max);
                                                            % store time coherent set of values for current combination of wind speed and inflow angle (wind CSYS)
                data_min_Wsp2(l, :, (j-1)*size(alpha_plot, 2) + k, i)   = data_min2(l, :, ind_min);
                                                            % store time coherent set of values for current combination of wind speed and inflow angle (wind CSYS)
            end
        end
        for k = 1:length(sens)                              % start looping on sensors
            h = figure('position', [50, 50, 600, 450]);     % create figure for plotting
            plot(alpha_plot(j, :), plot_max(j, :, k, i))    % plot max values
            hold on                                         % hold plot (for more plots)
            plot(alpha_plot(j, :), plot_min(j, :, k, i))    % plot min values
            plot(alpha_plot(j, :), plot_avg(j, :, k, i))    % plot average values
            plot([min(alpha_plot(j, :)), max(alpha_plot(j, :))], [0, 0], 'k')
                                                            % plot x = 0 line
            hold off                                        % unhold plot
            xlim([min(alpha_plot(j, :)), max(alpha_plot(j, :))])
                                                            % set limits for x-axis
            legend('Max', 'Min', 'Avg', 'location', 'best') % add legends to plot
            xlabel('Inflow angle [deg]')                    % add x-label (i.e. inflow angle)
            ylabel([name_plot{k}, ' ', unit2{k}])           % add y-label (i.e. force/moment)
            fname = sprintf('Wsp%d_%s_Alpha%d_%d.png', Wsp(i), name_plot{k}, min(alpha_plot(j, :)), max(alpha_plot(j, :)));
                                                            % get file name for saving plot
            print('-dpng', '-r72', [path, 'MBI_AeroLoad_figures\', fname])
                                                            % save plot
            close(h)                                        % close figure
        end
    end
end

%% Write results to output text file
fid1    = fopen([path, 'MBI_AeroLoads.txt'], 'w');
fprintf(fid1, 'Aero Loads on blades in MBI (Blade Gripper)\r\n');
fprintf(fid1, 'Loads in the following include a PLF of %.2f\r\n\r\n', PLF);

fid2    = fopen([path, 'MBI_AeroLoads_mark.txt'], 'w');
fprintf(fid2, 'Aero Loads on blades in MBI (Blade Gripper)\r\n');
fprintf(fid2, 'Loads in the following include a PLF of %.2f\r\n\r\n', PLF);

for i = 1:length(Wsp)
    fprintf(fid1, '#%d# Aero Loads at Wsp = %.1f m/s\r\n', i, Wsp(i));
    fprintf(fid2, '#%d# Aero Loads at Wsp = %.1f m/s\r\n', i, Wsp(i));

    fprintf(fid1, '    #%d.%d# Average values of loads\r\n', i, 0);
    fprintf(fid1, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name1{1}, name1{2}, name1{3}, name1{4}, name1{5}, name1{6});
    fprintf(fid1, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

    fprintf(fid2, '    #%d.%d# Average values of loads\r\n', i, 0);
    fprintf(fid2, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name2{1}, name2{2}, name2{3}, name2{4}, name2{5}, name2{6});
    fprintf(fid2, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

    for j = 1:length(alpha)
        fprintf(fid1, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(j), data_avg_Wsp1(:, j, i));
        fprintf(fid2, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(j), data_avg_Wsp2(:, j, i));
    end
    fprintf(fid1, '\r\n');
    fprintf(fid2, '\r\n');

    for j = 1:length(sens)
        fprintf(fid1, '    #%d.%d# MAX(%s) | MIN(%s)\r\n', i, j, name1{j}, name1{j});
        fprintf(fid1, '    %12s%12s%12s%12s%12s%12s%12s | %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name1{1}, name1{2}, name1{3}, name1{4}, name1{5}, name1{6}, 'alpha', name1{1}, name1{2}, name1{3}, name1{4}, name1{5}, name1{6});
        fprintf(fid1, '    %12s%12s%12s%12s%12s%12s%12s | %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6}, '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

        fprintf(fid2, '    #%d.%d# MAX(%s) | MIN(%s)\r\n', i, j, name2{j}, name2{j});
        fprintf(fid2, '    %12s%12s%12s%12s%12s%12s%12s | %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name2{1}, name2{2}, name2{3}, name2{4}, name2{5}, name2{6}, 'alpha', name2{1}, name2{2}, name2{3}, name2{4}, name2{5}, name2{6});
        fprintf(fid2, '    %12s%12s%12s%12s%12s%12s%12s | %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6}, '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

        for k = 1:length(alpha)
            fprintf(fid1, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f | %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(k), data_max_Wsp1(j, :, k, i), alpha(k), data_min_Wsp1(j, :, k, i));
            fprintf(fid2, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f | %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(k), data_max_Wsp2(j, :, k, i), alpha(k), data_min_Wsp2(j, :, k, i));
        end
        fprintf(fid1, '\r\n');
        fprintf(fid2, '\r\n');

    end
    fprintf(fid1, '\r\n');
    fprintf(fid2, '\r\n');

end
fclose(fid1);

fclose(fid2);

%% Write results to report output
fid     = fopen([path, 'MBI_AeroLoads_ReportOutput.txt'], 'w');
fprintf(fid, 'Aero Loads on blades in MBI (Blade Gripper)\r\n');
fprintf(fid, 'Loads in the following include a PLF of %.2f\r\n\r\n', PLF);
fprintf(fid, 'Mass of blade: %.0f kg\r\n', BLD_dat.mass);
fprintf(fid, 'CoG of blade: [%.3f, %.3f, %.3f] m\r\n', CoG(1), CoG(2), CoG(3));
fprintf(fid, 'Projected area of blade: %.1f m^2\r\n\r\n', BLD_dat.area);
for i = 1:length(Wsp)
    fprintf(fid, '#%d# Aero Loads at Wsp = %.1f m/s\r\n', i, Wsp(i));
    fprintf(fid, '    #%d.%d# MAX values\r\n', i, 1);
    fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name_plot{1}, name_plot{2}, name_plot{3}, name_plot{4}, name_plot{5}, name_plot{6});
   	fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

    for j = 1:length(alpha)
        if ~mod(alpha(j), 2)
            fprintf(fid, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(j), diag(data_max_Wsp2(:, :, j, i)));
        end
    end
    fprintf(fid, '\r\n');
    fprintf(fid, '    #%d.%d# MIN values\r\n', i, 2);
    fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name_plot{1}, name_plot{2}, name_plot{3}, name_plot{4}, name_plot{5}, name_plot{6});
 	fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

    for j = 1:length(alpha)
        if ~mod(alpha(j), 2)
            fprintf(fid, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(j), diag(data_min_Wsp2(:, :, j, i)));
        end
    end
    fprintf(fid, '\r\n\r\n');
end
fclose(fid);
%% Write average results and coefficients to new report output
fid     = fopen([path, 'MBI_AvgAeroLoads_ReportOutput.txt'], 'w');
fprintf(fid, 'Average Aero Loads on blades in MBI (Blade Gripper)\r\n');
fprintf(fid, 'Loads in the following include a PLF of %.2f\r\n\r\n', PLF);
fprintf(fid, 'Mass of blade: %.0f kg\r\n', BLD_dat.mass);
fprintf(fid, 'CoG of blade: [%.3f, %.3f, %.3f] m\r\n', CoG(1), CoG(2), CoG(3));
fprintf(fid, 'Projected area of blade: %.2f m^2\r\n', BLD_dat.area);
fprintf(fid, 'Reference Chord: %.3f m\r\n', BLD_dat.CoG_chord);
fprintf(fid, 'Blade CoG from rotor center : %.3f m\r\n\r\n', BLD_dat.CoGz+BLD_dat.SectionTable.R(1));

for i = 1:length(Wsp)
    fprintf(fid, '#%d# Avg Aero Loads at Wsp = %.1f m/s\r\n', i, Wsp(i));
    fprintf(fid, '    #%d.%d# AVG values\r\n', i, 1);
    fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', name_plot{1}, name_plot{2}, name_plot{3}, name_plot{4}, name_plot{5}, name_plot{6});
   	fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', unit2{1}, unit2{2}, unit2{3}, unit2{4}, unit2{5}, unit2{6});

    for j = 1:length(alpha)
        if ~mod(alpha(j), 2)
            fprintf(fid, '    %12.1f%12.2f%12.2f%12.2f%12.1f%12.1f%12.1f\r\n', alpha(j), data_avg_Wsp2(:, j, i));
        end
    end
    fprintf(fid, '\r\n\r\n');
    fprintf(fid, '#%d# Avg Aero Coefficients at Wsp = %.1f m/s\r\n', i, Wsp(i));
    fprintf(fid, '    #%d.%d# AVG Coefficients\r\n', i, 2);
    fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', 'alpha', coeff1{1}, coeff1{2}, coeff1{3}, coeff1{4}, coeff1{5}, coeff1{6});
    fprintf(fid, '    %12s%12s%12s%12s%12s%12s%12s\r\n', '[deg]', coeff_desc{1}, coeff_desc{2}, coeff_desc{3}, coeff_desc{4}, coeff_desc{5}, coeff_desc{6});
    
    for j = 1:length(alpha)
        if ~mod(alpha(j), 2)
            fprintf(fid, '    %12.1f%12.3f%12.3f%12.3f%12.3f%12.3f%12.3f\r\n', alpha(j), (data_avg_Wsp2(1:3, j, i).*1000)./(0.5*1.225.*Wsp(i).*Wsp(i)*BLD_dat.area),(data_avg_Wsp2(4:6, j, i).*1000)/((0.5*1.225.*Wsp(i).*Wsp(i)*BLD_dat.area)*BLD_dat.CoG_chord));
        end
    end
    fprintf(fid, '\r\n\r\n\r\n');
end
fclose(fid);