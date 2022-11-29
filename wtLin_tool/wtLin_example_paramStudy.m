%clear classes
close all
clear all
clc

% (Edit) Add path to wtLin
addpath('C:\repo\tsw\application\phTurbineCommon\Simulink\ControllerConfiguration')

%% Symbols and units
% w : omega Hss [rpm]
% W : omega Lss [rad/s]
% th : theta, pitch position [deg]
% P : power [W]
% M : torque (moment) [W/(rad/s)] = [Nm]


%% Extract parameters

% Import data from old style mat file.
% Modify and run "wtLin_example_getParam_matVer0.m" to get mat-file.
gp=wtLin.GrossParams.importFromOldMat('V164_8000kW_1B.mat');



%% Info param study functions
help wtLin.paramStudy


%% Setup studies (examples)

op=wtLin.operPoint.wind(12);

% defStudy : rows(studydef) columns(params)
% param: Name, Value, ValueAsGain(1/0)

SelectExampleStudy = 1; % edit, try different studies...

if SelectExampleStudy == 1
% Example: op parameters, diff wind speeds by abs, also change Kp
defStudy = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 1 1];
param = {...
    'op.s.env.wind',12,0;...
    'op.s.env.wind',14,0;...
    'op.s.env.wind',16,0;...
    'gp.s.ctr.flc.K_PI',1.3,1;...
    };
%
else
% Example: gp parameters, diff FLC Kp by gains, and diff Ti abs. 
defStudy = [1 0 0; 0 1 0; 1 0 1; 0 1 1];
param = {...
    'gp.s.ctr.flc.K_PI',1.0,1;...
    'gp.s.ctr.flc.K_PI',1.3,1;...
    'gp.s.ctr.flc.tau_i',8,0;
    };
%
end

%% Optional: Define non-standard systems (examples)

% define sum function to close loop
userSys{1} = sumblk('e','wRef','w','+-');

% Define first system, i.e. closed loop wRef -> w using pitUn and cnvUn.
cnctSys(1).comps = 'c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,userSys{1}';
cnctSys(1).in = 'wRef'; cnctSys(1).out = 'w';

% Define second system, i.e. closed loop vfree -> vy using pitUn and cnvUn.
cnctSys(2).comps = 'c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,userSys{1}';
cnctSys(2).in = 'vfree'; cnctSys(2).out = 'vy';


%% Call parameter study function

SelectNonStdSysExample = 1; % edit to try, call w/wo non-standard sys. 

if SelectNonStdSysExample == 1
    stdSysPlots = 0;
    [pp,cc,gg,hh] = wtLin.paramStudy(gp,op,param,defStudy,stdSysPlots,cnctSys,userSys);
else
    stdSysPlots = 1;
    [pp,cc,gg,hh] = wtLin.paramStudy(gp,op,param,defStudy,stdSysPlots,[],[]);
end



%% Optional: Plot non-standard systems (i.e. not plotted by paramStudy)

P = bodeoptions;
P.FreqUnits = 'Hz';
P.PhaseMatching = 'on';
plotCol = {'b','r','g','k','m','c','y'};

if SelectNonStdSysExample == 1
figure(1);

for jj = 1:length(hh)
    InFLC = pp{jj,1}.stat.ctr.FullLoad;
    if InFLC
        bode(hh{jj,1},plotCol{jj},P)
    else
        bode(hh{jj,1},plotCol{jj},P)
    end
    hold on
end
grid on
title('Closed Loop Bode (CL wRef2w)')

end

















