function [mp,cp,fcp]=getParameters(VTSPath,AeroFile,IECname)
%Extracts model parameters(mp), free control parameters (fcp) and control
%parameters from a VTS setup where at least one simulation has been run,
%generating an out file.
%
%[mp,cp,fcp]=getParameters(VTSPath,AeroFile)
%
% - VTSPath:    Path to VTS simulation setup
% - AeroFile:   Path to aer file containing CP and CT tables
% - IECname:    Name of IEC file used to populate VTS folder

%JADGR, Mar 2012

%Create file paths
MasFile=fullfile(VTSPath,'\INPUTS\',[IECname '.mas']);
ControlFile=fullfile(VTSPath,'\INPUTS\ProdCtrl_params');
PitchFile=fullfile(VTSPath,'\INPUTS\PitchCtrl_params');

%copy cvs files to m files to be able to run them
dos(['copy ' ControlFile '.csv ' ControlFile '.m']);
dos(['copy ' PitchFile '.csv ' PitchFile '.m']);

%Get a list of outfiles
outlist=ls(fullfile(VTSPath,'OUT\*.OUT'));

%Check if an outfile exists
if isempty(ls)
    error('Parameter reader','No outfiles found. Please run VTS')
end

%Choose the first outfile in the list
OutFile=fullfile(VTSPath,'OUT',outlist(1,:));


%Only used when comparing with a hardcoded Matlab setup
% % Turbine configuration
% cfg.type='Standard';
% cfg.turbine='V164';
% cfg.fnet='50Hz';
% cfg.towtype='tub86';
% cfg.ctrltype = 'V2.4';
% cfg.ctrlopt.IndPitch = 'ON';
% cfg.bladeprofile = 'prepreg';
% cfg.noise_level = 'none';
% 
% %% Extract control parameters
% fcpo = fcp_v164_v24(cfg);
% %Compute control parameters
% [~,cpo]=cprecalc_v24(fcpo);

%Read controller data from csv file
[fcp,cp]=cpExtract(ControlFile,PitchFile);

%% Read model data from master file
MasInfo=readmas(MasFile);

mp.gen=MasInfo.gen;
mp.gen.inertia=MasInfo.drt.Jgen;

if isfield(mp.gen,'AuxLoss')
    mp.gen.AuxLossEnabled=true;
else
    mp.gen.AuxLossEnabled=false;
end


mp.cnv=MasInfo.cnv;

mp.drv.damping=MasInfo.drt.tors;
mp.drv.torsdamping=MasInfo.drt.tors;
mp.drv.gear_ratio=MasInfo.drt.Ngear;
mp.pit.timeconst=MasInfo.pit.TauP;
mp.pit.delay=MasInfo.pit.delay;
mp.pit.table=MasInfo.pit.table;

%% Compute model parameters from VTS data (int/sta files)
%None yet

%% Read model data computed by VTS from out file
OutInfo=readout(OutFile);

mp.rot.radius=OutInfo.rot.diameter/2;
mp.rot.inertia=3*OutInfo.blade.inertia+OutInfo.hub.inertiaY;


%% Read aerodynamic data from aero file
[mp.rot.cp,mp.rot.ct,mp.rot.lambda_tab,mp.rot.theta_tab] = loadaero(AeroFile);
end

