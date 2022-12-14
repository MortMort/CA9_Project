function Plot_CP(lc_names_meas, lc_names_sims,Data, X_sens, Y_sens, X_sens2, X_sens3, X_SensorName, X_SensorName2, WShear_Sensor, WTG)

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
    figNo = 1;
    figure('Name', int2str(figNo), 'units', 'normalized', 'outerposition', [0 0 1 1]);
    figname1 = strcat('PowerCoefficient_WDirBin.fig');
    figname2 = strcat('PowerCoefficient_WDirBin.png');

% -------------------------------------------------------------------------       
% 1 - Scatter plots
% -------------------------------------------------------------------------
	
	import LAC.scripts.PowerVerification.auxiliary.Step03.Xbinning
	
%   1.1 - Formating
    left = subplot(1,2,1);
    axis square;
    axis([0 ceil(max(Data.dat1.data.mean(:, X_sens))) 0 1]);

    hold on;
    xlabel(X_SensorName, 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (scatter plot)', 'FontSize', 16);
    set(gca, 'XTick', 2: 2: ceil(max(Data.dat1.data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   1.2 - Measurement data 
    plot(Data.dat1.data.mean(:, X_sens), Data.dat1.data.mean(:,Y_sens), 'ob', 'MarkerSize', 5);
    plot(Data.dat2.data.mean(:, X_sens), Data.dat2.data.mean(:,Y_sens), 'or', 'MarkerSize', 5);
    plot(Data.dat3.data.mean(:, X_sens), Data.dat3.data.mean(:,Y_sens), 'og', 'MarkerSize', 5);

%   1.3 - Simulation data
    plot(Data.Simdat1.data.mean(:, X_sens), Data.Simdat1.data.mean(:,Y_sens), '*b', 'MarkerSize', 5);
    plot(Data.Simdat2.data.mean(:, X_sens), Data.Simdat2.data.mean(:,Y_sens), '*r', 'MarkerSize', 5);
    plot(Data.Simdat3.data.mean(:, X_sens), Data.Simdat3.data.mean(:,Y_sens), '*g', 'MarkerSize', 5);
    
    legend('Sector 225-315 Mean (Meas.)', 'Sector 240-300 Mean (Meas.)', 'Sector 255-285 Mean (Meas.)', 'Sector 225-315 Mean (Sim.)', 'Sector 240-300 Mean (Sim.)', 'Sector 255-285 Mean (Sim.)', 'location','northeast')%, 'FontSize', 12);
	
	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    hold off;

% -------------------------------------------------------------------------
% 2 - Bin plots (normalized Wind Speed)
% -------------------------------------------------------------------------

%   2.1 - Formating
    right = subplot(1,2,2); 
    axis square;
    axis([0 ceil(max(Data.dat1.data.mean(:, X_sens))) 0 1]);

    hold on;
    xlabel(['Bin ' X_SensorName2], 'FontSize', 16);
    ylabel('Power coefficient (-)', 'FontSize', 16);
    title('10-minutes statistics (binned plot)', 'FontSize', 16);
    set(gca,'XTick', 2: 2: ceil(max(Data.dat1.data.mean(:, X_sens))), 'FontSize', 14);
    grid on;

%   2.2 - Eliminates empty bins in measurement and simulation data
    zero = find(Data.dat1.mean(:,1) == 0);
    Data.dat1.mean(zero,:) = [];
    Data.Simdat1.mean(zero,:)  = [];
    
%   2.3 - Measurement data 
    plot(Data.dat1.mean(:, X_sens2), Data.dat1.mean(:, Y_sens), 'o-b', 'MarkerSize', 5, 'LineWidth', 2.0);
    plot(Data.dat2.mean(:, X_sens2), Data.dat2.mean(:, Y_sens), 'o-r', 'MarkerSize', 5, 'LineWidth', 2.0);
    plot(Data.dat3.mean(:, X_sens2), Data.dat3.mean(:, Y_sens), 'o-g', 'MarkerSize', 5, 'LineWidth', 2.0);

%   2.4 - Simulation data 
    plot(Data.Simdat1.mean(:, X_sens2), Data.Simdat1.mean(:, Y_sens), 'b--*', 'MarkerSize', 5, 'LineWidth', 2.0);
    plot(Data.Simdat2.mean(:, X_sens2), Data.Simdat2.mean(:, Y_sens), 'r--*', 'MarkerSize', 5, 'LineWidth', 2.0);
    plot(Data.Simdat3.mean(:, X_sens2), Data.Simdat3.mean(:, Y_sens), 'g--*', 'MarkerSize', 5, 'LineWidth', 2.0);

%   2.5 - Reference Power Curve
    plot(WTG.Pref(:, 1), WTG.Pref(:, 3), '-k', 'LineWidth', 2.0);
    legend('Sector 225-315 Mean (Meas.)', 'Sector 240-300 Mean (Meas.)', 'Sector 255-285 Mean (Meas.)', 'Sector 225-315 Mean (Sim.)', 'Sector 240-300 Mean (Sim.)', 'Sector 255-285 Mean (Sim.)', 'Reference', 'location','northeast')%, 'FontSize', 12); 

	% Data tips
    %dcm = cell(2,1);
    dcm = datacursormode(gcf);
    dcm.Enable = 'on';
    dcm.UpdateFcn = {@display_lc_names,lc_names_sims,lc_names_meas};
	
    hold off;
    
% -------------------------------------------------------------------------
% 3 - Save data and figures
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