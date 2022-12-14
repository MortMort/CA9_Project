function VStab_BladeOnly(damping,standstillpitch,masfn,profiles,turbname,outpath)
% Used to run the VStab configurations for a single blade analysis

%% USER INPUT SECTION **********
wdir = [0:5:355]; % default wdir/yaw error for damping evaluations
pitch = standstillpitch(1);
% pitch=90; % Set to 90 to have the wind direction aligned with the pitch axis

%% ****************************
runname=[turbname '_PitchSweep_' num2str(damping.wsp) '.mat'];

%Full Run, operational setup data ****************
flags.aero = 1;
flags.strucdamp =0;%Turned off in this analysis to compare to 2D damping
flags.locks =1;  %set to 0 for idleing, set to 1 for locked
flags.deform =[1 1 1]; %deflection is fully turned on
flags.induction = 0; %no need for induction at standstill
flags.bladeonly = 1; %we want to run the full turbine
flags.gui=0; %Always zero when running from command line
numeig=20; %number of eigenvalues to get
vexp=0.0;  %wind shear exponent - zero
azi_intervals=360; %degrees between azimuth intervals to perform averaging – for rotation only!
dstype = 0; %dynamic stall type: 0-None, 1 – Stig Oye, 2 – Beddoes Leishman
dsconsts=[]; %dynamic stall constants (empty for defaults)
exprop=[]; 
keepstations=1; %tells VStab to keep every "keepstations" blade station (used to remove stations for faster processing)
inout=[];
usrcfg=[];
Pit=[1 1 1]*pitch;
Azimuth=[180]; %Blade vertically upwards
rotationspeed=0;  
%Run VStab  ******************
[Res,Info,Turbgeom,Flow,SSMod]=VStab2([outpath '/' runname],[masfn],profiles,usrcfg,exprop,...
    flags,numeig,azi_intervals,vexp,dstype,dsconsts,keepstations,...
    damping.wsp,Pit,Azimuth,wdir,rotationspeed,[]);

save([outpath '/' runname],'Res','Info','Turbgeom','Flow','SSMod','wdir')

