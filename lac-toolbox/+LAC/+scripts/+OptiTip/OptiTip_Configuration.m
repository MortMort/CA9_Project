clc; clear all; close all;
% =========================================
% =========== INPUTS/SETTINGS =============
% =========================================
% This 3-step algorithm is based on the following methods for OTC
% optimization:
% 1. LAC Toolbox method (DMS 0055-4135) with rotor at free wheel for
% different settings. Stall limits are excluded from optimizer.
% 2. Method based on computing PC curves and then extracting optimum pitch.
% Method is only used on below rated WS.
% 3. Time in Stall based method that aims to establish OTC that satisfy 
% Time In Stall limits.

% ---------------------------------------------------
% ------- GENERAL SETTINGS --------------------------
% ---------------------------------------------------
% =========================================
% ========= >>> IMPORTANT <<< =============
% =========================================
% If you have any ctrl changes in your _CtrlParamChanges.txt file,
% make sure it is located in the same directory as prep template. If this
% file is to be empty, DO NOT place it next to your prep.

% Prep file template. Make sure it represents your turbine. BLD file must
% be defined as the one to be used. 
prepTemplate = 'o:\VY\V1749600.107\Investigations\034\3_OTC_TESTS\Mk11D_TEST\V120_2.20_IECS_HH92_HYB_STE_60HZ_T785C01.txt';
% Prep file template. The same as above but with BLD for PC computations
% i.e. having clean profiles.
PC_prepTemplate = 'o:\VY\V1749600.107\Investigations\034\3_OTC_TESTS\Mk11D_TEST\V120_2.20_IECS_HH92_HYB_STE_60HZ_T785C01.txt';

% Wind turbine Parameters
OTC.GBXRatio    = 90.3;
OTC.Radius      = 120/2; 
OTC.RatedPower  = 2200;  
OTC.RatedWS     = 9.0; % [m/s] rated wind speed. This can be approximate within 0.5m/s.

% Minimum and Maximum Generator Speeds
GRPM.min = 976; % Px_PSC_GenDeltaMinSpeedConnectedNormal 
GRPM.max = 1344; % Px_LDO_GenSpdSetpoint    

% First Guess OptiTip
Ref.OptiLambda      = 11.0;
Ref.OptiTip.TSR     = [1  3  5.5 5.7 6.2 7.2 8.91 9.85 10.4 11  11.3 12.53 14.32 17];
Ref.OptiTip.Pitch   = [45 18 9.4 8.8 6.8 4.4 2.3  1.3  1    2.4 2.6  3.4   4.1   4.8];     

% Directory names to be used for each step
OTC.Step_1.dir = 'VTS_step_1'; 
OTC.Step_2.dir = 'VTS_step_2'; 
OTC.Step_3.dir = 'VTS_step_3';  

% % Output direcotry
% OTC.Outdir = 'Results'; 

% Output names to be used for each step
OTC.Step_1.OTCfile = 'OptiTip_1.txt'; 
OTC.Step_2.OTCfile = 'OptiTip_2.txt'; 
OTC.Step_3.OTCfile = 'OptiTip_3.txt';  

% OTC steps to conduct. You can use this to ommit some steps.
% Must be a vector [1x3] with integers 0 or 1. 
% Example: to skip 2nd step use: [1 0 1];
OTC.Steps = [1 1 1];


% ---------------------------------------------------
% ------- STEP 1 SETTINGS ---------------------------
% ---------------------------------------------------
% Pitch variation around the first guess OptiLambda. If you are very
% uncertain about the OptiLambda, the Pitch.Amp should be high and you may
% want to do a first run with a high pitch step. If you think the first
% guess OptiLambda is close enough, then run with a smaller Pitch Amplitude
% and a smaller Pitch Step. It is recommended to use a Pitch Step of
% maximum 0.1 degree for final OptiTip curve.
Pitch.step  = 0.2;
Pitch.Amp   = 5.0;
Pitch.min   = -3.2;

% OptiLambda variation around the first guess OptiLambda.
OptiLambda.min      = Ref.OptiLambda - 2;
OptiLambda.max      = Ref.OptiLambda + 0.0;
OptiLambda.Step     = 0.2;

% Wind Speeds included in the OptiTip calculations
WS.min  = 4;
WS.step = 0.5;
WS.max  = 16; 

% Park configuration to optimise the OptiTip for. For single turbine, make
% time in wake = 0 (i.e. Wake.c = 0)
Wake.c = 0; %0.15;  % 15% time in wake
Wake.s = 5;     % 5D between turbines
Wake.k = 0.075; % onshore = 0.075

% Wind speed distribution to optimise the OptiTip for.
Weibull.V       = 8.0; 
Weibull.k       = 2.5; 
Weibull.Vin     = WS.min; 
Weibull.Vout    = WS.max; 
Weibull.step    = WS.step;

% ---------------------------------------------------
% ------- STEP 2 SETTINGS ---------------------------
% ---------------------------------------------------
% Pitch off-set range (string - min:step:max).
% Each value will be used to off-set from OTC from step 1.
OTC.Step_2.pitch_range = '-1.8:0.1:0.5';

% ---------------------------------------------------
% ------- STEP 3 SETTINGS ---------------------------
% ---------------------------------------------------
% Pitch off-set range (string - min:step:max).
% Each value will be used to off-set from OTC from step 2.
% It only makes sense to go towards positive range if Time in Stall is not
% satisfied.  
TimeInStall.pitch_range = '0:0.2:2.0'; 

% Set Wind Speeds for which Time In Stall limits are to be applied
TimeInStall.WS = [4 6 8 10 12 14 16 18 20];

% Time in positive stall limits
TimeInStall.R             = [0.500 0.600 0.700 0.800 0.900 1.000];% normalized radius in range <0,1>
TimeInStall.PositiveLimit = [0.010 0.010 0.010 0.010 0.010 0.010];%Ratio of time in positive stall


%% DO NOT CHANGE BELOW
% -----  STEP 1 --------
% Wind speeds at which the turbine may run in part 1 (min gen speed),
% part 2 (OptiLambda) or part 3 (max gen speed)
Part1.MaxWS = 2*pi*GRPM.min*OTC.Radius/(60*OTC.GBXRatio*OptiLambda.min); Part1.MaxWS = ceil(Part1.MaxWS/WS.step)*WS.step;
Part2.MinWS = 2*pi*GRPM.min*OTC.Radius/(60*OTC.GBXRatio*OptiLambda.max); Part2.MinWS = floor(Part2.MinWS/WS.step)*WS.step;
Part2.MaxWS = 2*pi*GRPM.max*OTC.Radius/(60*OTC.GBXRatio*OptiLambda.min); Part2.MaxWS = ceil(Part2.MaxWS/WS.step)*WS.step;
Part3.MinWS = 2*pi*GRPM.max*OTC.Radius/(60*OTC.GBXRatio*OptiLambda.max); Part3.MinWS = floor(Part3.MinWS/WS.step)*WS.step;
% -----  STEP 3 --------
% ----  Set up pitch variation range
OTC.Step_3.pitch_range = eval(TimeInStall.pitch_range);
% ----  Set up directory names
for i=1:length(OTC.Step_3.pitch_range)
    TimeInStall.sim_dir{i} = fullfile(pwd,OTC.Step_3.dir,sprintf('%03d',i));
end
% --- name of output dir for Time in Stall results
OTC.Step_3.name='TimeInStall';