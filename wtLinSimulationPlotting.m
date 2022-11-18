clc; close all;

% The purpose of this script is to plot data from the simulink simulation
% of the linear wtLin model. The system 5 model with FLC is compared to my
% LQR and LQI controllers.

% List signal names
signalNames = out.logsout.getElementNames

% Time index
nt = log.tout;

% Pull simulation data. Simulation values are extracted with: 
% simData.getElement('signal_name').Values.Data
simData = out.logsout;

% Default figure dimensions and location based on # of plots in subplot:
figSize.one =	[1 0.25 700 400];
figSize.two =	[1 0.25 700 600];
figSize.three = [1 0.25 700 800];
figSize.four =	[1 0.25 700 1000];


% Plot 