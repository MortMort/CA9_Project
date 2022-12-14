function Plot_CP(lc_names_meas, lc_names_sims, MeasData_scatter,  SimData_scatter,             MeasData_bin,       SimData_bin,             X_sens, Y_sens, X_sens2, X_sens3, X_SensorName,               X_SensorName2,                 WShear_Sensor, WTG)
%%Plot_CP(WSpeed_bin.dat1.data.mean,WSpeed_bin.Simdat1.data.mean,WSpeed_bin.dat1.mean,WSpeed_bin.Simdat1.mean,WS,     CP_sens, WS_N,    WS_Nac, SensorList.sensorname{WS, 1},SensorList.sensorname{WS_N, 1},sens(WShear, 1),WTG);

% % 6.2 - Plot
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author - JOPMF - 28/05/2019
% 
% Aim: Generate plots for a data input and a sensor number
%
% Inputs:
%       - Meas_data: struct variable with measurement data
%       - Sim_data: struct variable with simulation data
%       - X_sens: Sensor for the X-axis in the plots, e.g. wind speed
%       - Y_sens: Sensor for the Y-axis in the plots, e.g. Electrical Power
%       - X_SensorName: Name of the sensor in the X-axis
%       - Y_SensorName: Name of the sensor in the Y-axis
%       - WTG: Wind turbine matrix
%
% Outputs:
%       - delta: Matrix with percentage differences between measured and
%       simulated data (and the Reference, if used)
%               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    import LAC.scripts.PowerVerification.auxiliary.Step03.Xbinning
	
	figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCoefficient.fig');
    figname2 = strcat('PowerCoefficient.png');

% -------------------------------------------------------------------------       
% 1 - Scatter plots
% -------------------------------------------------------------------------

%   1.1 - Formating
    left = subplot(1,2,1);
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);

    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (scatter plot)', 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   1.2 - Measurement data 
    plot(MeasData_scatter(:, X_sens), MeasData_scatter(:,Y_sens), 'ob', 'MarkerSize', 5);
    set(gca,'Tag','meas')

%   1.3 - Simulation data
    plot(SimData_scatter(:, X_sens), SimData_scatter(:,Y_sens), 'or', 'MarkerSize', 5);
    set(gca,'Tag','meas')
    
    % Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    
    legend('Meas. mean', 'Sim. mean','Location','northeast')%,'FontSize', 12);
    hold off;

% -------------------------------------------------------------------------
% 2 - Bin plots (normalized Wind Speed)
% -------------------------------------------------------------------------

