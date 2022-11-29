%clear classes
close all
clear all
clc

% See "wtLin Quick Guide" in DMS 0063-0328

%% Edit path to your repo
addpath('C:\repo\mrotr_personal\wtLin')

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


%% Setup experiment and ref
op=wtLin.operPoint.wind(12);

%------ Setup ----------------
lp=wtLin.linparms.calcParms(gp,op); % Get linear parameters
comp=wtLin.comps.calcComps(lp); % Get components (linear systems)
loop=wtLin.loops.calcLoops(comp); % Get pre-defined loops
c=comp.s; % Components can be called with c.Name
g=loop.s; % Loops can be called with g.Name
%-----------------------------
disp(['FLC operation (1/0): ' num2str(lp.s.stat.ctr.FullLoad)])

% Notice, parameter sweeps can be done by changing gp (slow) or lp (fast).


%% 1P 3P
Freq1P = lp.s.stat.genSpd / (gp.s.drt.gearRatio * 60);
Freq3P = 3*Freq1P;
disp(['1P and 3P freq [Hz] :  ' num2str(Freq1P) '   ' num2str(Freq3P)]);


%% Example: Loops, pre-calculated

% 0) g.FLC_CL_wRef2w_nT
% 1) g.FLC_CL_wRef2w

%% Example: Loops, using components

% 0) No tower included, pitchdyn=1, convdyn=1
% 1) Tower included, FATD inactive, pitchdyn=1, convdyn=1
% 2) Tower included, FATD active, pitchdyn=1, convdyn=1

% Close speed ctrl loop
SumRef = sumblk('e','wRef','w','+-');

warning off Control:combination:connect9
warning off Control:combination:connect10

sysFLC_CL_0 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,SumRef,'wRef','w');
sysFLC_CL_1 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'wRef','w');
sysFLC_CL_2 = connect(c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'wRef','w');

sysFLC_OL_0 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,'e','w');
sysFLC_OL_1 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,'e','w');
sysFLC_OL_2 = connect(c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,'e','w');

sysFLC_CLw_0 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,SumRef,'vfree','w');
sysFLC_CLw_1 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'vfree','w');
sysFLC_CLw_2 = connect(c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'vfree','w');

sysFLC_CLt_1 = connect(c.FLC,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'wRef','vy');
sysFLC_CLt_2 = connect(c.FLC,c.FATD,c.pitUn,c.cnvUn,c.gen,c.drt,c.aeroFLC,c.aeroThr,c.rotWind,c.towSprMassFa,SumRef,'wRef','vy');

warning on Control:combination:connect9
warning on Control:combination:connect10


%% Plots

P = bodeoptions;
P.FreqUnits = 'Hz';
%P.PhaseMatching = 'on';


%%%%%%%%%%%%%%%%%%%
% Pre-calculated loops
figure(1)
bode(g.FLC_CL_wRef2w_nT,'b',P)
hold on
bode(g.FLC_CL_wRef2w,'g',P)
grid on
%
figure(2)
step(g.FLC_CL_wRef2w_nT,'b')
hold on
step(g.FLC_CL_wRef2w,'g')
grid on
%
%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%
% New loops
figure(3)
bode(sysFLC_CL_0,'b',P)
hold on
bode(sysFLC_CL_1,'g',P)
hold on
bode(sysFLC_CL_2,'r',P)
grid on
%
figure(4)
step(sysFLC_CL_0,'b')
hold on
step(sysFLC_CL_1,'g')
hold on
step(sysFLC_CL_2,'r')
grid on
%
figure(5)
bode(sysFLC_CLt_1,'g',P)
hold on
bode(sysFLC_CLt_2,'r',P)
grid on
%
figure(6)
step(sysFLC_CLt_1,'g')
hold on
step(sysFLC_CLt_2,'r')
grid on

%%%%%%%%%%%%%%%%%%%
