function outFile = baselineFreq(masfn,profiles,turbname,standstillpitch,idleflag,outpath)
% Establish edge mode frequencies (collective, tilt, yaw)

suffix={'locked','idle'};
wws=15;
runname=[turbname '_FreqAnalysis_' suffix{idleflag+1}];

%Full Run, operational setup data ****************
flags.aero = 1;
flags.strucdamp =1;
flags.locks =abs(1-idleflag);  %set to 0 for idleing, set to 1 for locked
flags.deform =[1 1 1]; %deflection is fully turned on
flags.induction = 0; %no need for induction at standstill
flags.bladeonly = 0; %we want to run the full turbine
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
Ws=wws;
if length(standstillpitch)<3
    Pit=[1 1 1]*standstillpitch(1);
else
    Pit=standstillpitch;
end
Azimuth=[180]; % azimuth angles
phidir=[0]; % wind directions
rotationspeed=0.1;  
%Run VStab  ******************
[Res,Info,Turbgeom,Flow,SSMod]=VStab2([outpath '/' runname],[masfn],profiles,usrcfg,exprop,...
    flags,numeig,azi_intervals,vexp,dstype,dsconsts,keepstations,...
    Ws,Pit,Azimuth,phidir,rotationspeed,[]);

outFile = [outpath '/' runname '.mat'];
save(outFile,'Res','Info','Turbgeom','Flow','SSMod')