%   2.1 - Formating
    right = subplot(1,2,2); 
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);

    hold on;
    xlabel(['Bin ' X_SensorName2], 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (binned plot)', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   2.2 - Eliminates empty bins in measurement and simulation data
    zero = find(MeasData_bin(:,1) == 0);
    MeasData_bin(zero,:) = [];
    SimData_bin(zero,:)  = [];
    
%   2.3 - Measurement data 
    plot(MeasData_bin(:, X_sens2), MeasData_bin(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   2.4 - Simulation data 
    plot(SimData_bin(:, X_sens2), SimData_bin(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   2.5 - Reference Power Curve
    plot(WTG.Pref(:, 1), WTG.Pref(:, 3), '-k', 'LineWidth', 2.0);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'Reference C_P', 'location','northeast')%, 'FontSize', 12);        
    hold off;
    
% -------------------------------------------------------------------------
% 3 - Save data and figures
% -------------------------------------------------------------------------
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;
    
% -------------------------------------------------------------------------
% 4 - Filtering by Wind Shear (WShear < 0.3) and binning
% -------------------------------------------------------------------------

%   4.1 - Data filtering    
    j = 1;
    for i = 1:length(MeasData_scatter(:,1))
        if MeasData_scatter(i, WShear_Sensor) < 0.3
            Meas_filtered.data(j, :) = MeasData_scatter(i, :);
            Sim_filtered.data(j, :)  = SimData_scatter(i, :);
            
            j = j + 1;
        else
        end
    end

%   4.2 - Binning
    
    [Meas_filtered.WSpeed_binning] = Xbinning(Meas_filtered.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);
    [Sim_filtered.WSpeed_binning]  = Xbinning(Sim_filtered.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);    

    for j = 1:length(Meas_filtered.WSpeed_binning.index)
        if isempty(Meas_filtered.WSpeed_binning.index{j})
            Meas_filtered.WSpeed_binning.mean(j, :) = zeros(1, length(Meas_filtered.data(1, :)));
            
        elseif length(Meas_filtered.WSpeed_binning.index{j}) == 1
            Meas_filtered.WSpeed_binning.mean(j, :) = Meas_filtered.data(Meas_filtered.WSpeed_binning.index{j}, :);
            
        else
            Meas_filtered.WSpeed_binning.mean(j, :) = mean(Meas_filtered.data(Meas_filtered.WSpeed_binning.index{j}, :));
        end
    end
    
    for j = 1:length(Sim_filtered.WSpeed_binning.index)
        if isempty(Sim_filtered.WSpeed_binning.index{j})
            Sim_filtered.WSpeed_binning.mean(j, :) = zeros(1, length(Sim_filtered.data(1, :)));
            
        elseif length(Sim_filtered.WSpeed_binning.index{j}) == 1
            Sim_filtered.WSpeed_binning.mean(j, :) = Sim_filtered.data(Sim_filtered.WSpeed_binning.index{j}, :);
            
        else
            Sim_filtered.WSpeed_binning.mean(j, :) = mean(Sim_filtered.data(Sim_filtered.WSpeed_binning.index{j}, :));
        end
    end
    
% -------------------------------------------------------------------------       
% 5 - Scatter plots
% -------------------------------------------------------------------------
    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCoefficient_WShearfilt.fig');
    figname2 = strcat('PowerCoefficient_WShearfilt.png');
    
%   5.1 - Formating
    left = subplot(1,2,1);
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);
    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (scatter plot), Wind shear < 0.3', 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   5.2 - Measurement data 
    plot(Meas_filtered.data(:, X_sens), Meas_filtered.data(:,Y_sens), 'ob', 'MarkerSize', 5);

%   5.3 - Simulation data
    plot(Sim_filtered.data(:, X_sens), Sim_filtered.data(:,Y_sens), 'or', 'MarkerSize', 5);
    
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'location','northeast')%, 'FontSize', 14);
    hold off;

% -------------------------------------------------------------------------
% 6 - Bin plots (normalized Wind Speed)
% -------------------------------------------------------------------------

%   6.1 - Formating
    right = subplot(1,2,2); 
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);

    hold on;
    xlabel(['Bin ' X_SensorName2], 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (binned plot), Wind shear < 0.3', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   6.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered.WSpeed_binning.mean(zero,:) = [];
    clear zero
    zero = find(Sim_filtered.WSpeed_binning.mean(:,1) == 0);
    Sim_filtered.WSpeed_binning.mean(zero,:)  = [];
    
%   6.3 - Measurement data 
    plot(Meas_filtered.WSpeed_binning.mean(:, X_sens2), Meas_filtered.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   6.4 - Simulation data 
    plot(Sim_filtered.WSpeed_binning.mean(:, X_sens2), Sim_filtered.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   6.5 - Reference Power Curve
    plot(WTG.Pref(:, 1), WTG.Pref(:, 3), '-k', 'LineWidth', 2.0);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'Reference C_P', 'location','northeast')%, 'FontSize', 14);        
    hold off;
    
% -------------------------------------------------------------------------
% 7 - Save data and figures
% -------------------------------------------------------------------------
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;

% -------------------------------------------------------------------------
% 8 - Filtering based on differences between MetMast and Nacelle WS
% -------------------------------------------------------------------------

%   8.1 - Data filtering    
    j = 1;
    k = 1;
    for i = 1:length(MeasData_scatter(:,1))
        if 100*abs((MeasData_scatter(i, X_sens) - MeasData_scatter(i, X_sens3)) / (MeasData_scatter(i, X_sens))) < WTG.MM_Nacelle_Diff
            Meas_filtered2.data(j, :) = MeasData_scatter(i, :);
            Sim_filtered2.data(j, :)  = SimData_scatter(i, :);
            
            j = j + 1;
        else
            Meas_filtered2.data_out(k, :) = MeasData_scatter(i, :);
            Sim_filtered2.data_out(k, :)  = SimData_scatter(i, :);
            
            k = k + 1;
        end
    end

%   8.2 - Binning
    [Meas_filtered2.WSpeed_binning] = Xbinning(Meas_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);
    [Sim_filtered2.WSpeed_binning]  = Xbinning(Sim_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);    

    for j = 1:length(Meas_filtered2.WSpeed_binning.index)
        if isempty(Meas_filtered2.WSpeed_binning.index{j})
            Meas_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Meas_filtered2.data(1, :)));
            
        elseif length(Meas_filtered2.WSpeed_binning.index{j}) == 1
            Meas_filtered2.WSpeed_binning.mean(j, :) = Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :);
            
        else
            Meas_filtered2.WSpeed_binning.mean(j, :) = mean(Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :));
        end
    end
    
    for j = 1:length(Sim_filtered2.WSpeed_binning.index)
        if isempty(Sim_filtered2.WSpeed_binning.index{j})
            Sim_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Sim_filtered2.data(1, :)));
            
        elseif length(Sim_filtered2.WSpeed_binning.index{j}) == 1
            Sim_filtered2.WSpeed_binning.mean(j, :) = Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :);
            
        else
            Sim_filtered2.WSpeed_binning.mean(j, :) = mean(Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :));
        end
    end    
    
