function Step04_Mod_CompareResults_Scatter_Bin_PP_v3(WTG,DNV,dat_path)
%% Purpose of this script:- ------------------------------------------------------------
% (i) This .m file is for creating comparison plots between meas. & VTS simulation for all important signals.
%       It includes scatter + bin plots + 95% CI stats. 
% (ii)Also creates the 20yrs fatigue table & fatigue stat comparison table for critical load sensors
% (iii) All figures & tables are saved with specific names, which will be used in report generation step05 again.

%% Given below are the few points to follow
%  1. Load the measured and simulation & stat compare processed data (output of step03) & sensorlist
%  2. Change the following inputs according to the requirements.
%  3. Change the main code only if needed.

%% Revision history
%%      Revision     Date        Author    Description of update
%       Rev0      3-Dec-2010     PRZIN       Initial script
%       Rev1     25-Apr-2018     RUSJE    Added new fatigue averaging
%       Rev2     23-Oct-2020     ATRSN    Added double binning plots for Wind direction

%% Input starts: ----------------------------------------------------------       

	import LAC.scripts.PowerVerification.auxiliary.*
	import LAC.scripts.PowerVerification.auxiliary.Step04.*
	
    % Loading measurement data -> Data structure: 'data'
    load ([pwd '\Output\Step03_Measurement_VTS_withBinning.mat']);
    
    % Loading sensor list ------> Data structure: 'SensorList'
    load ([pwd '\Output\Step03_SensorlistInput.mat']);

%% ********* Main code starts here ****************************************
% 1. Sensor selection and auxiliary data      
    sens = SensorList.sens;
    sensoption = {'Control_PwRpmPiAll'
%           'Bldrt_flpAll_edgAll';
%           'Bld_otherSection';
%           'Ms_TYrotating';
%           'Ms_TYfixed_Trq';
%           'TwrTop_Tor_long_lat';
%           'TwrBase_Tor_long_lat';
%           'Twr_otherSection';
%           'OtherSensors'
          }; 
     
     for i = 1:length(SensorList.sensorname(:,1))
         if strcmp(SensorList.sensorname(i,1), 'Wind speed (m/s)') == 1
             WS = i; 
            elseif strcmp(SensorList.sensorname(i,1), 'Wind speed normalised (m/s)') == 1
             WS_N = i;
            elseif strcmp(SensorList.sensorname(i,1), 'Nacelle wind speed (m/s)') == 1  
             WS_Nac = i;
            elseif strcmp(SensorList.sensorname(i,1), 'Power Coefficient as f. ofWind speed normalised(-)') == 1
             CP_sens = i;
            elseif strcmp(SensorList.sensorname(i,1), 'Electrical power (kW)') == 1
             P = i;
            elseif strcmp(SensorList.sensorname(i,1), 'Air density (kg/m3)') == 1
             rho = i;
         elseif strcmp(SensorList.sensorname(i,1), 'Wind shear (-)') == 1
             WShear = i;
         end
     
      end
     

%% Capture Matrix plot
    Plot_CaptureMatrix(WTG, load([pwd '\Output\Step01_SiteConditions.mat'], 'CapturMatrx'));

%% 3. Min. / Mean / Max. plots

% Loops through the labels selected in 'sensoption'
    for j=1:max(size(sensoption))

        % Loops through the sensors associated to the labels in 'sensoption'.
        % Values for these labels are read from the input file, e.g.:
        % Control_PwRpmPiAll = [2 3 4 5 6 7]

        for i = 1:max(size(SensorList.(sensoption{j})))
            Plot_MaxMinMean2(...
                WSpeed_bin.dat1, ...                                        % Measured data
                WSpeed_bin.Simdat1, ...                                     % Simulation data
                WS_N, ...                                                     % X sensor
                sens(SensorList.(sensoption{j})(i),1), ...                  % Y Sensor
                SensorList.sensorname{sens(WS_N, 1), 1}, ...                  % X Sensor name
                SensorList.sensorname{SensorList.(sensoption{j})(i),1},WTG);    % Y Sensor name
        end
    end

%% 4. Power Curve plot (with normalized wind speed)
    delta_PC = Plot_PowerCurve(...
        WSpeed_bin.dat1.data.name, ...                                  	% Measurement data name(scatter)
        WSpeed_bin.Simdat1.data.name, ...                                   % Simulation data name(scatter)
		WSpeed_bin.dat1, ...                                                % Measured data
        WSpeed_bin.Simdat1, ...                                             % Simulation data
        WS_N, ...                                                           % X sensor (Wind speed normalized)
        P, ...                                                              % Y Sensor
        WS, ...                                                             % X Sensor 2 (Met Mast wind speed)
        WS_Nac, ...                                                         % X Sensor 3 (Nacelle wind speed)
        SensorList.sensorname{WS_N, 1}, ...                                 % X Sensor name
        SensorList.sensorname{P, 1}, ...                                    % Y Sensor name
        WTG, ...                                                            % WTG data
        sens(WShear, 1));                                                   % Wind shear sensor
    
%% 5. Double binning plots

% 5.1 - Turbulence Intensity
     delta_TI = Plot_DoubleBin2(TI_bin, ...                                 % Binned structure
                               WS, ...                                      % X sensor
                               P, ...                                       % Y sensor
                               SensorList.sensorname{WS, 1}, ...            % X Sensor name
                               SensorList.sensorname{P, 1}, ...             % Y Sensor name
                               WTG, ...                                     % WTG data
                               'TI');                                       % Bin label

