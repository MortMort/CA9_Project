function Plot_MaxMinMean2(Meas_data, Sim_data, X_sens, Y_sens, X_SensorName, Y_SensorName,WTG)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author - JOPMF - 28/05/2019
% Modified - MACVL - May/2021: Included power curve reference
% 
% Aim: Generate plots for a data input and a sensor number
%
% Inputs:
%       - Meas_data: struct variable with measurement data
%       - Sim_data: struct variable with simulation data
%       - X_sens: Sensor for the X-axis in the plots, e.g. wind speed
%       - Y_sens: Sensor for the Y-axis in the plots, e.g. Electrical Power
%       normalized wind speed (0 if not used)
%       - X_SensorName: Name of the sensor in the X-axis
%       - Y_SensorName: Name of the sensor in the Y-axis
%               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat(Y_SensorName,', MaxMeanMin.fig');
    figname2 = strcat(Y_SensorName,', MaxMeanMin.png');
    
% -------------------------------------------------------------------------       
% 1 - Scatter plot
% -------------------------------------------------------------------------

%   1.1 - Formating
    left = subplot(1,2,1);  
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    
    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title('10-minutes statistics (scatter plot)', 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(Meas_data.data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   1.2 - Measurement data 
    plot(Meas_data.data.mean(:, X_sens), Meas_data.data.mean(:, Y_sens), 'ob', 'MarkerSize', 5);
    set(gca,'Tag','meas')
    plot(Meas_data.data.mean(:, X_sens), Meas_data.data.max(:, Y_sens), '^b', 'MarkerSize', 5);
    set(gca,'Tag','meas')
    plot(Meas_data.data.mean(:, X_sens), Meas_data.data.min(:, Y_sens), '*b', 'MarkerSize', 5);
    set(gca,'Tag','meas')
    lc_names_meas = Meas_data.data.name;

%   1.3 - Simulation data
    plot(Sim_data.data.mean(:, X_sens), Sim_data.data.mean(:,Y_sens) , 'or', 'MarkerSize', 5);
    set(gca,'Tag','sims')
    plot(Sim_data.data.mean(:, X_sens), Sim_data.data.max(:,Y_sens) , '^r', 'MarkerSize', 5);
    set(gca,'Tag','sims')
    plot(Sim_data.data.mean(:, X_sens), Sim_data.data.min(:,Y_sens) , '*r', 'MarkerSize', 5);   
    set(gca,'Tag','sims')
    lc_names_sims = Sim_data.data.name;
    
    legend('Meas._{mean}', 'Meas._{max}', 'Meas._{min}', 'Sim._{mean}', 'Sim._{max}', 'Sim._{min}', 'location', 'southeast')%, 'FontSize', 14);
    hold off;

% -------------------------------------------------------------------------
% 2 - Bin plots (non-normalized Wind Speed)
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);

%   2.1 - Formating    
    hold on;
    xlabel(['Bin ' X_SensorName], 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title('10-minutes statistics (binned plot)', 'FontSize', 16);
    set(gca,'XTick',  2: 2: ceil(max(Meas_data.data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   2.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_data.mean(:,1) == 0);
    Meas_data.mean(zero,:) = [];
    Meas_data.max(zero,:)  = [];
    Meas_data.min(zero,:)  = [];
    Meas_data.std(zero,:)  = [];

    Sim_data.mean(zero,:) = [];
    Sim_data.max(zero,:)  = [];
    Sim_data.min(zero,:)  = [];
    Sim_data.std(zero,:)  = [];

%   2.3 - Measurement data plot
    plot(Meas_data.mean(:, X_sens), Meas_data.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','meas')
    plot(Meas_data.mean(:, X_sens), Meas_data.max(:, Y_sens), '^:b', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','meas')
    plot(Meas_data.mean(:, X_sens), Meas_data.min(:, Y_sens), '*--b', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','meas')

%   2.3 - Simulation data plot
    plot(Sim_data.mean(:, X_sens), Sim_data.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','sims')
    plot(Sim_data.mean(:, X_sens), Sim_data.max(:, Y_sens), '^:r', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','sims')
    plot(Sim_data.mean(:, X_sens), Sim_data.min(:, Y_sens), '*--r', 'MarkerSize', 5, 'LineWidth', 2.0);
    set(gca,'Tag','sims')
    hold on 
    
    %   Plot Reference Power Curve
    if Y_sens == 2
        plot(WTG.Pref(:, 1), WTG.Pref(:, 2), '-k', 'LineWidth', 2.0);
    else
           % do nothing
    end
    
    
    % Data tips
    dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
        
    legend('Meas._{mean}', 'Meas._{max}', 'Meas._{min}', 'Sim._{mean}', 'Sim._{max}', 'Sim._{min}', 'Reference C_P', 'location', 'southeast')%, 'FontSize', 14);
    hold off;
    
% -------------------------------------------------------------------------
% 3 - Save data and figures
% -------------------------------------------------------------------------
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;  
    
end

function txt = display_lc_names(~,info,lc_names_sims,lc_names_meas)
index = info.DataIndex;
% get the axes where the user has clicked
hAxesParent  = get(get(info,'Target'),'Parent');
axesTag = get(hAxesParent,'Tag');
% get corresponding DLC
if strcmp(axesTag,'sims')
    dlc = lc_names_sims{index};
elseif strcmp(axesTag,'meas')
    dlc = lc_names_meas{index};
end
txt = dlc;
fprintf('File selected: %s\n',txt);
end