close all; 
clear; clc

% The V2 version is made because i just realized that the wtLin guide
% mentions that there are model problems with regards to FLC/PLC and the
% aeroFLC/aeroPLC components. It seems that only either FLC + aeroFLC or
% PLC + aeroPLC can be in a model at the same time. In this script PLC is
% left out entirely

% Comment out this if you dont want to re-run getParam every time. It takes
% extra time
% wtLin_getParam_V164_8MW

% See "wtLin Quick Guide" in DMS 0063-0328

% Edit path to your repo
addpath('h:\Offshore_TEMP\USERS\MROTR\wtLin_tool\')


% Symbols and units
% w : omega Hss [rpm]
% W : omega Lss [rad/s] (in guide it says rpm also)
% th : theta, pitch position [deg]
% P : power [W]
% M : torque (moment) [W/(rad/s)] = [Nm]
% thRef : [deg]
% Pref : [W]
% Pconv : [W]
% vfree : [m/s]
% py/px : [m]
% vy/vx : [m/s]
% pWy : [rad]
% vWy : [rad/s]


% Extract parameters

% Import data from old style mat file.
% Modify and run "wtLin_example_getParam_matVer0.m" to get mat-file.
gp=wtLin.GrossParams.importFromOldMat('V164_8MW.mat');

% Setup experiment and ref
opWindSpeed = 16;
op=wtLin.operPoint.wind(opWindSpeed);

%------ Setup ----------------
lp=wtLin.linparms.calcParms(gp,op); % Get linear parameters
comp=wtLin.comps.calcComps(lp);		% Get components (linear systems)
loop=wtLin.loops.calcLoops(comp);	% Get pre-defined loops
c=comp.s;					% Components can be called with c.Name
g=loop.s;					% Loops can be called with g.Name
%-----------------------------
disp(['FLC operation (1/0): ' num2str(lp.s.stat.ctr.FullLoad)])

% Notice, parameter sweeps can be done by changing gp (slow) or lp (fast).



% 1P 3P
% Freq1P = lp.s.stat.genSpd / (gp.s.drt.gearRatio * 60);
% Freq3P = 3*Freq1P;
% disp(['1P and 3P freq [Hz] :  ' num2str(Freq1P) '   ' num2str(Freq3P)]);

% JSTHO default loops and plots are located here:
% wtLin_jstho_systems_and_plots.m

% Initialize figure array for plotting:
figArray = [];
figNameArray = [];

%% Pull data for simulations
% -------------------------------
% The following section is dedicatd to pulling fata from .int files to use
% for inputs to a time simulation. If you don't need to run a time-series
% simulation don't run this section


% lax toolbox used for extracting data from .int files
addpath('C:\repo\lac-matlab-toolbox')

% (Edit) Ends up being the legend of the plots
simNames = [
			"fatd off, W = 16 m/s"
			"fatd off,lowturb W = 16 m/s"
			];

% (Edit) The names of the .int files (w.o. ".int")
intFileNames = [
				"1116a001"
				"1116a001"
			   ];

% (Edit) Put the folder paths to the .int files here
simDirArray = [
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\000_Baseline\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\001_lowturb\Loads\INT\"
				];

simFolders = [	
				simDirArray(1)
				simDirArray(2)
			 ];	
			
% (Edit) Choose Tmin, Tmax and write the .int file names (intFileNames)
Tmin = 0;		% [s] - Start time of sample extraction
Tmax = 1000;		% [s] - End time of sample extraction

% Current directory:
currentDir = pwd;

% Pull the data from the .int files and store them in .mat file
for ii = 1:length(simFolders)
	% Save current folder and go to a simulation folder
	cd(simFolders(ii));
	% Pull the data from the .int file
	[GenInfo{ii}, Xdata{ii}, Ydata{ii}, ErrorString{ii}] = LAC.timetrace.int.readint...
		(strcat(intFileNames(ii), ".int"), 1, [], Tmin, Tmax);
	
	% Handle no .int files found in folder.
	if length(GenInfo{ii}) == 0
		str = sprintf("Error! No int files found in sim folder #%.0f!", ii);
		disp(str)
	end
end


% Go back to original dir
cd(currentDir);

% Plotting
% ---------------------------------------


% An initialization script which defines a bunch of arrays with sensor
% labels and such:
run C:\repo\mrotr_personal\intFileMatlabAnalysis\sensorSetupInit

% Plotted sensors:
% - Generator speed reference
% - Power reference
% - FLC Pitch position reference
wantedSims = [1 2];
f = myfigplot(100, [senIdx.pnt413 senIdx.pfo017, senIdx.pft105], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, 0, 0);
% For exporting figures:
% figArray = [figArray f]; 
% figNameArray = [figNameArray strcat(setupPrefix, "figurename.png")]; %
wantedSims = [1 2];
f = myfigplot(101, [senIdx.Vhfree], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, 0, 0);
% For exporting figures:
% figArray = [figArray f]; 
% figNameArray = [figNameArray strcat(setupPrefix, "figurename.png")]; %


% Simulation setup
% -----------------
fs = 25;	% Sample frequencye
Ts = 1/fs;	% Sample period
nT = (0:length(Xdata{1})-1) * Ts;	% Time index


% Timetable for data input to simulink
% -----------------

%
vfree = Ydata{1}(:,senIdx.Vhfree);
tt_vfree = timetable(seconds(Xdata{1,1}), vfree);




%% Baseline System w. FLC PI
% =========================================================================

warning off Control:combination:connect9
warning off Control:combination:connect10

SumRef = sumblk('e','wRef','w','+-');

% Full system
sys.full = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["vfree"; "wRef"], ["py"; "vy"; "w"]);
		
