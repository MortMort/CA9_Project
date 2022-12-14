function [delta] = Plot_PowerCurve(lc_names_meas, lc_names_sims, Meas_data, Sim_data, X_sens, Y_sens, X_sens2, X_sens3, X_SensorName, Y_SensorName, WTG, WShear_Sensor)

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
%       - REF_data: Matrix with the reference data (0 if not used in the
%       plots)
%       - SC_WS: Success criteria wind speed values (vector or 0)
%       - SC_perc: Success criteria percentage values (vector or 0)
%
% Outputs:
%       - delta: Matrix with percentage differences between measured and
%       simulated data (and the Reference, if used)
%               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	import LAC.scripts.PowerVerification.auxiliary.Step03.Xbinning 
	import LAC.scripts.PowerVerification.auxiliary.Step04.*

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCurve_SuccessCriteria.fig');
    figname2 = strcat('PowerCurve_SuccessCriteria.png');
	   
% -------------------------------------------------------------------------       
% 1 - Bin plot (normalized Wind Speed)
% -------------------------------------------------------------------------

%   1.1 - Formating
    left = subplot(1,2,1);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title('10-minutes statistics (binned plot)', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   1.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_data.mean(:,1) == 0);
    Meas_data.mean(zero,:) = [];

    Sim_data.mean(zero,:) = [];
    
%   1.3 - Measurement data plot
    plot(Meas_data.mean(:, X_sens), Meas_data.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   1.4 - Simulation data plot
    plot(Sim_data.mean(:, X_sens), Sim_data.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   1.5 - Reference Power Curve plot
    plot(WTG.Pref(:, 1), WTG.Pref(:, 2), '-k', 'LineWidth', 2.0);
	
	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
	
	legend('Meas._{mean}', 'Sim._{mean}', 'Reference Power Curve', 'location', 'southeast')%, 'FontSize', 14);        
    
    hold off;

% -------------------------------------------------------------------------
% 2 - Delta calculations
% -------------------------------------------------------------------------

%   2.1 - Measurements vs Simulation
    delta(:, 1) = 100 * ((-Meas_data.mean(:, Y_sens) + Sim_data.mean(:, Y_sens)) ./ Meas_data.mean(:, Y_sens));

%   2.2 - Reference vs Measurements / Simulations 
    array_intersection = intersect((round(Meas_data.mean(:, X_sens) * 2) / 2), WTG.Pref(:, 1));
    
    for i = 1:length(array_intersection)
        id_1 = find(WTG.Pref(:, 1) == array_intersection(i));
        id_2 = find((round(Meas_data.mean(:, X_sens) * 2) / 2) == array_intersection(i));
        
        delta(i, 2) = 100 * ((-WTG.Pref(id_1, 2) + Sim_data.mean(id_2, Y_sens)) / WTG.Pref(id_1, 2));
        delta(i, 3) = 100 * ((-Meas_data.mean(id_2, Y_sens) + WTG.Pref(id_1, 2)) / Meas_data.mean(id_2, Y_sens));
    end

% -------------------------------------------------------------------------
% 3 - Delta plot
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    ylim([-30 30]);
    
    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel('\Delta_{relative} (%)', 'FontSize', 16);
    title('Success criteria evaluation', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

    plot(array_intersection, delta(:, 1), 'o-b', 'LineWidth', 2.0);
    plot(array_intersection, delta(:, 2), '^-r', 'LineWidth', 2.0);
    plot(array_intersection, delta(:, 3), '*-k', 'LineWidth', 2.0);
	
	dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};

    legend('\Delta (Sim. - Meas.)_{mean}', '\Delta (Sim. - Ref.)_{mean}', '\Delta (Ref. - Meas.)_{mean}', 'location','northeast')%, 'FontSize', 14);

% -------------------------------------------------------------------------
% 4 - Success criteria plot
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
    
% -------------------------------------------------------------------------
% 5 - Save data and figures
% -------------------------------------------------------------------------
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;

% -------------------------------------------------------------------------
% 6 - Filtering by Wind Shear (WShear < 0.3) and binning
% -------------------------------------------------------------------------
    
