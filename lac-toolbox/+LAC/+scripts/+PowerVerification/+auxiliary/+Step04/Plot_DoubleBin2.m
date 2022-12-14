 function [delta] = Plot_DoubleBin2(Binned_struct, X_sens, Y_sens, X_SensorName, Y_SensorName, WTG, label)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author - JOPMF - 28/05/2019
%          ATRSN - 23/10/2020 - Added Wind Direction binning
% Aim: Generate plots for a data input and a sensor number
%
% Inputs:
%       - Binned_struct: struct variable with binned data for measurements
%       and simulation
%       - X_sens: Sensor for the X-axis in the plots, e.g. wind speed
%       - Y_sens: Sensor for the Y-axis in the plots, e.g. Electrical Power
%       - X_sens2: Optional sensor for the X-axis in the plots, e.g.
%       normalized wind speed (0 if not used)
%       - X_SensorName: Name of the sensor in the X-axis
%       - Y_SensorName: Name of the sensor in the Y-axis
%       - X_SensorName2: Name of the optional sensor in the X-axis (0 if 
%       not used)
%       - REF_data: Matrix with the reference data (0 if not used in the
%       plots)
%       - SC_WS: Success criteria wind speed values (vector or 0)
%       - SC_perc: Success criteria percentage values (vector or 0)
%       - label: Used in the figures naming
%               
% Outputs:
%       - delta: Matrix with percentage differences between measured and
%       simulated data (and the Reference, if used)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat(Y_SensorName,', ', label, ' bin.fig');
    figname2 = strcat(Y_SensorName,', ', label, ' bin.png');
    
    if strcmp(label, 'TI') == 1
        low_lim = WTG.TI_PlotLims(1);
        upp_lim = WTG.TI_PlotLims(2);
        
    elseif strcmp(label, 'WShear') == 1
        low_lim = WTG.Shear_PlotLims(1);
        upp_lim = WTG.Shear_PlotLims(2);
        
    elseif strcmp(label, 'Rho') == 1
        low_lim = WTG.Rho_PlotLims(1);
        upp_lim = WTG.Rho_PlotLims(2);
        
    elseif strcmp(label, 'WDir') == 1
        low_lim = WTG.WDir_PlotLims(1);
        upp_lim = WTG.WDir_PlotLims(2);
        
    else
        disp('Field ''label'' in the Plot_DoubleBin2 function must be one of the following options: \n 1) TI \n 2) WShear \n 3) Rho \n 4) WDir')
        disp('       1) TI')
        disp('       2) WShear')
        disp('       3) Rho')
        disp('       4) WDir')
        disp(' ')
        error('Error')
    end

% -------------------------------------------------------------------------
% 1 - Bin plots
% -------------------------------------------------------------------------
    
%   1.1 - Formating
    left = subplot(1,2,1);
    axis square;
    
    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title('10-minutes statistics (binned plot)', 'FontSize', 16);
    set(gca, 'FontSize', 14);
    grid on;

%   1.2 - Eliminates empty bins in measurement and simulation data
    for i = 1:length(Binned_struct.lowerbinlimit)
        eval(strcat('zero = find(Binned_struct.dat', num2str(i), '.mean(:,1) == 0);'));
        eval(strcat('Binned_struct.dat', num2str(i), '.mean(zero,:) = [];'));
        clear zero
        eval(strcat('zero = find(Binned_struct.Simdat', num2str(i), '.mean(:,1) == 0);'));
        eval(strcat('Binned_struct.Simdat', num2str(i), '.mean(zero,:) = [];'));
        clear zero
    end
    
    j = 1;  % Controls data flow in delta array
    A = {}; % Legend array
    
    col_vec = {'[0 0 1]', '[1 0 0]', '[0 0.5 0]', '[0 0 0]', '[1 0 1]', '[1 140/255 0]', '[0 1 0]', '[0 0.6 0.6]'};
    
    for i = 1:length(Binned_struct.lowerbinlimit)
        if (Binned_struct.lowerbinlimit{i} >= low_lim && Binned_struct.upperbinlimit{i} <= upp_lim)
            
%   Colours manipulation            
            col = j;
            while col > length(col_vec)
                col = col - length(col_vec);
            end
            
