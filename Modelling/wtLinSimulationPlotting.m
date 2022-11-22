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

% TEMPLATE
% title('text', 'FontSize', fontSize.title, 'interpreter','latex')

% Make figure array
figArray = [];
figNameArray = [];

fontSize.leg = 11;
fontSize.legSmall = 9;
fontSize.title = 14;
fontSize.label = 11;



% Pitch reference and pitch reference derivative
f = myfig(1, figSize.two);
subplot(211)
plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
hold on
plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
ylim([-2 5])
title('LQI pitch angle reference', 'FontSize', fontSize.title, 'interpreter','latex')
legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')



subplot(223)
plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
hold on
plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
tstart = 0; tend = 50; % Xlim start for zoom 2
title(sprintf('Zoom T = %.0f:%.0f s',tstart, tend), 'FontSize', 12, 'interpreter','latex')
xlim([tstart tend])
% legend('$\theta$', '$\theta_{deriv}$', 'FontSize', fontSize.leg, 'interpreter','latex')
ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')



subplot(224)
plot(nt, simData.getElement('u_bar_thRef_lqi').Values.Data)
hold on
plot(nt, simData.getElement('u_bar_thRef_deriv_lqi').Values.Data)
tstart = 295; tend = 360; % Xlim start for zoom 2
title(sprintf('Zoom T = %.0f:%.0f s',tstart, tend), 'FontSize', 12, 'interpreter','latex')
xlim([tstart tend])
% legend('$\theta$', '$\theta_{deriv}$', 'location', 'southeast', 'FontSize', fontSize.leg, 'interpreter','latex')
ylabel(["Angle [deg]", "Angle/s [deg/s]"], 'FontSize', fontSize.label, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "01_pitch"];


f = myfig(2, figSize.three);
subplot(311)
plot(nt, simData.getElement('x_bar_sys5_W').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_W_lqi').Values.Data)
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','bottom');
title('Rotor speed', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(312)
plot(nt, simData.getElement('x_bar_sys5_py').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','bottom');
title('Surge direction position', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(313)
plot(nt, simData.getElement('x_bar_sys5_vy').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','bottom');
title('Surge direction velocity', 'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "02_W_py_vy_comp"];


f = myfig(3, figSize.three);
subplot(311)
plot(nt, simData.getElement('x_bar_sys5_W').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_W_lqi').Values.Data)
tstart = 295; tend = 500;
xlim([tstart tend])
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','bottom');
title(sprintf('Rotor speed zoomed at T = %.0f:%.0f',tstart,tend), 'FontSize', ...
				fontSize.title, 'interpreter','latex')
ylabel('Angular velocity [rpm]', 'FontSize', fontSize.label, 'interpreter','latex')
legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(312)
plot(nt, simData.getElement('x_bar_sys5_py').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
xlim([tstart tend])
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','bottom');
title(sprintf('Surge direction position zoomed at T = %.0f:%.0f',tstart,tend), ...
				'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Position [m]', 'FontSize', fontSize.label, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

subplot(313)
plot(nt, simData.getElement('x_bar_sys5_vy').Values.Data)
hold on
plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
xlim([tstart tend])
xline(300, '--', {'vfree', 'step'}, 'interpreter','latex', 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','top');
title(sprintf('Surge direction velocity zoomed at T = %.0f:%.0f',tstart,tend), ...
				'FontSize', fontSize.title, 'interpreter','latex')
ylabel('Velocity [m/s]', 'FontSize', fontSize.label, 'interpreter','latex')
% legend('FLC PI', 'LQI', 'FontSize', fontSize.legSmall, 'interpreter','latex')

figArray = [figArray f];
figNameArray = [figNameArray "03_W_py_vy_comp_zoom"];

% f = myfig(2, figSize.two);
% subplot(211)
% plot(nt, simData.getElement('x_bar_sys5_W').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_sys5_py').Values.Data)
% plot(nt, simData.getElement('x_bar_sys5_vy').Values.Data)
% legend('FLC PI: W', 'FLC PI: py', 'FLC PI: vy')
% 
% subplot(212)
% plot(nt, simData.getElement('x_bar_W_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
% plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
% 
% legend('LQI W', 'LQI py', 'LQI vy')
% 
% figArray = [figArray f];
% figNameArray = [figNameArray "figure2"];

% ZOOM
% f = myfig(3, figSize.two);
% subplot(221)
% plot(nt, simData.getElement('x_bar_sys5_W').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_sys5_py').Values.Data)
% plot(nt, simData.getElement('x_bar_sys5_vy').Values.Data)
% xlim([0 50])
% % ylim([-2 2])
% title('Original FLC PI')
% legend('W', 'py', 'vy', 'location', 'southeast')
% 
% subplot(222)
% plot(nt, simData.getElement('x_bar_sys5_W').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_sys5_py').Values.Data)
% plot(nt, simData.getElement('x_bar_sys5_vy').Values.Data)
% xlim([280 400])
% % ylim([])
% title('Original FLC')
% legend('W', 'py', 'vy', 'location', 'southeast')
% 
% subplot(223)
% plot(nt, simData.getElement('x_bar_W_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
% plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
% xlim([0 50])
% % ylim([])
% title('My LQI')
% legend('W', 'py', 'vy', 'location', 'southeast')
% 
% subplot(224)
% plot(nt, simData.getElement('x_bar_W_lqi').Values.Data)
% hold on
% plot(nt, simData.getElement('x_bar_py_lqi').Values.Data)
% plot(nt, simData.getElement('x_bar_vy_lqi').Values.Data)
% xlim([280 400])
% % ylim([])
% title('My LQI')
% legend('LQI W', 'LQI py', 'LQI vy', 'location', 'southeast')

% figArray = [figArray f];
% figNameArray = [figNameArray "figure2zoom"];



% Setting ylabels and ticks with different ylims and colors:

% % Extract default color codes for figure plots
% defColors = get(groot,'defaultAxesColorOrder');
% defCol.blue = defColors(1,:);
% defCol.red = defColors(2,:);

% yyaxis left 
% ylabel("Angle [deg]", 'Color', defCol.blue, 'FontSize', fontSize.label, 'interpreter','latex')
% set(gca,'YColor',defCol.blue)
% yyaxis right
% set(gca,'YColor',defCol.red)
% ylabel("Angular velocity [deg/s]", 'Color', defCol.red, 'FontSize', fontSize.label, 'interpreter','latex')
% ylim([-2 5])



% Export figures
% ---------------------------------
try
	% Path to folder on windows
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\foreaftFitting"; % Windows type path
catch exception
	% Set path to git folder on mac
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\foreaftFitting"; % Windows type path
end

exportFileType = ".png";
figNameArray = strcat(figNameArray, exportFileType);

% figSaveDir = "H:/Offshore_TEMP/USERS/MROTR/wtLinWork"; % Macos type path
createNewFolder = 0; % Folder name to save figures:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, "nofolder", resolution)