% -------------------------------------------------------------------------       
% 9 - Scatter plots
% -------------------------------------------------------------------------
    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCoefficient_WSCtrlfilt.fig');
    figname2 = strcat('PowerCoefficient_WSCtrlfilt.png');
    
%   9.1 - Formating
    left = subplot(1,2,1);
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);
    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title(['10-minutes statistics (scatter plot), Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff), ' %'], 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   9.2 - Measurement data 
    plot(Meas_filtered2.data(:, X_sens), Meas_filtered2.data(:,Y_sens), 'ob', 'MarkerSize', 5);

%   9.3 - Simulation data
    plot(Sim_filtered2.data(:, X_sens), Sim_filtered2.data(:,Y_sens), 'or', 'MarkerSize', 5);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    
    legend('Meas. mean', 'Sim. mean', 'location','northeast', 'FontSize')%, 14);
    hold off;

% -------------------------------------------------------------------------
% 10 - Bin plots (normalized Wind Speed)
% -------------------------------------------------------------------------

%   10.1 - Formating
    right = subplot(1,2,2); 
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);

    hold on;
    xlabel(['Bin ' X_SensorName2], 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title(['10-minutes statistics (binned plot), Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   10.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered2.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered2.WSpeed_binning.mean(zero,:) = [];
    clear zero
    zero = find(Sim_filtered2.WSpeed_binning.mean(:,1) == 0);
    Sim_filtered2.WSpeed_binning.mean(zero,:)  = [];
    clear zero
    
%   10.3 - Measurement data 
    plot(Meas_filtered2.WSpeed_binning.mean(:, X_sens2), Meas_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   10.4 - Simulation data 
    plot(Sim_filtered2.WSpeed_binning.mean(:, X_sens2), Sim_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   10.5 - Reference Power Curve
    plot(WTG.Pref(:, 1), WTG.Pref(:, 3), '-k', 'LineWidth', 2.0);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'Reference C_P', 'location','northeast')%, 'FontSize', 14);        
    hold off;
    
    % -------------------------------------------------------------------------
% 7 - Save data and figures
% -------------------------------------------------------------------------
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;
% -------------------------------------------------------------------------
% 12 - Filtering based on differences between MetMast and Ctrl WS
% -------------------------------------------------------------------------

%   8.1 - Data filtering    
    j = 1;
    k = 1;
    for i = 1:length(MeasData_scatter(:,1))
        if 100*abs((MeasData_scatter(i, X_sens) - MeasData_scatter(i, X_sens3)) / (MeasData_scatter(i, X_sens))) < WTG.MM_Nacelle_Diff*2
            Meas_filtered2.data(j, :) = MeasData_scatter(i, :);
            Sim_filtered2.data(j, :)  = SimData_scatter(i, :);
            
            j = j + 1;
        else
            Meas_filtered2.data_out(k, :) = MeasData_scatter(i, :);
            Sim_filtered2.data_out(k, :)  = SimData_scatter(i, :);
            
            k = k + 1;
        end
    end

%   8.2 - Binning
    [Meas_filtered2.WSpeed_binning] = Xbinning(Meas_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);
    [Sim_filtered2.WSpeed_binning]  = Xbinning(Sim_filtered2.data(:, X_sens), WTG.WSBinSize, 'WS', [], 1);    

    for j = 1:length(Meas_filtered2.WSpeed_binning.index)
        if isempty(Meas_filtered2.WSpeed_binning.index{j})
            Meas_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Meas_filtered2.data(1, :)));
            
        elseif length(Meas_filtered2.WSpeed_binning.index{j}) == 1
            Meas_filtered2.WSpeed_binning.mean(j, :) = Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :);
            
        else
            Meas_filtered2.WSpeed_binning.mean(j, :) = mean(Meas_filtered2.data(Meas_filtered2.WSpeed_binning.index{j}, :));
        end
    end
    
    for j = 1:length(Sim_filtered2.WSpeed_binning.index)
        if isempty(Sim_filtered2.WSpeed_binning.index{j})
            Sim_filtered2.WSpeed_binning.mean(j, :) = zeros(1, length(Sim_filtered2.data(1, :)));
            
        elseif length(Sim_filtered2.WSpeed_binning.index{j}) == 1
            Sim_filtered2.WSpeed_binning.mean(j, :) = Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :);
            
        else
            Sim_filtered2.WSpeed_binning.mean(j, :) = mean(Sim_filtered2.data(Sim_filtered2.WSpeed_binning.index{j}, :));
        end
    end    
    