% SISO systems
		
sys.th_vy = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["th"], ["vy"]);

sys.wRef_vy = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["wRef"], ["vy"]);
		
sys.wRef_w = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["wRef"], ["w"]);
		
sys.vfree_vy = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["vfree"], ["vy"]);

sys.vfree_W = connect(c.FLC, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, SumRef, ["vfree"], ["W"]);
		
% Check system
sys.evaluation_full = ss_sys_evaluation(sys.full.A, sys.full.B, sys.full.C, ...
	sys.full.D, "Original system w. FLC PI");

% myfig(50);
% pzmap(sys.wRef_vy)
% title('Sys: Pzmap wRef -> vy')

% wRef -> w
f = myfig(51, [0.2 0.25 700 500]);
[mag,phase,wout] = bode(sys.wRef_w);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
xlim([10^(-2) 0.3])
ylim([-20 20])
title('Linear model closed loop bode: wRef -> w')
ylabel('Magnitude [dB]')
grid
xline(0.032), xline(0.04), yline(10.3), yline(-13.4)

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid
xline(0.038), yline(-170)

figArray = [figArray f];
figNameArray = [figNameArray strcat("wtLin_wRef-w_", string(opWindSpeed), "ms", ".png")];

% wRef -> vy
f = myfig(52, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(sys.wRef_vy);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Linear model closed loop bode: wRef -> vy')
xline(0.035)
yline(-16)
xlim([10^(-2) 0.3])
ylim([-60 -10])
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase-360))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid

figArray = [figArray f];
figNameArray = [figNameArray strcat("wtLin_wRef-vy_", string(opWindSpeed), "ms", ".png")];

% vfree -> vy
myfig(53, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(sys.vfree_vy);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Linear model closed loop bode: vfree -> vy')
xlim([10^(-2) 0.3])
ylim([-60 -10])
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase-360))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid


% vfree -> W
myfig(54, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(sys.vfree_W);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Linear model closed loop bode: vfree -> W')
xlim([10^(-2) 0.3])
ylim([-60 -10])
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase-360))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid


% th -> w
f = myfig(55, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(sys.th_vy);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Linear model closed loop bode: theta -> vy')
xlim([10^(-2) 0.3])
ylim([-40 20])
yline(10)
xline(0.034)
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase-(2*360)))
xlim([10^(-2) 0.3])
ylim([-700 -200])
yline(-342.6)
yline(-155-360)
xline(0.03)
xline(0.0377)
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid

figArray = [figArray f];
figNameArray = [figNameArray strcat("wtLin_th-vy_", string(opWindSpeed), "ms", ".png")];


% Step from wRef -> w (No error is present due to integrator in FLC)
myfig(56);
step(sys.wRef_w)



