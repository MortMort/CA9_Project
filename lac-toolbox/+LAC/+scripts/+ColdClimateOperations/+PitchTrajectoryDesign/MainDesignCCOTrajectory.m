%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Cold Climate Operations (CCO) controller Main Tuning Script
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following script comes with a step by step guide to the tuning 
% procedure of the CCO ice opti-tip controller. The settings that should 
% not be modified are collected in LoadSettings.m, where the purpose of 
% each variable is also explained thoroughly.
% The tuning approach is called B-Tuning, where the ice shapes just serves 
% as a reference but the tuned pitch trajectory does not fit the max Cp of 
% each ice shape. Suggestions are provided below on how to pick the tuning
% parameters.
%
% Inputs to the tuning function getPitchVsCpVsTSR:
%   - settings: a struct with different fields. The fields of interests are
%               explained below. Explanation for other settings are 
%               available in LoadSettings.m
%   - PyroFiles: the .out files with the Cp tables of the ice shapes.
%               Typically these files are provided by the blades team.
%   - csvFiles: path to a ProdCtrlNormal file with the opti-tip controller
%               tuning.
%
% Outputs of getPitchVsCpVsTSR:
%   - A figure showing the opti-tip controller curve, with the optimal tsr
%       highlighted.
%   - Figures showing the 3D rendering of the Cp table for each ice shape 
%       in use.
%   - A set of figures showing the CCO pitch trajectory starting from 
%       nominal condtions to Cp = 0, for each tip-speed-ratio in the CCO
%       tip-speed-ratio, Cp to pitch map.
%   - A Figure showing the minimum and the maximum opti-pitch curve.
%   - Two figures showing the CCO pitch map, both as absolute pitch and
%       additive offset.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Requires LAC Matlab toolbox
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Cold Climate Operations 2021: FASAL, SIEMA, KAVAS.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all; clc; fnxt = 1;

%% Settings

% Select Rotor of Interest among: V90 V117, V120, V126, V136, V150, V162
TurbineofInterest='V136'; 

% The script loads the settings that are believed to stay constant during 
% the design phase of the CCO pitch trajectory.
LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.LoadSettings;

% Save figures showing the pitch trajectory at each and every
% tip-speed-ratio.
settings.SavePitchTrajectory = true; % [bool]

% B-Tuning:

% B-Tuning requires the following ingredients: Regions of Degradations 0, 1
% and 2 and their Cp boundaries; Pitch trajectory slope in each of the
% three regions of degradation. Negative slope means that the pitch
% increases further the lower is the Cp. The following tuning steps are 
% required:

% 0. Defining the nominal Cpmax at each tip-speed-ratio:

% Already existing turbine variants rely on the hardcoded Cp tables,
% available here:
% \tsw\application\phTurbineCommon\Simulink\Include\constant.m. 
% New variants rely on the CtrlInput.txt file (Px_SP_CpCtTablesFromFile = 1)
% Check in the csv of ProdCtrlNormal which tables are in use and reflect that 
% selection here. 
% If false, make sure that the ProductionMixed Cp curve matches that of the
% CtrlInput.txt file. In ProdCtrlNormal this choice is reflected on
% Px_OTC_CpTableFromFile = 1.
% This is important because the Regions boundaries are defined using Cp Max
% as reference. Should Cp Max at the design phase be different than that in
% use in the controller, then the Regions boundaries will be different too,
% and so will be the pitch trajectory. 

settings.Btuning.CpMaxFromHardcoded = true; % [bool]

% 1. Region of Degradation 0:
%
% Naming CpMax the nominal maximum power coefficient at a certain
% tip-speed-ratio, Region 0 covers the interval [0.85*CpMax 1.5*CpMax].
% While the upper bound (Btuning.RatioToNomCpForRegion0Start) is fixed to
% 1.5, the lower bound can be 0.85 and 1.
% 0.85 is the candidate value for those turbine variants with a positive 
% margin to stall (opti-pitch is tuned to the right of nominal CpMax). 
% 1 is the candidate value for those turbine variants with a negative or 0
% margin to stall. So far only Mk2A V117 has been found with such an
% opti-pitch tuning.
% The lower bound is named as Btuning.RatioToNomCpForRegion0End. If less
% than 1, there is an interval of Cp degradation where CCO does not
% increase the pitch angle. When a positive margin to stall (up to 1.5 deg)
% is applied around nominal TSR, there is no need to pitch further out, 
% else in light ice this means reducing power output.
settings.Btuning.RatioToNomCpForRegion0End = 0.85;

% 2. Region of Degradation 3:
%
% It has been observed that for high TSRs the stall pitch angle is reduced
% rather than increased. In order to account for that, dThetadCp is
% linearly reduced with increase of TSR in Region 3. Region 3 overlaps with
% the other regions, affecting their respective dThetadCp. Start and end
% points are speficied by a ratio to the TSR where Cp is max (LambdaOpt). 
% The value is picked such that at ~nominal TSR , the CCO pitch trajectory 
% crosses the worst case ice shape around the maximum. At TSR 10 there 
% should be half a degree pitch in compared to tuned opti-tip pitch.
% Btuning.RatioToLambdaOptForRegion3Start is picked as 0.95 and should work
% for all rotors but V90, which requires 1.
settings.Btuning.RatioToLambdaOptForRegion3Start = 0.95; 

