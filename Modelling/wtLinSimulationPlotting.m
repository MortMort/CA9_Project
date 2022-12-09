clear; clc; close all;

load('linearSimData.mat');

% The purpose of this script is to plot data from the simulink simulation
% of the linear wtLin model. The system 5 model with FLC is compared to my
% LQR and LQI controllers.

% List signal names
signalNames = out.logsout.getElementNames

% Time index
nt = out.tout;

% Pull simulation data. Simulation values are extracted with: 
% simData.getElement('signal_name').Values.Data
simData = out.logsout;

% Default figure dimensions and location based on # of plots in subplot:
figSize.one =	[1 0.25 700 300];
figSize.two =	[1 0.25 700 400];
figSize.three = [1 0.25 700 550];
figSize.four =	[1 0.25 700 670];

fontSize.leg = 11;
fontSize.legSmall = 9;
fontSize.title = 12;
fontSize.label = 11;
fontSize.labelSmall = 10;


% Set grid to be ON as default for this matlab session
set(groot,'DefaultAxesXGrid','on')
set(groot,'DefaultAxesYGrid','on')


% TEMPLATE
% title('text', 'FontSize', fontSize.title, 'interpreter','latex')

% Make figure array
figArray = [];
figNameArray = [];


%% =================================================
% vfree step setup
% =================================================
% close all
% 
% % Pitch reference and pitch reference derivative
% f = myfig(1, figSize.two);
% subplot(211)
% plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','top');
% xlim([-1 1000])
% % ylim([-3 10])
% title('LQI pitch angle reference', 'FontSize', fontSize.title, 'interpreter','latex')
% legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
% ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% 
% subplot(223)
% plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
% tstart = -1; tend = 50; % Xlim start for zoom 2
% title(sprintf('Zoom T = %.0f:%.0f s',tstart, tend), 'FontSize', 12, 'interpreter','latex')
% xlim([tstart tend])
% % legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
% ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% 
% subplot(224)
% plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
% tstart = 295; tend = 360; % Xlim start for zoom 2
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','top');
% title(sprintf('Zoom T = %.0f:%.0f s',tstart, tend), 'FontSize', 12, 'interpreter','latex')
% xlim([tstart tend])
% ylim([-1 4])
% % legend('$\theta$', '$\theta_{deriv}$', 'location', 'southeast', 'FontSize', fontSize.leg, 'interpreter','latex')
% ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% 
% figArray = [figArray f];
% figNameArray = [figNameArray "01_pitch"];
% 
% 
% % Rotor speed, py and vy
% f = myfig(2, figSize.three);
% subplot(311)
% plot(nt, simData.getElement('x_bar_W_rad').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_W_lqi_rad').Values.Data)
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','bottom');
% title('Rotor speed', 'FontSize', fontSize.title, 'interpreter','latex')
% ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% 
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% subplot(312)
% plot(nt, simData.getElement('x_bar_py').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','bottom');
% title('Surge direction position', 'FontSize', fontSize.title, 'interpreter','latex')
% ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% % legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% subplot(313)
% plot(nt, simData.getElement('x_bar_vy').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','bottom');
% title('Surge direction velocity', 'FontSize', fontSize.title, 'interpreter','latex')
% ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% % legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% figArray = [figArray f];
% figNameArray = [figNameArray "02_W_py_vy_comp"];
% 
% 
% % Rotor speed, py and vy ZOOM
% f = myfig(3, figSize.three);
% subplot(311)
% plot(nt, simData.getElement('x_bar_W_rad').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_W_lqi_rad').Values.Data)
% tstart = 295; tend = 500;
% xlim([tstart tend])
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','bottom');
% title(sprintf('Rotor speed zoomed at T = %.0f:%.0f',tstart,tend), 'FontSize', ...
% 				fontSize.title, 'interpreter','latex')
% ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% subplot(312)
% plot(nt, simData.getElement('x_bar_py').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
% xlim([tstart tend])
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','bottom');
% title(sprintf('Surge direction position zoomed at T = %.0f:%.0f',tstart,tend), ...
% 				'FontSize', fontSize.title, 'interpreter','latex')
% ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% % legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% subplot(313)
% plot(nt, simData.getElement('x_bar_vy').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
% xlim([tstart tend])
% xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
% 				'horizontal', 'LabelVerticalAlignment','top');
% title(sprintf('Surge direction velocity zoomed at T = %.0f:%.0f',tstart,tend), ...
% 				'FontSize', fontSize.title, 'interpreter','latex')
% ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% % legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')
% 
% figArray = [figArray f];
% figNameArray = [figNameArray "03_W_py_vy_comp_zoom"];



%% =================================================
% VTS vfree data setup
% =================================================
close all

% Pitch reference and pitch reference derivative
f = myfig(10, figSize.two);
subplot(211)
plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
hold on
plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
ylim([-4 7])
title('LQI pitch angle reference', 'FontSize', fontSize.title, 'interpreter','latex')
legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')

subplot(212)
plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
hold on
plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
tstart = 0; tend = 50; % Xlim start for zoom 2
title(sprintf('Zoom T = %.0f:%.0f s',tstart, tend), 'FontSize', 12, 'interpreter','latex')
xlim([tstart-1 tend])
ylim([-4 7])
% legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')
xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "10_pitch"];


% py, vy, W
f = myfig(11, figSize.three);
subplot(311)
plot(nt, simData.getElement('x_bar_W_rad').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_W_lqi_rad').Values.Data)
ylim([-1.5 1.5])
title('Rotor speed', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(312)
plot(nt, simData.getElement('x_bar_py').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
ylim([-7 7])
title('Surge direction position', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(313)
plot(nt, simData.getElement('x_bar_vy').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
ylim([-2 2])
title('Surge direction velocity', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "11_W_py_vy_comp"];


% py, vy, W ZOOM
f = myfig(12, figSize.three);
subplot(311)
plot(nt, simData.getElement('x_bar_W_rad').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_W_lqi_rad').Values.Data)
ylim([-1.5 1.5])
tstart = -1; tend = 100;
xlim([tstart tend])
title(sprintf('Rotor speed zoomed at T = %.0f:%.0f',tstart,tend), 'FontSize', ...
				fontSize.title, 'interpreter','latex')
ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(312)
plot(nt, simData.getElement('x_bar_py').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
ylim([-7 7])
xlim([tstart tend])
title(sprintf('Surge direction position zoomed at T = %.0f:%.0f',tstart,tend), ...
				'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(313)
plot(nt, simData.getElement('x_bar_vy').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
ylim([-2 2])
xlim([tstart tend])
title(sprintf('Surge direction velocity zoomed at T = %.0f:%.0f',tstart,tend), ...
				'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
xlabel("Time [s]", 'FontSize', fontSize.labelSmall, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "12_W_py_vy_comp_zoom"];


%% Export figures
% ---------------------------------
if ispc % <- checks if the script is run on a windows computer
	% Path to folder on windows
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\linearModPerf"; % Windows type path
else % I'm using my mac so use the path from it.
	% Set path to git folder on mac
	figSaveDir = "/Users/martin/Documents/Git/Repos/CA9_Writings/Graphics/TestResults/linearModPerf"; % Windows type path
end

exportFileType = ".png";
figNameArray = strcat(figNameArray, exportFileType);

% figSaveDir = "H:/Offshore_TEMP/USERS/MROTR/wtLinWork"; % Macos type path
createNewFolder = 0; % Folder name to save figures:
resolution = 400;
myfigexport(figSaveDir, figArray, strcat('sim_', figNameArray), createNewFolder, "nofolder", resolution)