%% Simulation of Original system
% ---------------------------------------
% To be able to run the simulation you need to run the simulation
% preparation section further up in the script. Also i don't think the
% simulation works currently anyway.

Asys = sys.full.A
Bsys = sys.full.B
Csys = sys.full.C % W -> w is the product of rad/s -> rpm and 38.2 gear ratio

Dsys = sys.full.D;	% Is zero


sys.full.StateName{1} = 'FLCint'; % First state must be FLC integrator state
sys.full.StateName
sys.full.InputName
sys.full.OutputName


% Simulation:
% -------------------

% Select which dataset to simulate
simulationData = Ydata{1};

% Generator speed reference is the sum of the constant FLC spd ref and the
% test sine. The test sine has a mean which is removed due to the sine
% being added to the already excisting signal. Also the test sine is in
% Hz but needs to be rpm
% Ydata{1} is the 16 m/s wind speed data set
testSine = (simulationData(:,senIdx.pft229)-mean(simulationData(:,senIdx.pft229))) * 30/pi;
totalGenSpdRef = simulationData(:,senIdx.pnt413) + testSine;

% Inputs
u = [simulationData(:,senIdx.Vhfree)'; totalGenSpdRef'];
% Operating point
u_op = [opWindSpeed; simulationData(1,senIdx.pnt413)];
% In the current setup u_op ends up being: [16 400 8000000]

% States
x = zeros(length(sys.full.StateName),length(Xdata{1}));

% Operating point (these are used in the LQR and LQI sims also)
py_op = 10;
vy_op = 0;
W_op = 10;
x_op_temp_flc = [0 py_op vy_op W_op]';

% Init away from the operating point (these are used in the LQR and LQI sims also)
py_init = 10;
vy_init = 0;
W_init = 0;
x_bar_init_flc = [0 py_init vy_init W_init]';

x_init = x_op_temp_flc + x_bar_init_flc;

x(:,1) = x_init;

% Initialize derivative array
xDot = zeros(length(sys.full.StateName),length(Xdata{1}));
xDot(:,1) = Asys*(x_init-x_op_temp_flc) + Bsys*(u(:,1)-u_op);
for ii = 2:length(Xdata{1})
	
	x(:,ii) = x(:,ii-1) + xDot(:,ii-1) * Ts;
	
	xDot(:,ii) = (Asys*(x(:,ii-1)-x_op_temp_flc) + Bsys*(u(:,ii-1)-u_op));	
end

myfig(500);
plot(nT,x)
title('Sys: Simulation - States')
legend(sys.full.StateName)

myfig(501);
plot(nT,xDot)
title('Sys: Simulation - State derivatives')
legend(sys.full.StateName)

myfig(502);
plot(nT, u)
title('Sys: Simulation - Inputs')
legend(sys.full.InputName)

% Discrete system
sys_d = c2d(sys.full, Ts, 'zoh');

% Extracting system matrices for making LQR controller
% Calculated from xdot = A*x + B*u -> discritize ->
% (x(k+1) - x(k)) / Ts = A*x(k) + B*u(k) ->
% x(k+1) = (A*Ts + 1)x(k) + B*Ts*u(k)
Asys_d = sys_d.A;
Bsys_d = sys_d.B;
Csys_d = sys_d.C; % Not changed in discritization
Dsys_d = sys_d.D; % Not changed in discritization

% Notice that the discrete system can be derived manually as well:
Asys_d2 = (Asys*Ts + eye(length(Asys)));
Bsys_d2 = Bsys*Ts;
Csys_d2 = Csys;
Dsys_d2 = Dsys;


% Check for stability:
if abs(eig(Asys_d)) <= 1
	disp('Discrete system "SysnoFLC2" is stable')
else
	disp('Discrete system "SysnoFLC2" is NOT stable')
end


%% System (LQR)
% =========================================================================
% In this section the FLC controller is replaced with a SS LQR controller.
% There is no integrator
% - In this section the aim is to get a FLC+FATD controller component which
% can be connected with the rest of the system.

% System from output of controller to input of controller:
sys.noFLC = connect(c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["thRef"], ["py"; "vy"; "W"]);