%   1.3 - Measurement data 
            eval(strcat('plot(Binned_struct.dat', int2str(i) ,'.mean(:, X_sens), Binned_struct.dat', int2str(i), '.mean(:, Y_sens), ''Color'', ', col_vec{col}, ', ''MarkerSize'', 5, ''LineWidth'', 1.5);'));
            if strcmp(label, 'TI') == 1          
                A{end + 1} = {strcat('Meas._{Bin: ', num2str(Binned_struct.lowerbinlimit{i}), '-', num2str(Binned_struct.upperbinlimit{i}), '% }')};
            else
                A{end + 1} = {strcat('Meas._{Bin: ', num2str(round(Binned_struct.lowerbinlimit{i},4)), '-', num2str(round(Binned_struct.upperbinlimit{i}, 4)), '}')};
            end
%   1.4 - Simulation data
            eval(strcat('plot(Binned_struct.Simdat', int2str(i) ,'.mean(:, X_sens), Binned_struct.Simdat', int2str(i), '.mean(:, Y_sens), ''Color'', ', col_vec{col}, ', ''LineStyle'', ''--'', ''MarkerSize'', 5, ''LineWidth'', 1.5);'));
            if strcmp(label, 'TI') == 1          
                A{end + 1} = {strcat('Sim._{Bin: ', num2str(Binned_struct.lowerbinlimit{i}), '-', num2str(Binned_struct.upperbinlimit{i}), '% }')};
            else
                A{end + 1} = {strcat('Sim._{Bin: ', num2str(round(Binned_struct.lowerbinlimit{i}, 4)), '-', num2str(round(Binned_struct.upperbinlimit{i}, 4)), '}')};
            end

%   1.5 - Delta calculations
            delta.lowerbinlimit(j) = Binned_struct.lowerbinlimit{i};
            delta.upperbinlimit(j) = Binned_struct.upperbinlimit{i};
            eval(strcat('delta.bin', num2str(j), '(:, 1) = round(Binned_struct.dat', int2str(i) ,'.mean(:, X_sens) * 2) / 2;'));
            eval(strcat('delta.bin', num2str(j), '(:, 2) = 100 * (-Binned_struct.dat', int2str(i) ,'.mean(:, Y_sens) + Binned_struct.Simdat', int2str(i), '.mean(:, Y_sens)) ./ Binned_struct.dat', int2str(i), '.mean(:, Y_sens);'));

            j = j + 1;
        else
        end
    end

    legend([A{:}], 'location', 'southeast', 'FontSize', 14);
    clear A;
    hold off;

% -------------------------------------------------------------------------
% 2 - Delta plot
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    ylim([-30 30]);
    
    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel('\Delta_{relative} (%)', 'FontSize',16);
    title('Success criteria evaluation', 'FontSize', 16);
    set(gca, 'FontSize',14);
    grid on;
    
    A = {}; % Legend array
    for i = 1:length(delta.lowerbinlimit)
        col = i;
        while col > length(col_vec)
            col = col - length(col_vec);
        end

        eval(strcat('plot(delta.bin', num2str(i), '(:, 1), delta.bin', num2str(i), '(:, 2), ''Color'', ', col_vec{col}, ', ''LineWidth'', 1.5);'));
        if strcmp(label, 'TI') == 1          
            A{end + 1} = {strcat('Bin: ', num2str(delta.lowerbinlimit(i)), '-', num2str(delta.upperbinlimit(i)), '%')};
        else
            A{end + 1} = {strcat('Bin: ', num2str(round(delta.lowerbinlimit(i),4)), '-', num2str(round(delta.upperbinlimit(i), 4)))};
        end

    end
    
    legend([A{:}], 'location', 'southeast', 'FontSize', 14);
    clear A;

% -------------------------------------------------------------------------
% 5 - Success criteria plot
% -------------------------------------------------------------------------

    for h = 2:max(length(WTG.SC_WS))
        a = area([WTG.SC_WS(h-1) WTG.SC_WS(h)], [WTG.SC_PC(h-1) WTG.SC_PC(h-1)]);
        a.FaceColor = [0 0.75 0.75];
        a.FaceAlpha = 0.25;
        a.LineStyle = 'none';
        a.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end

    for h = 2:max(length(WTG.SC_WS))
        a = area([WTG.SC_WS(h-1) WTG.SC_WS(h)], [-WTG.SC_PC(h-1) -WTG.SC_PC(h-1)]);
        a.FaceColor = [0 0.75 0.75];
        a.FaceAlpha = 0.25;
        a.LineStyle = 'none';
        a.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end    
    
    hold off;
    
% -------------------------------------------------------------------------
% 6 - Save data and figures
% -------------------------------------------------------------------------
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;

end