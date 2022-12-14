%% Idling Stability Assessment script - Combine results
% 
%	Created: AAMES 22/12/2021
%
%	This script is used to assess stability during commissioning. 
%   Outputs generated are used by the YAW-Pilot software.
%
%   This script is to be used after running Steps 01 to 03 from
%   IdlingStabilityAssessment_Main
%
%   The script contains Step 04 of the assessment, which combines 
%   the results from the desired variants/climate conditions 
%

% INITIALIZATION ----------------------------------------------------------
clear; close all; clc;
addpath(genpath('c:\repo\lac-matlab-toolbox'));

% INPUTS ------------------------------------------------------------------
% VTS MODELS
	TurbineID = {'EV150_S96A602_Vexp0.1', ...
        'EV150_S96A602_Vexp0.3',...
        'EV150_T966909_Vexp0.1',...
        'EV150_T966909_Vexp0.3'}; % Labels for folders to combine
    BLD.profile = 'STANDSTILL';     % Blade profile name (c.f. BLD file)

% OUTPUT FOLDER
    OutFolder = 'h:\Vidar\Investigations\535_LV-5863_V150_Fishnet_Assessment\_NewMethod_V01\_ResultsCombine\';

% RUN STEP 04 -------------------------------------------------------------
    LAC.scripts.YawPilotIdlingStability.functions.IdlingStabilityAssessment_Step04_Combine(TurbineID, OutFolder);