% Evaluate system (stability, controllability, observability)
sys.evaluation_noFLC = ss_sys_evaluation(sys.noFLC.A, sys.noFLC.B, sys.noFLC.C, ...
	sys.noFLC.D, "System No FLC");

% Print out state, input and outputs
disp('States:')
sys.noFLC.StateName
disp('Inputs:')
sys.noFLC.InputName
disp('Outputs:')
sys.noFLC.OutputName


% State weighting matrix

% Using brysons rule to determine Q. 

% V1 tuning parameters:
% var_Omega = (0.1)^2;	% Permitted variance of Omega in [rpm]
% var_py = 1^2;		% Permitted variance of py in [m]
% var_vy = 0.5^2;		% Permitted variance of vy in [m/s]

% V2 tuning parameters:
v_W = 0.25^2; v_py = 3^2; v_vy = 0.5^2; v_Wi = v_W * 10;
var_Omega	= v_W;	% Permitted variance of Omega in [rpm]
var_py		= v_py;	% Permitted variance of py in [m]
var_vy		= v_vy;	% Permitted variance of vy in [m/s]
Qlqr = [1/var_py	0			0
		0			1/var_vy	0
		0			0			1/var_Omega];

% Input weighting

% var_th = 1^2; % V1 tuning parameter
var_th = 5^2; % V2 tuning parameter
R = 1/var_th;


[Klqr, S, P] = lqr(sys.noFLC.A, sys.noFLC.B, Qlqr, R, 0);

% Show K gains
Klqr


% -------------------------
% NOTE:
% B.c. of the dT/dth < 0 then K_1 should be negative to make sense. E.g.
% smaller theta -> omega acceleration

% dF_T/dth < 0 and thus K_2 and K_3 should be positive to decrease F_T!
% bigger theta -> smaller F_T
% --------------------------

% Creating a MISO LQR component. A,B,C = 0.
Alqrcomp = 0;			% Dimensions to fit 
Blqrcomp = zeros(1,3);	% Dimensions to fit 
Clqrcomp = 0;			% Dimensions to fit 
% Notice negative feedback
Dlqrcomp = -Klqr*eye(3,3);

c.FLC_LQR = ss(Alqrcomp, Blqrcomp, Clqrcomp, Dlqrcomp);
c.FLC_LQR.InputName = ["py"; "vy"; "W"];
c.FLC_LQR.OutputName = ["thRef"];

% Combining my LQR controller with the full system without FLC
sysLQR.full_1 = connect(c.FLC_LQR, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, ...
			c.rotWind, c.towSprMassFa, c.drt, ["vfree"],["py"; "vy"; "W"]);

sysLQR.vfree_pyvyW = connect(c.FLC_LQR, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, ...
			c.rotWind, c.towSprMassFa, c.drt, ["vfree"], ["py"; "vy"; "W"]);
			
sysLQR.vfree_vy = connect(c.FLC_LQR, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, ...
			c.aeroThr, c.rotWind, c.towSprMassFa, c.drt, ["vfree"], ["vy"]);
		

% Evaluation of system
sysLQR.evaluation_full_1 = ss_sys_evaluation(sysLQR.full_1.A, sysLQR.full_1.B, ...
			sysLQR.full_1.C, sysLQR.full_1.D, "System LQR full_1");
		

% Plotting
% ----------------------


% % vfree -> vy
% myfig(520, [0.6 0.25 700 500]);
% [mag,phase,wout] = bode(sysLQR.vfree_vy);
% 
% subplot(2,1,1)
% semilogx(rad2hz(wout), mag2db(squeeze(mag)))
% title('Sys w. LQR: Closed Loop Bode (CL vfree2vy)')
% xlim([10^(-2) 0.3])
% ylim([-60 -10])
% ylabel('Magnitude [dB]')
% grid
% 
% subplot(2,1,2)
% semilogx(rad2hz(wout), squeeze(phase))
% xlim([10^(-2) 0.3])
% xlabel('Frequency [Hz]')
% ylabel('Phase [deg]')
% grid
% 
% % Bode full system
% myfig(521);
% bode(sysLQR.full_1)
% title('Sys w. LQR: Closed loop bode of full system')
% 
% % Bode vfree -> py, vy and W
% myfig(522);
% bode(sysLQR.vfree_pyvyW)
% title('Sys w. LQR: Closed loop bode from vfree -> py, vy and W')
% 
% % Step vfree -> py, vy and W
% myfig(523);
% step(sysLQR.vfree_pyvyW)
% title('Sys w. LQR: Step from vfree -> py, vy and W')

