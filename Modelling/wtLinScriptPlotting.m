clc;clear;close all;

% The purpose of this script is to make comparative plots of the linear
% model with FLC vs. my LQI controller.

load('wtLinScriptData.mat', 'sys', 'sysLQI')


% Default figure dimensions and location based on # of plots in subplot:
figSize.one =	[1 0.25 700 300];
figSize.two =	[1 0.25 700 400];
figSize.three = [1 0.25 700 550];
figSize.four =	[1 0.25 700 670];

fontSize.leg = 11;
fontSize.legSmall = 9;
fontSize.title = 13;
fontSize.label = 11;

% set(groot,'DefaultAxesXGrid','on')
% set(groot,'DefaultAxesYGrid','on')

% Make figure array
figArray = [];
figNameArray = [];



% vfree -> vy
f = myfig(1, figSize.two);
subplot(2,1,1)
[mag, ~, wout] = bode(sys.vfree_vy);
semilogx((wout * 1/(2*pi)), mag2db(squeeze(mag)))
hold on
[mag, ~, wout] = bode(sysLQI.vfree_vy);
semilogx((wout * 1/(2*pi)), mag2db(squeeze(mag)))
title('Linear model closed loop bode from disturbance $v_{free}$ to outupt $v_y$', ...
	'FontSize', fontSize.title, 'interpreter','latex')
xlim([10^(-2) 0.3])
% ylim([-60 -10])
ylabel('Magnitude [dB]', 'FontSize', fontSize.label, 'interpreter','latex')
grid on
legend(["FLC PI", "LQI"], 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(2,1,2)
[~, phase, wout] = bode(sys.vfree_vy);
semilogx((wout * 1/(2*pi)), squeeze(phase-360))
hold on
[~, phase,wout] = bode(sysLQI.vfree_vy);
semilogx((wout * 1/(2*pi)), squeeze(phase-360))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]', 'FontSize', fontSize.label, 'interpreter','latex')
ylabel('Phase [deg]', 'FontSize', fontSize.label, 'interpreter','latex')
grid on

figArray = [figArray f];
figNameArray = [figNameArray "script_vfreeTovy"];


% vfree -> vy
f = myfig(2, figSize.two);
subplot(2,1,1)
[mag, ~, wout] = bode(sys.vfree_W);
semilogx((wout * 1/(2*pi)), mag2db(squeeze(mag)))
hold on
[mag, ~, wout] = bode(sysLQI.vfree_W);
semilogx((wout * 1/(2*pi)), mag2db(squeeze(mag)))
title('Linear model closed loop bode from disturbance $v_{free}$ to output $\Omega$', ...
	'FontSize', fontSize.title, 'interpreter','latex')
xlim([10^(-2) 0.3])
% ylim([-60 -10])
ylabel('Magnitude [dB]', 'FontSize', fontSize.label, 'interpreter','latex')
grid on
legend(["FLC PI", "LQI"], 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(2,1,2)
[~, phase, wout] = bode(sys.vfree_W);
semilogx((wout * 1/(2*pi)), squeeze(phase-360))
hold on
[~, phase,wout] = bode(sysLQI.vfree_W);
semilogx((wout * 1/(2*pi)), squeeze(phase-360))
xlim([10^(-2) 0.3])
xlabel('Frequency [Hz]', 'FontSize', fontSize.label, 'interpreter','latex')
ylabel('Phase [deg]', 'FontSize', fontSize.label, 'interpreter','latex')
grid on

figArray = [figArray f];
figNameArray = [figNameArray "script_vfreeToW"];



% Export figures
% ---------------------------------
try
	% Path to folder on windows
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\linearModPerf"; % Windows type path
catch exception
	% Set path to git folder on mac
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\linearModPerf"; % Windows type path
end

exportFileType = ".png";
figNameArray = strcat(figNameArray, exportFileType);

% figSaveDir = "H:/Offshore_TEMP/USERS/MROTR/wtLinWork"; % Macos type path
createNewFolder = 0; % Folder name to save figures:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, "nofolder", resolution)