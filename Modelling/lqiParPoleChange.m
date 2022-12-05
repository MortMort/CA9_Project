clc;clear;close all;

load('wtLinScriptData.mat', 'Alqi', 'Bulqi', 'Bdlqi', 'Clqi', 'sysNoFLC2', ...
	'distIndex')


% -----------------
% | CHANGE THESE ->
% -----------------
s_W = 1;		% [rpm] - Rotor speed
s_py = 5;		% [m] - Fore-aft position
s_vy = 1;		% [m] - Fore-aft velocity
s_Wi = s_W*5;	% [rpm] Rotor speed integrator state

s_th = 5;		% [deg] - Pitch actuator
% -----------------
% <- CHANGE THESE |
% -----------------

% State weighting
var_Omega		= (s_W * (2*pi)/60)^2;	% Permitted variance of Omega in [rad/s]
var_py			= s_py^2;				% Permitted variance of py in [m]
var_vy			= s_vy^2;				% Permitted variance of vy in [m/s]
var_OmegaInt	= (s_Wi * (2*pi)/60)^2; % rad/s -> rpm weight

% Input weighting
var_th = s_th^2; % V2 tuning parameter
R = 1/var_th;

Qlqi = [1/var_py	0			0				0
	0			1/var_vy	0				0
	0			0			1/var_Omega		0
	0			0			0				1/var_OmegaInt];


% Including Integrator
% --------------------

% Calculate LQI gains
[Klqi, S, P] = lqr(Alqi, Bulqi, Qlqi, R, 0);

% Closed loop system with integrator:
Acl_lqi = Alqi-Bulqi*Klqi;

% Creating the full closed loop LQR + integrator system
sysLQI2 = ss(Acl_lqi, Bdlqi, Clqi, 0);
% Add missing integrator state name:
tempStateNames = sysNoFLC2.StateName; tempStateNames{4} = 'W_i';
sysLQI2.StateName = tempStateNames;
sysLQI2.InputName = sysNoFLC2.InputName(distIndex); % Disturbance
sysLQI2.OutputName = sysNoFLC2.OutputName;



% Plotting
% ---------------------

myfig(1);
pzmap(sysNoFLC2)
hold on
pzmap(sysLQI2)
legend('FLC PI', 'LQI', 'Location','northwest')