%% System: LQI

% Construct a C matrix which only picks out the rotor speed (W)
CintW = [0 0 1];

% Augmented A, B and C matrices
Ai = [sys.noFLC.A		zeros(3,1)
		CintW			0];
Bi = [sys.noFLC.B;		0];
Ci = [sys.noFLC.C		zeros(3,1)];
Di = 0;

% Currently the same weighting of py, vy and W are used with the
% integrator. This might not be the best way to go about it.
var_OmegaInt = v_Wi; % 10 times lower wighting of integrator state
Qlqi = [1/var_py	0			0				0
	0			1/var_vy	0				0
	0			0			1/var_Omega		0
	0			0			0				1/var_OmegaInt];


[Klqi, S, P] = lqr(Ai, Bi, Qlqi, R, 0);

% Print K gains
Klqi


Alqicomp = [0];
Blqicomp = [0 0 1];
Clqicomp = [-Klqi(4)];
Dlqicomp = -Klqi(1:3)*eye(3,3);

% Creating the LQI component
c.SysLQI = ss(Alqicomp, Blqicomp, Clqicomp, Dlqicomp);
c.SysLQI.StateName = ["Omega_i"];
c.SysLQI.InputName = ["py"; "vy"; "W"];
c.SysLQI.OutputName = ["thRef"];


% Full system with LQR controller
SysLQI.full = connect(c.SysLQI, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["vfree"], ...
			["py"; "vy"; "W"]);
		
SysLQI.vfree_pyvyW = connect(c.SysLQI, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["vfree"], ["py"; "vy"; "W"]);

SysLQI.vfree_vy = connect(c.SysLQI, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["vfree"], ["vy"]);
		
SysLQI.vfree_W = connect(c.SysLQI, c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["vfree"], ["W"]);
		

% Evaluation of system
SysLQI.evaluation_full_1 = ss_sys_evaluation(SysLQI.full.A, SysLQI.full.B, SysLQI.full.C, ...
SysLQI.full.D, "System LQI");


% Plotting
% ----------------------


% vfree -> vy
myfig(540, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(SysLQI.vfree_vy);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Bode of linear model with LQI: vfree -> vy)')
xlim([10^(-2) 0.3])
ylim([-60 -10])
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid

% vfree -> W
myfig(541, [0.6 0.25 700 500]);
[mag,phase,wout] = bode(SysLQI.vfree_W);

subplot(2,1,1)
semilogx(rad2hz(wout), mag2db(squeeze(mag)))
title('Bode of linear model with LQI: vfree -> W')
xlim([10^(-2) 0.3])
ylim([-60 -10])
ylabel('Magnitude [dB]')
grid

subplot(2,1,2)
semilogx(rad2hz(wout), squeeze(phase))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
grid

% Bode full system
myfig(542);
bode(SysLQI.full)
title('Bode of linear model with LQI: Full system')

% Bode vfree -> py, vy and W
myfig(543);
bode(SysLQI.vfree_pyvyW)
title('Bode of linear model with LQI: vfree -> py, vy and W')

% Step vfree -> py, vy and W
myfig(544);
step(SysLQI.vfree_pyvyW)
title('Step of linear model with LQI: vfree -> py, vy and W')

%% System: LQR/LQI approach 2
% In this section i make a controller for the system
% in the classical state space way in stead of going for making a
% component.
% - The variables from this section are the ones used in the simulink
% simulation.


SumRef = sumblk('e','wRef','w','+-');
SysnoFLC2 = connect(c.pitUn, c.cnvUn, c.gen, c.aeroFLC, c.aeroThr, c.rotWind, ...
			c.towSprMassFa, c.drt, ["vfree"; "thRef"],["py"; "vy"; "W"])	
		

sys.evaluation_noFLC2_full_1 = ss_sys_evaluation(SysnoFLC2.A, ...
	SysnoFLC2.B, SysnoFLC2.C, SysnoFLC2.D, "System no FLC with sumblk");