% -------------------------------------------------------------------------       
% 9 - Scatter plots
% -------------------------------------------------------------------------
    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCoefficient_WSCtrlfilt10.fig');
    figname2 = strcat('PowerCoefficient_WSCtrlfilt10.png');
    
%   9.1 - Formating
    left = subplot(1,2,1);
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);
    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title(['10-minutes statistics (scatter plot), Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff*2), ' %'], 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   9.2 - Measurement data 
    plot(Meas_filtered2.data(:, X_sens), Meas_filtered2.data(:,Y_sens), 'ob', 'MarkerSize', 5);

%   9.3 - Simulation data
    plot(Sim_filtered2.data(:, X_sens), Sim_filtered2.data(:,Y_sens), 'or', 'MarkerSize', 5);
    
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'location','northeast', 'FontSize')%, 14);
    hold off;

% -------------------------------------------------------------------------
% 10 - Bin plots (normalized Wind Speed)
% -------------------------------------------------------------------------

%   10.1 - Formating
    right = subplot(1,2,2); 
    axis square;
    axis([0 ceil(max(MeasData_scatter(:, X_sens))) 0 1]);

    hold on;
    xlabel(['Bin ' X_SensorName2], 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title(['10-minutes statistics (binned plot), Met. Mast - Nacelle Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff*2), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(MeasData_scatter(:, X_sens))), 'FontSize', 14);
    grid on;

%   10.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered2.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered2.WSpeed_binning.mean(zero,:) = [];
    clear zero
    zero = find(Sim_filtered2.WSpeed_binning.mean(:,1) == 0);
    Sim_filtered2.WSpeed_binning.mean(zero,:)  = [];
    clear zero
    
%   10.3 - Measurement data 
    plot(Meas_filtered2.WSpeed_binning.mean(:, X_sens2), Meas_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   10.4 - Simulation data 
    plot(Sim_filtered2.WSpeed_binning.mean(:, X_sens2), Sim_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   10.5 - Reference Power Curve
    plot(WTG.Pref(:, 1), WTG.Pref(:, 3), '-k', 'LineWidth', 2.0);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    legend('Meas. mean', 'Sim. mean', 'Reference C_P', 'location','northeast')%, 'FontSize', 14);        
    hold off;
    
% -------------------------------------------------------------------------
% 7 - Save data and figures
% -------------------------------------------------------------------------
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
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