% dThetadCpRatioAtRegion3End - At the end of Region 3, dThetadCp is scaled
% with this ratio from the dThetadCp otherwise specified in the other
% regions. At the start of region 3, dThetadCp is not scaled, and in
% between it is linearly interpolated from the two end points.
% Btuning.dThetadCpRatioAtRegion3End should be chosen as -0.1 for turbines
% whose margin to stall is positive at TSR > 9. For variants with zero or
% negative margin to stall Btuning.dThetadCpRatioAtRegion3End shall be set
% to 0. So far this has been observed only in V117 Mk2A.
settings.Btuning.dThetadCpRatioAtRegion3End = -0.1;

% 3. Pitch Slope Definition:
%
% Slope of pitch vs Cp used in Region 1. Depending on the variant, this
% tunable allows to pitch out between 1.5 and 3.5 degrees at nominal TSR at
% 0.5*NominalMaxCp. The chosen value helps getting closer to Cp Max in the
% most severe ice scenarios at lower TSRs.
settings.Btuning.dThetadCpRegion1 = -30;

%% Input - Pyro out files: 

% If settings.Btuning.CpMaxFromHardcoded = false, make sure to match the
% first element in the PyroFiles array to the .out file corresponding to 
% the Cp table in the CtrlInput.txt file. 

% When adding or updating a switch case, include the PyroFiles in order of
% increasing degradation. Also remember to add the path to the csvFile
% pointing to the nominal Opti-tip controller tuning, as this is used to
% define the starting point of the CCO pitch Trajectory.