% Extracting system matrices for making LQR controller
Alqr = SysnoFLC2.A;
Blqr = SysnoFLC2.B;
Clqr = SysnoFLC2.C;
Dlqr = SysnoFLC2.D;

% Split inputs into input and disturbance matrix
distIndex = 1; % Index of disturbance (vfree)
Bulqr = Blqr(:, distIndex+1:end);
Bdlqr = Blqr(:, distIndex);

% Display names
disp('States:')
SysnoFLC2.StateName
disp('Inputs:')
SysnoFLC2.InputName(distIndex+1:end)
disp('Disturbances:')
SysnoFLC2.InputName(distIndex)
disp('Outputs:')
SysnoFLC2.OutputName


% Calculate LQR gains from A and B matrices
% [K, S, P] = lqr(A, Bu, Q, R, 0);
[Klqr2, S, P] = lqr(Alqr, Bulqr, Qlqr, R, 0);
% Notice! Is the same as "Klqr" of course!


% Closed loop system
Acl_lqr = Alqr-Bulqr*Klqr2;		% Closed loop system

SysLQR2 = ss(Acl_lqr, Bdlqr, Clqr, 0)
SysLQR2.StateName = SysnoFLC2.StateName;
SysLQR2.InputName = SysnoFLC2.InputName(distIndex); % Disturbance
SysLQR2.OutputName = SysnoFLC2.OutputName;

% Evaluate system
eval = ss_sys_evaluation(SysLQR2.A, SysLQR2.B, SysLQR2.C, SysLQR2.D, "System with LQR 2");


% Plotting

myfig(560);
step(SysLQR2)
title('Sys w. LQR V2 full system')

myfig(561);
bode(SysLQR2)
title('Sys w. LQR V2: Bode LQR V2 full system')


% Simulation setup (for simulink) (LQR)

u_op = [simulationData(1,senIdx.Vhfree); simulationData(1,senIdx.pnt413); simulationData(1,senIdx.pfo017)];
% In the current setup u_op ends up being: [16 400 8000000]

% Initial state values
x_op_temp = [py_op vy_op W_op]';

% Initialization away from the operating point
x_bar_init = [py_init vy_init W_init]';


% Including Integrator
% ---------------------

% Augmented system
Alqi = [Alqr		zeros(3,1)
		CintW		0];
Bulqi = [Bulqr; 0];
Bdlqi = [Bdlqr; 0]
Clqi = [Clqr	zeros(3,1)];


% Calculate LQI gains
[Klqi, S, P] = lqr(Alqi, Bulqi, Qlqi, R, 0);


% Closed loop system with integrator:
Acl_lqi = Alqi-Bulqi*Klqi;

% Creating the full closed loop LQR + integrator system
SysLQI2 = ss(Acl_lqi, [Bulqi Bdlqi], Clqi, 0);
tempStateNames = SysnoFLC2.StateName; tempStateNames{4} = 'W_i';
SysLQI2.StateName = tempStateNames;
SysLQI2.InputName = SysnoFLC2.InputName;
SysLQI2.OutputName = SysnoFLC2.OutputName;

% Evaluate system
eval = ss_sys_evaluation(SysLQI2.A, SysLQI2.B, SysLQI2.C, SysLQI2.D, "System with LQI");


% Plotting

myfig(580);
step(SysLQI2)
title('Sys w. LQR V2 full system')

myfig(581);
bode(SysLQI2)
title('Sys w. LQR V2: Bode LQR V2 full system')



% Simulation setup for simulink (LQI)

% Operating point
x_op_temp_lqi =[ py_op vy_op W_op 0]';

% Initialization away from the operating point. Last state is the integrator state
% Expanded with integrator (int)
x_bar_init_lqi = [py_init vy_init W_init 0]';


%% Discritisation of LQI system

SysnoFLC2_d = c2d(SysnoFLC2, Ts ,'zoh')

% Check for stability:
if abs(eig(SysnoFLC2_d)) <= 1
	disp('Discrete system "SysnoFLC2" is stable')
else
	disp('Discrete system "SysnoFLC2" is NOT stable')
end


sysINT_d = c2d(ss(Alqi, [Bdlqi Bulqi], Clqi, 0), Ts, 'tustin');

