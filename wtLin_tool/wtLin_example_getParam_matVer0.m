% See "wtLin Quick Guide" in DMS 0063-0328

% Example
% Generate parameters for V164

clc; clear all;

% (Edit) Add path to LAC Toolbox 
addpath('C:\repo\lac-matlab-toolbox')

% (Edit) Add path to wtLin
addpath('C:\repo\tsw\application\phTurbineCommon\Simulink\ControllerConfiguration')

% (Edit) Add path to ParameterReader (only until loadaero has been moved to LAC Toolbox)
addpath('C:\repo\tsw\application\phTurbineCommon\Simulink\ControllerConfiguration\ParameterReader')

% (Edit) Specify path to turbine files
%MasFile='o:\VY\V1648000.107\IECs.024\Loads\INPUTS\IECs.mas';
%CtrFile='o:\VY\V1648000.107\IECs.024\Loads\PARTS\CTR\V164_ctr_Mk1B_16.07.029';
%AerFile='o:\VY\Control\WorkSpace\AeroFiles\AeroFiles\V164-8MW_019.aer';
%BldFile='o:\VY\V1648000.107\IECs.024\Loads\PARTS\BLD\V164_bld_NoPA.027';

MasFile='h:\FEATURE\HighTowers\NewCtr\047\Mk3A_V126_3.45MW_113.3_hh137\Loads\INPUTS\V126_3.45_IEC3A_HH137_VDS_LTQ_T3III460.mas';
CtrFile='h:\FEATURE\HighTowers\NewCtr\047\Mk3A_V126_3.45MW_113.3_hh137\Loads\PARTS\CTR\CTR_Mk3A_V126_3.45MW_113.3_hh137_Unofficial.txt';
AerFile='C:\JSTHO\Matlab\wtLinTests\AeroFiles\V126-3.45MW_113_LowTorque.out';
BldFile='h:\FEATURE\HighTowers\NewCtr\047\Mk3A_V126_3.45MW_113.3_hh137\Loads\PARTS\BLD\Mk3_v126_deicing.002';

% Notes : Aero-files
% h:\3MW\MK2A\Profiles\Aer-files\ or under \BLD

[mp,cp,fcp] = wtLin.getTurbineParam(MasFile,CtrFile,BldFile,AerFile);

%% Manually entered data (not available in control parameter file)
cp.ctrl_delay           =   0.025;  % [s]       Communication delay
fcp.pit.MaxOutVolt		=   10; 	% [V]       Max pitch voltage
fcp.pit.MinOutVolt		=	-10;	% [V]       Min pitch voltage
fcp.Ts                  =   0.1;    % [s]       Sample time


%% Manually determined parameters, should be derived from VTS data
mp.drv.eigfreq = 1.6; % Calculated from inertias, stiffness and edge frequency
mp.drv.useEigFreq = 0; % If 1, use eigfreq for parametrising drt model
mp.gen.tau=0.01;  % Not directly available but might be computed from generator controller
mp.rot.tauIL=12; % Induction lag time constant. Found by experiments in VTS to be 12 for V100
mp.gen.gridFreq=50; % Hz


%% Compute reduced pitch table
%Assummed mean pitch moment to simplify pitch model
pitchMoment=-7;
tab = wtLin.getSimplePitchTable(pitchMoment,mp.pit.table);
mp.pit.dthetadt_tab=tab.data;
mp.pit.u_tab=tab.voltage;

%Compute pitch controller non-linearity table
[cp.pit.theta_tab,cp.pit.utab] = wtLin.pitchtab(fcp.pit);

%% DTD

mp.dtd.enable = 0; % 0: DTD not calculated.

% DTD general
mp.dtd.dtdType = 'Hp_Reson'; % Hp_Reson, Hp_HpLp
mp.dtd.convType = 'vcsv'; % vcsv, gapc
mp.dtd.fLpSpdEst = 20; % Normally 20 Hz; disabled if neg

% DTD Resonance filter (Hp_Reson) : KDtd,  fHpPre, fBwDtd, fDtDtd
mp.dtd.fDT = 1.5; % DTD.fDT_DTDPx [Hz]
mp.dtd.GDT_DTD_dB = 98; % DTD.GDT_DTDPx [W/(rad/s) dB]
mp.dtd.eta_BW = 0.7; % DTD.ETA_BW_DTDPx [Hz]
mp.dtd.fHpPre = 0.5; % fBW_OMEGAR_DTD_HPFPx [Hz]

% DTD Hp-Lp filter (Hp_HpLp) : KDtd, fHpPre, fHpDtd, fLpDtd
mp.dtd.K_LPF_HPF_DTD = 284869; % K_LPF_HPF_DTDPx [W/Hz]
mp.dtd.fHpPre = 1.0; % fBW_OMEGAR_DTD_HPFPx
mp.dtd.fHpDtd = 0.2563; % fBW_MOD_DTD_LPFPx [Hz]
mp.dtd.fLpDtd = 1.912; % fBW_MOD_DTD_LPFPx [Hz]

%% Tower

% V164
% gp.s.towSprMass.frqHz1 = 0.22;
% gp.s.towSprMass.hubHeight = 107;
% gp.s.towSprMass.mass = 4.78e+5;
% Mass: 3*massBlade+massHub+massNacelle (see out-file)
% 3*3.408e+4 + 8.23e+4 + 2.93e+5 = 477540

% V126
mp.twr.frqHz1 = 0.154;
mp.twr.hubHeight = 137;
%mp.towSprMass.frqHz1 = 0.13;
%mp.towSprMass.hubHeight = 166;
mp.twr.mass = 1.91670e+5;
% Mass: 3*massBlade+massHub+massNacelle (see out-file)
% 3*1.289e+04 + 3.30e+04 + 1.20e+05 = 191670

%% TEST FEATURES (DISABLED)

% Rotor damping by power in full load operation
fcp.flc.KRotDamp = 0;


%% Save data in mat fil

%save V164_8000kW_1B.mat cp fcp mp
save V112_3450kW_Mk3A.mat cp fcp mp