% 5.2 - Turbulence Intensity
    delta_WShear = Plot_DoubleBin2(WShear_bin, ...                          % Binned structure
                               WS, ...                                      % X sensor
                               P, ...                                       % Y sensor
                               SensorList.sensorname{WS, 1}, ...            % X Sensor name
                               SensorList.sensorname{P, 1}, ...             % Y Sensor name
                               WTG, ...                                     % WTG data
                               'WShear');                                   % Bin label   
                           
% 5.3 - Wind Direction
    delta_WDir = Plot_DoubleBin2(WDir_bin, ...                              % Binned structure
                               WS, ...                                      % X sensor
                               P, ...                                       % Y sensor
                               SensorList.sensorname{WS, 1}, ...            % X Sensor name
                               SensorList.sensorname{P, 1}, ...             % Y Sensor name
                               WTG, ...                                     % WTG data
                               'WDir');  

%% 6. Power coefficient plots

% 6.1 - Reference and scatter data CP calculation
    WTG.Pref(:, 3) = WTG.Pref(:, 2)*1000 ./ (0.5 * WTG.RhoRef * ((WTG.RotorDiameter/2)^2*pi()) * WTG.Pref(:, 1).^3);
    WSpeed_bin.dat1.data.mean(:, CP_sens)    = 1000 * WSpeed_bin.dat1.data.mean(:, P) ./ (0.5 .* WSpeed_bin.dat1.data.mean(:, rho) .* ((WTG.RotorDiameter/2)^2*pi()) .* WSpeed_bin.dat1.data.mean(:, WS).^3);
    WSpeed_bin.Simdat1.data.mean(:, CP_sens) = 1000 * WSpeed_bin.Simdat1.data.mean(:, P) ./ (0.5 .* WSpeed_bin.Simdat1.data.mean(:, rho) .* ((WTG.RotorDiameter/2)^2*pi()) .* WSpeed_bin.Simdat1.data.mean(:, WS).^3);
    
% % 6.2 - Plot
    Plot_CP(WSpeed_bin.dat1.data.name, ...                                  % Measurement data name(scatter)
        WSpeed_bin.Simdat1.data.name, ...                                   % Simulation data name(scatter)
        WSpeed_bin.dat1.data.mean, ...                                  % Measurement data (scatter)
        WSpeed_bin.Simdat1.data.mean, ...                                   % Simulation data (scatter)
        WSpeed_bin.dat1.mean, ...                                           % Measurement data (binned)
        WSpeed_bin.Simdat1.mean, ...                                        % Simulation data (binned)
        WS, ...                                                             % X Sensor (wind speed)
        CP_sens, ...                                                        % Y Sensor
        WS_N, ...                                                          % X Sensor 2 normalized wind speed
        WS_Nac, ...                                                         % X Sensor 3 (Nacelle wind speed)
        SensorList.sensorname{WS, 1}, ...                                   % X Sensor name
        SensorList.sensorname{WS_N, 1}, ...                                % X Sensor 2 name
        sens(WShear, 1), ...                                                % Wind shear sensor
        WTG);                                                               % WTG data
%%
    WDir_bin.dat1.data.mean(:, CP_sens)    = 1000 * WDir_bin.dat1.data.mean(:, P) ./ (0.5 .* WDir_bin.dat1.data.mean(:, rho) .* ((WTG.RotorDiameter/2)^2*pi()) .* WDir_bin.dat1.data.mean(:, WS).^3);
    WDir_bin.Simdat1.data.mean(:, CP_sens) = 1000 * WDir_bin.Simdat1.data.mean(:, P) ./ (0.5 .* WDir_bin.Simdat1.data.mean(:, rho) .* ((WTG.RotorDiameter/2)^2*pi()) .* WDir_bin.Simdat1.data.mean(:, WS).^3);
    
% % 6.3 - CP Plot for WDir Bin
    Plot_CP_WDir(WSpeed_bin.dat1.data.name, ...                                  % Measurement data name(scatter)
        WSpeed_bin.Simdat1.data.name, ...                                   % Simulation data name(scatter)
		WDir_bin, ...                                          				% WDir_Bin with measurement and simulation data
        WS, ...                                                             % X Sensor (wind speed)
        CP_sens, ...                                                        % Y Sensor
        WS_N, ...                                                          % X Sensor 2 normalized wind speed
        WS_Nac, ...                                                         % X Sensor 3 (Nacelle wind speed)
        SensorList.sensorname{WS, 1}, ...                                   % X Sensor name
        SensorList.sensorname{WS_N, 1}, ...                                % X Sensor 2 name
        sens(WShear, 1), ...                                                % Wind shear sensor
        WTG);                                                               % WTG data

%%
% %% 7 - Data filtering and plotting
% 
% %   7.1. - Determination of the trended wind speed
%     if exist([pwd '\Output\Step04_Wind_Detrending.mat'])
%         load([pwd '\Output\Step04_Wind_Detrending.mat']);
%     else
%         [detrend_info] = DetrendWS_filter(data, WTG,dat_path);
%     end
%     
% %   7.2. - Eliminates the trended wind speed, bins and produces plots
%     Plot_DetrendWind(detrend_info, WSpeed_bin.dat1.data.mean, WSpeed_bin.Simdat1.data.mean, SensorList.sensorname, WTG, 1);

    
%% clearing the work space
    if exist([pwd '\Output\Step04_Wind_Detrending.mat'])
        save([pwd '\Output\Step04_ResultsComparison_delta'], 'delta_PC', 'delta_TI', 'delta_WShear');
    else
        save([pwd '\Output\Step04_ResultsComparison_delta'], 'delta_PC', 'delta_TI', 'delta_WShear');% 'detrend_info');
    end

    clear all;