Alqi_d = sysINT_d.A;
Bdlqi_d = sysINT_d.B(:,distIndex);
Bulqi_d = sysINT_d.B(:,distIndex+1:end);
Clqi_d = sysINT_d.C; % Due to 'tustin' method it's not just eye().. If 'zoh'
					% method is used then it's = Clqi which is eye()

% Deriving discrete system manually:
Alqi_d2 = Alqi*Ts + eye(length(Alqi));
Bdlqi_d2 = Bdlqi*Ts;
Bulqi_d2 = Bulqi*Ts;


% Calculate LQI gains
[Klqi_d, S, P] = dlqr(Alqi_d, Bulqi_d, Qlqi, R, 0);

Klqi_d


%% Calculating the FLC Kp, Ti parameters and the FATD Kpos Kvel gains:

Kpy = Klqi(1);
Kvy = Klqi(2);
Kp = 1/38.2 * 2*pi/60 * Klqi(3);
Ti = Kp/(1/38.2 * 2*pi/60 * Klqi(4));


%% Export figures
% ---------------------------------
figSaveDir = "H:\Offshore_TEMP\USERS\MROTR\wtLinWork";		% Windows type path
% figSaveDir = "H:/Offshore_TEMP/USERS/MROTR/wtLinWork";	% Macos type path
createNewFolder = 1; % Folder name to save figures:
folderName = "figuerExport";
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, folderName, resolution)


%% Save to a .mat file so i can use the data at home:

close all
save("c:\Users\Mrotr\Git\Repos\CA9_Project\Modelling\wtLinScriptData.mat")


%% Functions
% =========================================================================

function ss_sys_evaluation = ss_sys_evaluation(A, B, C, D, sysName)
	% Check important parameters of state space system such as:
	% - Stability (neg/pos eigenvalues)
	% - Controllability
	% - Observability
	
	disp("===============================")
	disp(strcat(sysName, " evaluation:"))
	disp("--------------------")

	% Poles
	ss_sys_evaluation.eig = eig(A);
	if real(eig(A)) <= 0
		disp("System is stable")
	else
		disp("System is NOT stable!!")
	end
	
	% controllability
	ss_sys_evaluation.Co = ctrb(A, B);
	if (length(A) - rank(ss_sys_evaluation.Co)) == 0
		disp("System controllable")
	else
		disp("System is NOT controllable!!")
	end
	
	% Observability
	ss_sys_evaluation.Oo = obsv(A,C);
	if (length(A) - rank(ss_sys_evaluation.Oo)) == 0
		disp("System observable")
	else
		disp("System is NOT observable!!")
	end
end


function out = rad2hz(rad)
	out = rad/(2*pi);
end


function fig = myfig(fignumber, positionIn)
	% Create figure w. white colour and specific position and size.
	% Inputs: fignumber, position
	%	- fignumber: The figure number
	%	- position: Position and size array [x y width height] or [width height]
	%			x and y are in the range 0 -> 1 where 0.5 is in the middle
	% Outputs: figure handler
	
	% Extract screen resolution to define placement of figure
	set(0,'units','pixels');	% Set unit for screen resolution extraction
	screenres = get(0,'screensize'); screenres = screenres([3 4]);
	screenXres = screenres(1); screenYres = screenres(2);


	% Default figure width and height
	defwidth = 700;
	defheight = 500;
	% Default figure x and y position (In middle of screen the the left)
	defxpos = 0;
	defypos = 0.5;
	
	% Defualt position and width/height
	defaultPosition = [defxpos defypos defwidth defheight];

	if nargin == 1
		% No position argument given: Use defualt position
		position = defaultPosition;
	elseif nargin == 2
		sizePosIn = size(positionIn);		% Calculate size of input position

		% If only xlength and ylength are given, then use default position and
		% change size only
		if sizePosIn(2) == 2
			position = [defaultPosition(1:2) positionIn];
		else
			position = positionIn;
		end
	end

	% Define x and y position based on screen resolution
	xpos = position(1) * screenXres-position(3)/2;
	ypos = position(2) * screenYres-position(4)/2;


	% Contain the figure inside the screen if position is beyond borders
	if xpos < 0
		xpos = 0;
	end
	if ypos < 0
		ypos = 0;
	end
	if xpos > (screenXres-position(3))
		xpos = screenXres-position(3);
	end
	if ypos > (screenYres-position(4))
		ypos = (screenYres-position(4));
	end
	
	figPos = [xpos ypos position(3) position(4)];

	if fignumber > 0
		fig = figure(fignumber);
	else
		fig = figure();
	end
	
	fig.Position = figPos; fig.Color = 'white';

