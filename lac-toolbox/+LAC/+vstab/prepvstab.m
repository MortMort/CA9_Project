function [ArgVstab, STA]=prepvstab(simpath) 


%% 
simulationInfo  = LAC.vts.simulationdata(simpath);
masterFile      = fullfile(simulationInfo.simulationpath,'INPUTS',simulationInfo.masfile);

dataFromMasterfile  = LAC.vts.convert(masterFile);
profiles            = dataFromMasterfile.pro.default; %This can be a cell array of profile files

runname = 'VStab_NormalOperation';
stadat  = LAC.vts.stapost(simpath); 

stadat.readfiles('11*');
idxLC   = stadat.findLC('11');
idxWhub = stadat.findSensor('Vhub');
WS      = unique(round(stadat.stadat.mean(idxWhub,idxLC)));
LC      = regexp(sprintf('11%02.0f/',WS), '/','split');LC(end)=[];

STA.WS       = stadat.getLoad('Vhub','mean',LC(1:end))';
STA.Omega    = stadat.getLoad('Omega','mean',LC(1:end))';
STA.OmegaMin = stadat.getLoad('Omega','min',LC(1:end))';
STA.OmegaMax = stadat.getLoad('Omega','max',LC(1:end))';
STA.Pi2      = stadat.getLoad('Pi2','mean',LC(1:end))';

usrcfg = [STA.WS STA.Pi2 STA.Pi2 STA.Pi2 zeros(size(STA.WS,1),2) STA.Omega];


%%
% Define inputs common for all runs
flags.aero      = 1;   %aerodynamics? controls both static and dynamic , we need handle to turn off dynamic but keep static
flags.strucdamp = 1;   %structural damping?
flags.locks     = 0;   %free=0, genlock=1, rotorlock=2
flags.deform    = [1 0 1]; %due to aero, gravity, centrifugal?
flags.induction = 1;   %on=1, off=0
flags.bladeonly = 0;   %do blade only analysis =1  (blade 1)
flags.gui       = 0;   %Always zero when running from command line
numeig          = 20;  %number of eigenvalues to get
vexp            = 0.0; %wind shear exponent
azi_intervals   = 360; %degrees between azimuth intervals to perform averaging – for rotation only!
dstype          = 2;   %dynamic stall type: 0-None, 1 – Stig Oye, 2 – Beddoes Leishman
dsconsts        = [];  %dynamic stall constants (empty for defaults)
exprop          = [];  %['T:\DesignForStability\V120\Vstab\' strings_exprop{k} '.txt'];%['T:\DesignForStability\V120\Vstab\StructuralTwist_tip.txt']; %extra properties file
keepstations    = 1;   %tells VStab to keep every "keepstations" blade station (used to remove stations for faster processing)

% Configurations (not active)
Ws=[];                 %wind speed (m/s)
Pit=[];                %pitch (deg)
Azimuth=[];            %only for non-rotating cases (deg) (blade 1 down=0)
phidir=[];             %wind direction (deg, positive clockwise when looking down on turbine from above, 0=perpendicular to rotor)
rotationspeed=[];      %rpm

%State Space inputs and outputs ****************
inout=[];


%%
masfn=masterFile;
ArgVstab = v2struct(runname,masfn,profiles,usrcfg,exprop,...
            flags,numeig,azi_intervals,vexp,dstype,dsconsts,keepstations,...
            Ws,Pit,Azimuth,phidir,rotationspeed,inout);