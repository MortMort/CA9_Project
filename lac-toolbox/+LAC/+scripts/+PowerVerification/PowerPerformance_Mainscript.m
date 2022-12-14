%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: MODFY
% Date: 27/02/2019
% Object: Measurements processing
%
% Modified by JOPMF for Mk3A V174 Loads Verification campaign
% Modified by MACVL for EnVentus V162 Loads Verification campaign
% Modified by SEHIK Jan-2022 for LiDAR input and repo folder
%
% DESCRIPTION
% This script calls the functions for the evaluation of Power Performance Campaign. 
%
% Section "LAC inputs" must be updated with the inputs of the campaign. 
% !! Data for the excel sheet must be in accordance to the certification 
% documents (align with the Tech Lead)!!
%
% Section "T&V Data" must contain the paths fr the external measurements 
% (align with T&V the right data to use).
%
% Section "Simulation folder" must contain the path in which the simulations 
% for comparing with measurememts are located
%
% Section "Steps and processing" must be updated with the required options:
% Steps to run: 
% 1) Function to take in measured data, filter it, and create loadcases 
% for VTS simulation.
% ATTENTION: From step1 to step2 the simulations must be performed.
% 2) Function to create the sensor list which will be refered in the 
% later stages of the varification process.(relevant sensors are defined 
% on the excel sheet). This function also reads the simulations and 
% create data.dat1 format like measurement
% 3) Function to bin the data according to multiple parameters
% 4) Function to create comparison plots between meas. & VTS sim. 
% This function also calculates AEP.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; fclose all; clc;

import LAC.scripts.PowerVerification.*
import LAC.scripts.PowerVerification.auxiliary.*

%addpath(genpath('c:\repo\lac-matlab-toolbox'));
addpath('\\rifile\Group\Group_Technology_RD\Technology Rd Support\Verifikation\Programs\matlab\dat8\');


%% User inputs - Those data are to be !CHANGED! to align with your PP campaign

% LAC inputs
    InputInfo = 'PowerVerificationInputs_VIDAR.xlsx'; %PC taken from Document no.: 
    INTs_naming = 'V162_'; 
	LIDAR = 0; %Set to 0 if using met-mast measured dat, set to 1 if using LIDAR
	
% T&V Data
    dat_path = '\\vestas.net\data\_Data\Tech\General_Field\Platform-Vidar\V162_Vidar_237525_Oesterild_Pad4\Institute\03_Postprocessed_data\Post12\dat\'; 
    vpas_path = '\\vestas.net\data\_Data\Tech\General_Field\Platform-Vidar\V162_Vidar_237525_Oesterild_Pad4\Institute\03_Postprocessed_data\Post12\vpas\vpas_stat.mat';
    TV_filter = '\\vestas.net\data\_Data\Tech\General_Field\Platform-Vidar\V162_Vidar_237525_Oesterild_Pad4\Institute\03_Postprocessed_data\Post12\vpas\Filter_Final_corrected.mat'; % filter from TV, define as an empty char if no filter defined
    TI_filter = [0, 6, 12]; % TI_filter(1) = 1 or 0 with 1 = activate filter, TI_filter(2:3) lower and upper boundary of the filter 
    Shear_filter = [0, 0, 0.3] ;  % Shear_filter(1) = 1 or 0 with 1 = activate filter, Shear_filter(2:3) lower and upper boundary of the filter 
	LIDAR_quality_filters = 0; % Set to 1 to apply additional LIDAR_QualityFilters, 0 to exlude those filters
	
% Simulation folder
    SimFolder = 'h:\Vidar\Investigations\549_LV-4201_Power_Performance\Scripts_Filter_TV\Simulations\'; % Fill in after running VTS simulation
    StaPath   = [SimFolder 'Loads\STA\'];

% Steps and processing
    Steps_to_run = [1]; %% or [2:4]
    createDirectories = 1; % 0 = No, 1 = Yes
    ReportLevels.DNV  = 0; % DNV report = 1, Internal = 0
    set(0, 'DefaultFigureVisible', 'on'); % If you don't want figures appearing set to off
    bin_Vn = 1; % bin_Vn = 1 if the wind speed binning should be done in function of the normalised wind speed
                % bin_Vn = 0 if the wind speed binning should be done in function of the wind speed at the met mast level
    FlagInterpolAll=0; % FlagInterpolAll=1 if interpolation of the power for incomplete bins in the measurement dataset for AEP calculation should be forced 
					   % FlagInterpolAll=0 if follow the IEC standard 61400-12-2 requirements
%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Preparation
    if createDirectories == 1
        createPPFolderStructure();
    end

% Read and check input info  
    [WTG, Report, WTG.Pref] = ReadInputs_PP(InputInfo);

    WTGNames = fieldnames(WTG);
    for i =1:length(WTGNames)
        if isempty(WTG.(WTGNames{i}))
            msg = 'Error: WTG contains empty cells. Update the intput file with the right info inputs.';
            error(msg);
        end
    end

% Steps execution    
    if ismember(1,Steps_to_run)
	    disp('Running step 1');
		if LIDAR==1
			LIDAR_WindShear = 1 ;
			LIDAR_Turb = 1 ;
			LIDAR_WindVeer = 1 ;

			if LIDAR_WindShear ==1
				if ~exist('.\Output\01_LiDAR_ShearData\','dir')
					mkdir('.\Output\01_LiDAR_ShearData\')
				end
			end

			if LIDAR_WindVeer ==1
				if ~exist('.\Output\03_LiDAR_VeerData\','dir')
					mkdir('.\Output\03_LiDAR_VeerData\')
				end
			end

			if LIDAR_Turb ==1
				if ~exist('.\Output\02_LiDAR_TurbData\','dir')
					mkdir('.\Output\02_LiDAR_TurbData\')
				end
			end
			Step01_PrepMeasuredPrepVTSInput_PP_LIDAR(InputInfo,WTG,bin_Vn,LIDAR_WindShear,LIDAR_Turb,LIDAR_WindVeer,dat_path, vpas_path, TV_filter, LIDAR_quality_filters)
		else 
			Step01_PrepMeasuredPrepVTSInput_PP(InputInfo, INTs_naming, WTG, bin_Vn, dat_path, vpas_path, TV_filter, TI_filter, Shear_filter)
		end
	end

    if ismember(2,Steps_to_run)
        disp('Running step 02');
        Step02_ProcessSimuSta_CreateSensorListInput_PP(InputInfo,StaPath, WTG)
    end

    if ismember(3,Steps_to_run)
        disp('Running step 03');
        Step03_Binning_HypothesisTestingStatData_PP(WTG,bin_Vn,FlagInterpolAll)
    end

    if ismember(4,Steps_to_run)
        disp('Running step 04');
        Step04_Mod_CompareResults_Scatter_Bin_PP(WTG,ReportLevels.DNV,dat_path)
    end

