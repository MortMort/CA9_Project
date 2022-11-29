function [mp,cp,fcp]=getTurbineParam(MasFile,CtrFile,BldFile,AerFile)
%
%Extracts model parameters(mp), free control parameters (fcp) and control
%parameters from a VTS setup where at least one simulation has been run,
%generating an out file.
%
%[mp,cp,fcp]=getTurbineParam(MasFile,CtrFile,OutFile,AeroFile)
%
% - MasFile:    Name of master file with full path
% - CtrFile:    Name of CTR file with full path
% - OutFile:    Name of one OUT file with full path
% - AeroFile:   Path to aer file containing CP and CT tables


%% To be fixed

%-------------------------%
mas_pitTauP = 0.01;
mas_pitDelay = 0;
%-------------------------%



%% Get controller data

CtrInfo = LAC.vts.convert(CtrFile);

% Find controller indices
ProdNormal_idx = find(ismember({CtrInfo.AuxDLLs.ControllerName},'ProdCtrlNormal'));
ProdFast_idx = find(ismember({CtrInfo.AuxDLLs.ControllerName},'ProdCtrl'));
Pitch_idx = find(ismember({CtrInfo.AuxDLLs.ControllerName},'PitchCtrl'));

% Read csv files
ProdNormal_parm = CtrInfo.AuxDLLs(ProdNormal_idx).Parameters;
ProdFast_parm = CtrInfo.AuxDLLs(ProdFast_idx).Parameters;
Pitch_parm = CtrInfo.AuxDLLs(Pitch_idx).Parameters;

% Extract parameters
%[fcp,cp] = cpExtractNew(ProdNormal_parm,ProdFast_parm,Pitch_parm);
[fcp,cp] = wtLin.ctrlParamExtract(ProdNormal_parm,ProdFast_parm,Pitch_parm);


%% Get model data from master file

MasInfo = LAC.vts.convert(MasFile);

%mp.gen = MasInfo.gen; % problem
mp.gen.poles = MasInfo.gen.PolePairs; % check if same
mp.gen.freq = MasInfo.gen.NetFrequency;
mp.gen.constLoss = MasInfo.gen.ConstLoss;
mp.gen.ElecEff.data = MasInfo.gen.G1ElEfficiency;
mp.gen.ElecEff.rpm = MasInfo.gen.RpmBinEl;
mp.gen.ElecEff.power = MasInfo.gen.PelBinEl;
mp.gen.MechEff.data = MasInfo.gen.G1MechEfficiency;
mp.gen.MechEff.rpm = MasInfo.gen.RpmBinMech;
mp.gen.MechEff.power = MasInfo.gen.PelBinMech;
mp.gen.AuxLoss.data = MasInfo.gen.AuxLoss;
mp.gen.AuxLoss.rpm = MasInfo.gen.RpmBinAux;
mp.gen.AuxLoss.power = MasInfo.gen.PelBinAux;

if isfield(mp.gen,'AuxLoss')
    mp.gen.AuxLossEnabled=true;
else
    mp.gen.AuxLossEnabled=false;
end

mp.gen.inertia = MasInfo.drv.Jgen;

mp.cnv.TauP = MasInfo.cnv.T_PM; % check
mp.cnv.TauI = MasInfo.cnv.Ti; % check
mp.cnv.Kp = MasInfo.cnv.kP; % check

mp.drv.torsStiffness = MasInfo.drv.kshtors;
mp.drv.torsDampingLogDecr = 0.1; % UPDATE WITH VARIABLE 
mp.drv.gear_ratio = MasInfo.drv.Ngear;

%mp.pit.timeconst = MasInfo.pit.TauP; % UPDATE IN MAS READER
mp.pit.timeconst = mas_pitTauP;
%mp.pit.delay = MasInfo.pit.delay; % UPDATE IN MAS READER
mp.pit.delay = mas_pitDelay;
mp.pit.table.data = MasInfo.pit.PitchRate;
mp.pit.table.voltage = MasInfo.pit.UctrlBin;
mp.pit.table.pitchMoment = MasInfo.pit.PitchMomentBin;


%% Get model data from Out file and other files

BldInfo = LAC.vts.convert(BldFile);
%HubInfo = LAC.vts.convert(HubFile);

mp.rot.radius = cp.sp.RotorRadius; % get radius from ctrl param

% rotor_inertia = 3*Imom + JYhub;
b=BldInfo.computeMass;
%mp.rot.inertia = 3*b.Imom + HubInfo.Iyhub;
mp.rot.inertia = 3*b.Imom;


%% Get data from aero file

[mp.rot.cp,mp.rot.ct,mp.rot.lambda_tab,mp.rot.theta_tab] = loadaero(AerFile);

% Alternatively :
%AeroInfo = LAC.pyro.ReadPyroOutFile(AeroFile)
%mp.rot.cp = AeroInfo.Cp_table_2;
%mp.rot.ct = AeroInfo.Ct_table_2;
%mp.rot.lambda_tab = AeroInfo.Row_2_Lambda;
%mp.rot.theta_tab = AeroInfo.Col_2_Theta;










