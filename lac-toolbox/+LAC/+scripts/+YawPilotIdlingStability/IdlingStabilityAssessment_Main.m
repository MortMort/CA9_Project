%% Idling Stability Assessment script
% 
%	Created: JOPMF 10/09/2019
%	Review:  JOPMF 18/03/2021
%   Review:  AAMES 22/12/2021
%
%	This script is used to assess stability during commissioning. 
%   Outputs generated are used by the YAW-Pilot software.
%
%   The outputs of this analysis allow to identify the most convenient wind
%   directions for a rotor to be parked in commissioning, so that edgewise 
%   vibrations can be avoided at different wind speeds.
%
%   The analysis can be performed considering different aero profiles, e.g.
%   STANDSTILL or FISHNETS, and understand if there is any benefit from the
%   installation of fishnets.
%
%   The script is run in steps:
%	- Step01: Generates folder structure and VTS prep files;
%	- Step02: Post process results and prints outputs:
%		- Stability roses
%		- Root edgewise bending moment vs Wind Direction
%	- Step03: Imports created figures to a Word-format report
%

% INITIALIZATION ----------------------------------------------------------
clear; close all; clc;
addpath(genpath('c:\repo\lac-matlab-toolbox'));

% INPUTS ------------------------------------------------------------------
% VTS MODEL and FAT1 version
	TurbineID = 'EV150_TA27D00_Vexp0.1'; % Label for folder generation and navigation
	VTS_model = 'h:\Vidar\Investigations\535_LV-5863_V150_Fishnet_Assessment\_Models\V150_LTq_5.60_IEC_HH125.0_VAS_STE_TA27D00\V150_LTq_5.60_IEC_HH125.0_VAS_STE_TA27D00.txt'; % Path to the turbine VTS model without any DLCs specified
    BLD.profile = 'STANDSTILL';     % Blade profile name (c.f. BLD file)
    
% STEP TO RUN
	Step = 1;     
    
% SIMULATION CONDITIONS
	Options.WS_range   = [10:5:30 33]; 		    % From 10 m/s to V1, in 5 m/s steps
    Options.pitch      = 95;                    % Stop/Idling pitch position
    Options.Wshear     = 0.1;                   % wind shear
    Options.AirDensity = 1.225;                 % air density

% SCRIPT STEP CONTROL -----------------------------------------------------
% Unless a different refinement is desired, the conditions below should not be changed
    Options.WD_range = 0: 10: 350;
 	Options.TI_range = 0: 0.05: 0.2;
 	Options.AZ_range = 0: 10: 110;
    
    Options.turb_seeds = 12; % Number of seeds to be considered in turbulent cases
    Options.fam_method = 0;  % Family method, 0 (worst seed), 1 or 2

switch Step
    case 1
        LAC.scripts.YawPilotIdlingStability.functions.IdlingStabilityAssessment_Step01_PreProcess(TurbineID, VTS_model, Options, BLD)
    case 2
        LAC.scripts.YawPilotIdlingStability.functions.IdlingStabilityAssessment_Step02_PostProcess(TurbineID, Options, BLD);
    case 3
        LAC.scripts.YawPilotIdlingStability.functions.IdlingStabilityAssessment_Step03_Report(TurbineID, Options, BLD);
    otherwise
        error('ERROR: Invalid step number.')
end