switch TurbineofInterest
    case 'V90'
        % V90 profiles: 15/10/2020
        PyroFiles = {...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\BARE\profi-6_baseline_orig_mixed.out',... 
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\BARE-CFX\V90_Baseline_CFX_Production_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\HARD-RIME\V90_HR1-4H_CFX_Production_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\HARD-RIME\V90_HR5-4M_CFX_Production_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\HARD-RIME\V90_HR5-4Mx_CFX_Production_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V90_15102020\PyRO\HARD-RIME\V90_HR5-4Mxx_CFX_Production_r.out'}; 
        % Path from where to load the optiLambda curve
        csvFiles = 'h:\FEATURE\ColdClimate\Investigations\068_LCT-899_CreateAndTestV90Controller\Investigations\1_PowerCurveV90\PrdMix_CCODis\Loads\INPUTS\ProdCtrl_VTS_Mk7_V90_2MW_VCS_50Hz_112,8_hh80_Noise1,2,3,0_params_001.csv';
    case 'V117'
        % V117 profiles: 24/06/2020
        PyroFiles = {...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V117_24062020\PyRO\BARE\V117_3.3MW_production_mixed_v11_3bd.001_BL.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V117_24062020\PyRO\HARD-RIME\V117-3.3MW_profi55rootext_v11_3d_HR4-7_CFX.out',...      
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V117_24062020\PyRO\GLAZE-ICE\V117-3.3MW_profi55rootext_v11_3d_GL3-7_CFX.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V117_24062020\PyRO\HARD-RIME\V117-3.3MW_profi55rootext_v11_3d_HR2-7_CFX.out',...
              'h:\feature\ColdClimate\Simulation_Models\Pyro_IceShapes\V117_24062020\PyRO\HARD-RIME\V117-3.3MW_profi55rootext_v11_3d_HR2-7x_CFX.out',...
              };        
        % Path from where to load the optiLambda curve
        csvFiles = 'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V117_LemKar\SorbyOptiTipCurve.csv';	
    case 'V120'
        % V120 profiles: 24/06/2020
        PyroFiles = {...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V120_24062020\PyRO\Base\V120-NG01mod1_V16_production_mixed.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V120_24062020\PyRO\Eros4\v120_a51_erosion4.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V120_24062020\PyRO\Eros5\v120_a51_erosion5.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V120_24062020\PyRO\Eros6\v120_a51_erosion6.out'};        
        % Path from where to load the optiLambda curve	
        csvFiles = 'h:\FEATURE\ColdClimate\Investigations\068_LCT-899_CreateAndTestV90Controller\Build2020_20\MK11C_V120_2.2MW_50Hz_112.8_hh80_T785000\ProdCtrl_VTS_MK11C_V120_2.2MW_50Hz_112.8_hh80_T785000_Noise1_params_001.csv';	
 case 'V126'
     % V126 profiles: 14/10/2020
        PyroFiles = {...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\BARE\V126-3.3MW_IEC3A_optipitch.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\BARE-CFX\V126-3.3MW_IEC3A_optipitch_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\HARD-RIME\V126-3.3MW_IEC3A_optipitch_HR1-2_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\BARE_RB\V126-3.3MW_IEC3A_optipitch_RB1_VASApp2.out',...                      
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\SOFT-RIME\V126-3.3MW_IEC3A_optipitch_SR1-2_r.out',...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V126_28092020\PyRO\GLAZE-ICE\V126-3.3MW_IEC3A_optipitch_GL4-4_r.out',...
                      };
        % Path from where to load the optiLambda curve
        csvFiles = 'h:\FEATURE\ColdClimate\Investigations\067_LCT-1880(1)_CreateAndTestV126Controller\Investigations\PerformanceNoCpEstTimeConstant\PrdMix_CCODis\Loads\INPUTS\ProdCtrl_VTS_Mk2_V126_3.3MW_GS_113.3_hh137_Noise1,2,3,0_params_001.csv';  
case 'V136'
     % V136 profiles
        PyroFiles={...
              'h:\feature\ColdClimate\Simulation_Models\Pyro_IceShapes\V136_15082019\PyRO\Base\V136-NG01_production_mix_V12_iced-sects.out',...
              'h:\feature\ColdClimate\Simulation_Models\Pyro_IceShapes\V136_15082019\PyRO\LightIcing\V136-NG01_production_rough_V12_iced-sects_90ms.out',...
              'h:\feature\ColdClimate\Simulation_Models\Pyro_IceShapes\V136_15082019\PyRO\MediumIcing\V136-NG01_production_rough_V12_iced-sects_85ms.out',...
              'h:\feature\ColdClimate\Simulation_Models\Pyro_IceShapes\V136_15082019\PyRO\HeavyIcing\V136-NG01_production_rough_V12_iced-sects_75ms.out'};     
        % Path from where to load the optiLambda curve
        csvFiles = 'h:\FEATURE\ColdClimate\Investigations\000_PERFORMANCE\Mk3E_V136_HH112\Wk39\001_Baseline_CTR_20_19\PC\Normal\Rho1.32\INPUTS\ProdCtrl_VTS_Mk3E_V136_4.0MW_137.5_hh112.0_NoNoise_params.csv';
case 'V150'
     % V150 profiles: 23/06/2020
        PyroFiles = {...
              'h:\Vidar\PARTS\Profiles\Out-files\EnVentus_V150_RVG_STE.out',...
              'h:\feature\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_mixed_V10.out', ...
              'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_HRM3-4_CFX.out', ...
              'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_HRM4-4_CFX.out', ...
              'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_SR2-4_CFX.out', ...
              'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_SR4-4_CFX.out', ...
              'h:\feature\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_HRM1-1_CFX.out', ...
              'H:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_HRM2-2_CFX.out',...
              'h:\feature\ColdClimate\Simulation_Models\+++VTSModel+++\V150_HH105\002\_Parts\OutFIles\EV150_BARE_production_rough_V10_HRM2-4_CFX.out', ...
              'h:\FEATURE\ColdClimate\Simulation_Models\Pyro_IceShapes\V150_24062020\PyRO\HARD-RIME\EV150_BARE_production_rough_V10_HRM2-4_Scaled_CFX.out'
        }; 
     % Weibull parameters
        settings.Vavg = 8.5; %m/s
        settings.k = 2.3;
     % Path from where to load the optiLambda curve
        csvFiles = {'h:\Vidar\Control\ClassicalController\Release\Parameters\061\ProdCtrl_params_vidar_V150_5600kW_T966909_HH105_0.187Hz.csv'};        
case 'V162'
     % V162 profiles: 24/06/2020
       PyroFiles = {... 
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_RVG_mixed_STE_V3.out'...   
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_rough_HR1-2_CFX.out'...
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_rough_HR2-4_CFX.out'...
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_rough_HR3-2_CFX.out'...
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_rough_HR3-4_CFX.out'...
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFIles\V162_EnVentus_production_rough_HR4-4_CFX.out'...
        'h:\FEATURE\ColdClimate\Simulation_Models\+++VTSModel+++\V162_HH166\002\_Parts\OutFiles\V162_EnVentus_production_rough_HR4-4scaled_CFX.out'};
     % Path from where to load the optiLambda curve
        csvFiles = {'h:\Vidar\Control\ClassicalController\Release\Parameters\066\ProdCtrl_params_vidar_V162_5600kW_SA2A600_HH166_0.142Hz.csv'};
     % Weibull parameters
        settings.Vavg = 7.9; %m/s
        settings.k = 2.48;
    otherwise
        error('Turbine not found!');
end

%% Create the lookup table:

tic

[pitAngleVsCpVsTSR, deltaAngleVsCpVsTSR, TSR_vec, Cp_vec] = LAC.scripts.ColdClimateOperations.PitchTrajectoryDesign.getPitchVsCpVsTSR(PyroFiles, csvFiles, settings, fnxt, TurbineofInterest);

toc

% Return if getPitchVsCpVsTSR failed to run
if length(pitAngleVsCpVsTSR) == 1
    return;
end

% Save to MAT file the current computations
mkdir([pwd,'\MAT']);
MatFile = sprintf('CCO_%s.mat', datestr(now, 'yyyymmdd_HH_MM'));
save(fullfile('MAT\', MatFile), 'TSR_vec', 'pitAngleVsCpVsTSR','deltaAngleVsCpVsTSR', 'settings', 'PyroFiles', 'csvFiles', 'TurbineofInterest', 'BranchName');