end


function f = myfigplot(figNum, wantedPlots, wantedSims, Xdata, sensorData, titles, ylabels, simNames, plottype, xlimits, ylimits)
	% Plot chosen data sets for comparison
	% Inputs: figNum, wantedPlots, wantedSims, Nsims, Xdata, sensorData, titles,
	% ylabels, simNames, plottype, xlimits, ylimits
	% figNum			: The number of the figure
	% wantedPlots		: Ex. [1 2] - Data from sensor 1 and 2
	% wantedSims		: Ex. [1 3] - Data from sim 1 and 3
	% Nsims				: The number of .int files which is used
	% Xdata				: The cell of Xdata (timeseries)
	% sensorData		: The cell of sensor data
	% titles			: An array of the titles relating to the chosen dataseries
	% ylabels			: An array of the y labels relating to the chosen dataseries
	% simNames			: An array of the simNames relating to the .int files
	% plottype			: 1 if timeseries, 0 if fft (sets xlabel)
	% xlimits			: ex. xlimits = [0 1]. if xlimits = 0 then it's not set
	% ylimits			: ex. ylimits = [0 100]. if ylimits = 0 then it's not set
	
	Nplots = length(wantedPlots);
	switch Nplots
		case 1
			figSize = [1 0.25 700 400];
		case 2
			figSize = [1 0.25 700 600];
		case 3
			figSize = [1 0.25 700 800];
		case 4
			figSize = [1 0.25 700 1000];
		case 5
			figSize = [1 0.25 700 1000];
	end
	
	if plottype
		xlabelstr = "Time [s]";
	else
		xlabelstr = "Frequency [Hz]";
	end
	
	f = myfig(figNum, figSize);
	for ii = 1:length(wantedPlots)
		axs(ii) = subplot(length(wantedPlots), 1, ii);

		for nn = wantedSims
			plot(Xdata{nn}, sensorData{nn}(:,wantedPlots(ii)))
			hold on
		end
		hold off
		
		% Set limits if they are specified as an input other than 0
		if length(xlimits) > 1
			xlim(xlimits)
		end
		if length(ylimits) > 1
			ylim(ylimits)
		end

		title(titles(wantedPlots(ii)))
		xlabel(xlabelstr)
		ylabel(ylabels(wantedPlots(ii)))
		legend(simNames(wantedSims))
	end
	linkaxes(axs,'x');
	
end

% For exporting figures
function myfigexport = myfigexport(saveDir, figures, fileNames, createNewFolder, folderName, resolution)
	% Export figures
	% Inputs: saveDir, figures, fileNames, createNewFolder, folderName, resolution
	% saveDir				: directory in '' string
	% figures				: figure array [figure() figure()]
	% fileNames				: file name array ["name1.png" "name2.png"]
	% createNewFolder: 'true' or 'false' - depending on whether you want to
	% folderName			: folder name in '' string
	% resolution			: absolute number.. Default: 400
	
	% Check if windows computer or mac
	if ispc
		% Windows
		dirSplit = '\';
	else
		% Mac
		dirSplit = '/';
	end
	
	% Default resolution
	if nargin == 5
		resolution = 400;
	end
	
	% If "\" or "/" at end of path. Remove it - otherwise an error occurs
	if saveDir(end) == dirSplit
		saveDir(end) == '';
	end

	% Just change savepath to whichever fits you!
	if createNewFolder == 1
		mkdir(saveDir, folderName);							% Create folder
		savePath = strcat(saveDir, dirSplit, folderName);	% Save path for figures
	else
		savePath = saveDir;						% Save path for figures
	end
	
	fileName = fileNames;
	
	for i=1:length(figures)
    	f = strcat(savePath, dirSplit, fileName(i));
    	exportgraphics(figures(i), f,'Resolution', resolution);
	end
end