%   6.1 - Data filtering
    j = 1;
    for i = 1:length(Meas_data.data.mean(:,1))
        if Meas_data.data.mean(i, WShear_Sensor) < 0.3
            Meas_filtered.data(j, :) = Meas_data.data.mean(i, :);
            Sim_filtered.data(j, :)  = Sim_data.data.mean(i, :);
            
            j = j + 1;
        else
        end
    end
    
%   6.2 - Binning
    
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
% 7 - Bin plot (normalized Wind Speed)
% -------------------------------------------------------------------------

%   7.1 - Formating

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCurve_SuccessCriteria_WShearfilt.fig');
    figname2 = strcat('PowerCurve_SuccessCriteria_WShearfilt.png');
    
    left = subplot(1,2,1);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    hold on;

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title('10-minutes statistics (binned plot), Wind shear < 0.3', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   7.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered.WSpeed_binning.mean(zero,:) = [];

    Sim_filtered.WSpeed_binning.mean(zero,:) = [];
    
%   7.3 - Measurement data plot
    plot(Meas_filtered.WSpeed_binning.mean(:, X_sens), Meas_filtered.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   7.4 - Simulation data plot
    plot(Sim_filtered.WSpeed_binning.mean(:, X_sens), Sim_filtered.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   7.5 - Reference Power Curve plot
    plot(WTG.Pref(:, 1), WTG.Pref(:, 2), '-k', 'LineWidth', 2.0);
	
	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
	
	legend('Meas._{mean}', 'Sim._{mean}', 'Reference Power Curve', 'location','southeast')%, 'FontSize', 14);        
    
    hold off;    

% -------------------------------------------------------------------------
% 8 - Delta calculations
% -------------------------------------------------------------------------

%   8.1 - Measurements vs Simulation
    delta2(:, 1) = 100 * ((-Meas_filtered.WSpeed_binning.mean(:, Y_sens) + Sim_filtered.WSpeed_binning.mean(:, Y_sens)) ./ Meas_filtered.WSpeed_binning.mean(:, Y_sens));

%   8.2 - Reference vs Measurements / Simulations 
    clear array_intersection;
    array_intersection = intersect((round(Meas_filtered.WSpeed_binning.mean(:, X_sens) * 2) / 2), WTG.Pref(:, 1));
    
    for i = 1:length(array_intersection)
        id_1 = find(WTG.Pref(:, 1) == array_intersection(i));
        id_2 = find((round(Meas_filtered.WSpeed_binning.mean(:, X_sens) * 2) / 2) == array_intersection(i));
        
        delta2(i, 2) = 100 * ((-WTG.Pref(id_1, 2) + Sim_filtered.WSpeed_binning.mean(id_2, Y_sens)) / WTG.Pref(id_1, 2));
        delta2(i, 3) = 100 * ((-Meas_filtered.WSpeed_binning.mean(id_2, Y_sens) + WTG.Pref(id_1, 2)) / Meas_filtered.WSpeed_binning.mean(id_2, Y_sens));
    end

% -------------------------------------------------------------------------
% 9 - Delta plot
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    ylim([-30 30]);

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel('\Delta_{relative} (%)', 'FontSize', 16);
    title('Success criteria evaluation, Wind shear < 0.3', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

    plot(array_intersection, delta2(:, 1), 'o-b', 'LineWidth', 2.0);
    plot(array_intersection, delta2(:, 2), '^-r', 'LineWidth', 2.0);
    plot(array_intersection, delta2(:, 3), '*-k', 'LineWidth', 2.0);

    legend('\Delta (Sim. - Meas.)_{mean}', '\Delta (Sim. - Ref.)_{mean}', '\Delta (Ref. - Meas.)_{mean}', 'location','northeast')%, 'FontSize', 14);
    
% -------------------------------------------------------------------------
% 10 - Success criteria plot
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
    
% -------------------------------------------------------------------------
% 11 - Save data and figures
% -------------------------------------------------------------------------
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;

% -------------------------------------------------------------------------
% 12 - Filtering based on differences between MetMast and Nacelle WS
% -------------------------------------------------------------------------
  
[Meas_filtered2,Sim_filtered2] = MetMastNac_Filter(Meas_data,Sim_data,X_sens,X_sens2,X_sens3,WTG);
   
% -------------------------------------------------------------------------       
% 14 - Bin plot (normalized Wind Speed)
% -------------------------------------------------------------------------

%   14.1 - Formating

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCurve_SuccessCriteria_WSCtrl.fig');
    figname2 = strcat('PowerCurve_SuccessCriteria_WSCtrl.png');
    
    left = subplot(1,2,1);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    hold on;

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title(['10-minutes statistics (binned plot), Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered2.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   14.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered2.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered2.WSpeed_binning.mean(zero,:) = [];

    Sim_filtered2.WSpeed_binning.mean(zero,:) = [];
    
%   14.3 - Measurement data plot
    plot(Meas_filtered2.WSpeed_binning.mean(:, X_sens), Meas_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   14.4 - Simulation data plot
    plot(Sim_filtered2.WSpeed_binning.mean(:, X_sens), Sim_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   14.5 - Reference Power Curve plot
    plot(WTG.Pref(:, 1), WTG.Pref(:, 2), '-k', 'LineWidth', 2.0);
	
	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
	legend('Meas._{mean}', 'Sim._{mean}', 'Reference Power Curve', 'location','southeast')%, 'FontSize', 14);        
    
    hold off;    

% -------------------------------------------------------------------------
% 15 - Delta calculations
% -------------------------------------------------------------------------

%   15.1 - Measurements vs Simulation
    delta3(:, 1) = 100 * ((-Meas_filtered2.WSpeed_binning.mean(:, Y_sens) + Sim_filtered2.WSpeed_binning.mean(:, Y_sens)) ./ Meas_filtered2.WSpeed_binning.mean(:, Y_sens));

%   15.2 - Reference vs Measurements / Simulations 
    clear array_intersection;
    array_intersection = intersect((round(Meas_filtered2.WSpeed_binning.mean(:, X_sens) * 2) / 2), WTG.Pref(:, 1));
    
    for i = 1:length(array_intersection)
        id_1 = find(WTG.Pref(:, 1) == array_intersection(i));
        id_2 = find((round(Meas_filtered2.WSpeed_binning.mean(:, X_sens) * 2) / 2) == array_intersection(i));
        
        delta3(i, 2) = 100 * ((-WTG.Pref(id_1, 2) + Sim_filtered2.WSpeed_binning.mean(id_2, Y_sens)) / WTG.Pref(id_1, 2));
        delta3(i, 3) = 100 * ((-Meas_filtered2.WSpeed_binning.mean(id_2, Y_sens) + WTG.Pref(id_1, 2)) / Meas_filtered2.WSpeed_binning.mean(id_2, Y_sens));
    end

% -------------------------------------------------------------------------
% 16 - Delta plot
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    ylim([-30 30]);

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel('\Delta_{relative} (%)', 'FontSize', 16);
    title(['Success criteria evaluation, Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered2.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

    plot(array_intersection, delta3(:, 1), 'o-b', 'LineWidth', 2.0);
    plot(array_intersection, delta3(:, 2), '^-r', 'LineWidth', 2.0);
    plot(array_intersection, delta3(:, 3),' *-k', 'LineWidth', 2.0);

    legend('\Delta (Sim. - Meas.)_{mean}', '\Delta (Sim. - Ref.)_{mean}', '\Delta (Ref. - Meas.)_{mean}', 'location','northeast')%, 'FontSize', 14);
    
% -------------------------------------------------------------------------
% 17 - Success criteria plot
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
    
% -------------------------------------------------------------------------
% 17 - Save data and figures
% -------------------------------------------------------------------------
    set(right, 'Position', [0.4 0.175 0.725 0.725]);
    set(left, 'Position', [-0.1 0.175 0.725 0.725]);
    saveas(figNo, [pwd '\Output_Figures\' figname1]);
    saveas(figNo, [pwd '\Output_Figures_PNG\' figname2]);
    close;
    
% -------------------------------------------------------------------------
% 12 - Filtering based on differences between MetMast and Nacelle WS
% -------------------------------------------------------------------------
  
[Meas_filtered2,Sim_filtered2] = MetMastNac_Filter10(Meas_data,Sim_data,X_sens,X_sens2,X_sens3,WTG);

    
% -------------------------------------------------------------------------       
% 14 - Bin plot (normalized Wind Speed)
% -------------------------------------------------------------------------

%   14.1 - Formating

    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCurve_SuccessCriteria_WSCtrl10.fig');
    figname2 = strcat('PowerCurve_SuccessCriteria_WSCtrl10.png');
    
    left = subplot(1,2,1);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    hold on;

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel(Y_SensorName, 'FontSize', 16);
    title(['10-minutes statistics (binned plot), Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff*2), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered2.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   14.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Meas_filtered2.WSpeed_binning.mean(:,1) == 0);
    Meas_filtered2.WSpeed_binning.mean(zero,:) = [];

    Sim_filtered2.WSpeed_binning.mean(zero,:) = [];
    
%   14.3 - Measurement data plot
    plot(Meas_filtered2.WSpeed_binning.mean(:, X_sens), Meas_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);

%   14.4 - Simulation data plot
    plot(Sim_filtered2.WSpeed_binning.mean(:, X_sens), Sim_filtered2.WSpeed_binning.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);

%   14.5 - Reference Power Curve plot
    plot(WTG.Pref(:, 1), WTG.Pref(:, 2), '-k', 'LineWidth', 2.0);
	
	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
	
	legend('Meas._{mean}', 'Sim._{mean}', 'Reference Power Curve', 'location','southeast')%, 'FontSize', 14);        
    
    hold off;    

% -------------------------------------------------------------------------
% 15 - Delta calculations
% -------------------------------------------------------------------------

%   15.1 - Measurements vs Simulation
    delta4(:, 1) = 100 * ((-Meas_filtered2.WSpeed_binning.mean(:, Y_sens) + Sim_filtered2.WSpeed_binning.mean(:, Y_sens)) ./ Meas_filtered2.WSpeed_binning.mean(:, Y_sens));

%   15.2 - Reference vs Measurements / Simulations 
    clear array_intersection;
    array_intersection = intersect((round(Meas_filtered2.WSpeed_binning.mean(:, X_sens) * 2) / 2), WTG.Pref(:, 1));
    
    for i = 1:length(array_intersection)
        id_1 = find(WTG.Pref(:, 1) == array_intersection(i));
        id_2 = find((round(Meas_filtered2.WSpeed_binning.mean(:, X_sens) * 2) / 2) == array_intersection(i));
        
        delta4(i, 2) = 100 * ((-WTG.Pref(id_1, 2) + Sim_filtered2.WSpeed_binning.mean(id_2, Y_sens)) / WTG.Pref(id_1, 2));
        delta4(i, 3) = 100 * ((-Meas_filtered2.WSpeed_binning.mean(id_2, Y_sens) + WTG.Pref(id_1, 2)) / Meas_filtered2.WSpeed_binning.mean(id_2, Y_sens));
    end

% -------------------------------------------------------------------------
% 16 - Delta plot
% -------------------------------------------------------------------------
    right = subplot(1,2,2);
    axis square;
    xlim([0 ceil(max(Meas_data.data.mean(:, X_sens)))]);
    ylim([-30 30]);

    hold on;
    xlabel('Wind speed bin (m/s)', 'FontSize', 16);
    ylabel('\Delta_{relative} (%)', 'FontSize', 16);
    title(['Success criteria evaluation, Met. Mast - Control Wind Speed deviations < ', num2str(WTG.MM_Nacelle_Diff*2), ' %'], 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Meas_filtered2.WSpeed_binning.mean(:, X_sens))), 'FontSize', 14);
    grid on;

    plot(array_intersection, delta4(:, 1), 'o-b', 'LineWidth', 2.0);
    plot(array_intersection, delta4(:, 2), '^-r', 'LineWidth', 2.0);
    plot(array_intersection, delta4(:, 3),' *-k', 'LineWidth', 2.0);

    legend('\Delta (Sim. - Meas.)_{mean}', '\Delta (Sim. - Ref.)_{mean}', '\Delta (Ref. - Meas.)_{mean}', 'location','northeast')%, 'FontSize', 14);
    
% -------------------------------------------------------------------------
% 17 - Success criteria plot
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
    
% -------------------------------------------------------------------------
% 17 - Save data and figures
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