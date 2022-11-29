clc;clear;close all;

% Pull data from script
load("wtLinV5data.mat")

% Create system
sysForeaft = connect(c.aeroFLC, c.drt, c.aeroThr, c.rotWind, c.towSprMassFa, ["vfree"], ["vy"])
A = sysForeaft.A
B = sysForeaft.B
C = sysForeaft.C
D = sysForeaft.D


% System and measurement variances and estimations
var_w = 0.02; % measurement uncertainty
var_z = 0.02; % Model/prediction uncertainty
var_w_guess = var_w*1		% Guess of measurement uncertainty
var_z_guess = var_z* 1/4000	% Guess of Model/prediction uncertainty
% Note: guess can deviate from "actual" uncertainty to allow for testing of
% the consequences of not guessing correctly.


% Process error noise covariance matrices
Q = [var_z_guess	0	0
	0	var_z_guess	0
	0	0	var_z_guess];
% Measurement noise covariance matrix
R = var_w_guess;

% Solve discrete-time algebraic Riccati equation
[P,K1] = idare(A',C',Q,R,[],[]);

% Kalman gain version 1
K1 = K1'


P_ss = idare(A',C',Q,R,[],[]); % Steady-state Kalman gain

% Kalman gain version 2
K2 = P_ss*C'*(C*P_ss*C' +R )^(-1)


% Kalman gain version 3
K3 = lqr(A',C',Q,R)

% Closed loop estimator (observer)
L = K1;

Aobs = [A zeros(3,3); L*C A-L*C];
Bobs = [B;B];
Cobs = [C zeros(1,3)];

sysobs = ss(Aobs, Bobs, Cobs, 0)

myfig(-1);
step(sysobs)