clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.


% Pull data from int file
% ---------------------------------
% Step 1: Choose simulation names for the different simulations
simNames = ["Baseline"; 
			"ChangedParam"];

% Step 2: Put the folder paths to the .int files here
simFolders = [	"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\00_SimBaseline\Loads\INT\";
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\001_SimFATDparamChange\Loads\INT\"];


% Step 3: Choose Tmin, Tmax and write the .int file names (intFileNames)
Tmin = 0;		% [s] - Start time of sample extraction
Tmax = 2000;	% [s] - End time of sample extraction

% The names of the .int files
intFileNames = ["1114a001.int";
				"1114a001.int"];

% Pulling data
for ii = 1:length(simFolders)
	scriptFolder = cd(simFolders(ii));
	[GenInfo{ii},Xdata{ii},Ydata{ii},ErrorString{ii}] = LAC.timetrace.int.readint...
	(intFileNames(ii), 1, [], Tmin, Tmax);
	cd(scriptFolder)
	str = strcat("intData", int2str(ii));
	save(str);
end



%% Load and treat data
% ---------------------------------
clc; clear; close all;

% Write the number of simulations which have been stored as .mat files
Nsims = 2;

% Load data
for ii = 1:Nsims
	str = strcat("intData", int2str(ii));
	load(str);
end

% Start a figure cell array to later use for exporting figures
figs = [];

% Create frequency indexes
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
for ii = 1:Nsims
	L{ii} = length(Xdata{ii});	% Number of samples
	nf{ii} = Fs.*(0:(L{ii}/2))/L{ii};	% Frequency index
end


% The below vector contains the IDs of the sensors which are of interest.
% If the # of sensors prepped for simulation is changed then these IDs maybe will
% change as well

% Sensor output V1 (2500+ sensors):
% sensorIDs = [1,		2,		8,		11,		14,		17,		18,		22,		478:495];
%           Vfree	Vhub	Pi1		Pi2		Pi3		PSI		Omega	GenMom
% Sensors 478 -> 495 are the xKF -> OMPzKF sensors

% Sensor output V2 (~150 sensors)
sensorIDs = [1,		3,		7,		10,		13,		16,		17,		21,		109:126];
%           Vfree	Vhub	Pi1		Pi2		Pi3		PSI		Omega	GenMom
% Sensors 109 -> 126 are the xKF -> OMPzKF sensors


% Sensor names. Used for legends when plotting
legs = ["Vfree", "Vhub", "Pi1", "Pi2", "Pi3", "PSI", "Omega", "GenMom", "xKF", ...
	"yKF", "zKF", "AlxKF", "AlyKF", "AlzKF", "UxKF", "UyKF", "UzKF","OMxKF", ...
	"OMyKF", "OMzKF", "AxKF", "AyKF", "AzKF","OMPxKF", "OMPyKF", "OMPzKF"];

% Title names. Used for titles when plotting
titles = ["Free wind speed", "Hub wind speed", "Blade pitch angle 1", "Blade pitch angle 2", ...
	"Blade pitch angle 3", "PSI", "Rotor angular velocity", "Generator torque", ...
	"x-axis translation position", "y-axis translation position", "z-axis translation position", ...
	"Tower Pitch angle", "Tower Roll angle", "Tower Yaw angle??? Or?", ...
	"x-axis translational velocity", "y-axis translational velocity", "z-axis translational velocity", ...
	"Tower Pitch speed", "Tower Roll speed", "Tower Yaw speed??? Or?", ...
	"AxKF", "AyKF", "AzKF", ...
	"OMPxKF", "OMPyKF", "OMPzKF"];

% ylabels. Used for ylabels when plotting
ylabels = ["Velocity [m/s]", "Velocity [m/s]", "Angle [deg]", "Angle [deg]", "Angle [deg]", ...
			"PSI??", "Angular Velocity [m/s]", "Torque [Nm]", "Position [m]", "Position [m]", "Position [m]", ...
			"Angle [rad]", "Angle [rad]", "Angle [rad]", ...
			"Velocity [m/s]", "Velocity [m/s]", "Velocity [m/s]", ...
			"Angular Velocity [m/s]", "Angular Velocity [m/s]", "Angular Velocity [m/s]", ...
			"AxKF", "AyKF", "AzKF", ...
			"OMPxKF", "OMPyKF", "OMPzKF"];

% Data of sensors of interest
for ii = 1:Nsims
	sensorData{ii} = Ydata{ii}(:,sensorIDs);
end

% Create ffts
for nn = 1:Nsims
	for ii = 1:length(titles)
		Y = abs(fft(sensorData{nn}(:,ii)))/L{nn};
		sensorDataFFT{nn}(:,ii) = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
	end
end


%% Compare Plotting

% Start a figure cell array to later use for exporting figures
figs = [];

f = myfigplot(100, [1 3 7 8], Nsims, Xdata, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

f = myfigplot(101, [9 10], Nsims, Xdata, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

f = myfigplot(102, [12 13], Nsims, Xdata, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

f = myfigplot(103, [15 16], Nsims, Xdata, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

f = myfigplot(104, [18 19], Nsims, Xdata, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

% Plotting FFTs
f = myfigplot(200, [1], Nsims, nf, sensorDataFFT, titles, ylabels, simNames, 0);
figs = [figs f];


% blade pitch fft
Y = abs(fft(sensorData{1}(:,3)))/L{1};
Y = Y(1:((end+1)/2)); % OnL{1}y one half of fft (up to nyquist frequency)
f = myfig(20, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 2])
title('FFT of Blade 1 pitch')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(3))
figs = [figs, f];

f = myfigplot(200, [1 2], Nsims, nf, sensorData, titles, ylabels, simNames, 1);
figs = [figs f];

%% Plotting (of the first .int file data sensorData{1}!
% ---------------------------------
% Settings for myfig() functoin: Position and size of figure
defFigSize = [1 0.25 700 400];
defTwoSubFigSize = [1 0.25 700 600];
defThreeSubFigSize = [1 0.25 700 800];
defFourSubFigSize = [1 0.25 700 1000];


close all

% Free wind and hub wind
f = myfig(1, defFourSubFigSize);
ax1 = subplot(411);
plot(Xdata{1}, sensorData{1}(:,1:2))
title('Free wind and hub wind')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(legs(1:2))
% Blade pitches
ax2 = subplot(412);
plot(Xdata{1} , sensorData{1}(:,3:5))
title('Blade 1-3 pitch angles')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3:5))
% Rotor speed
ax3 = subplot(413);
plot(Xdata{1} , sensorData{1}(:,7))
title('Rotor speed')
xlabel('Time [s]')
ylabel('Rotational Velocity [rad/s]')
legend(legs(7))
% Generator Torque
ax4 = subplot(414);
plot(Xdata{1} , sensorData{1}(:,8))
title('Generator Torque')
xlabel('Time [s]')
ylabel('Torque [Nm]')
legend(legs(8))

figs = [figs, f];
% Lock x-axis for zooming collectively
linkaxes([ax1,ax2,ax3,ax4],'x');


% xKF, yKf
% f = myfig(2, defFigSize);
% plot(Xdata{1}, sensorData{1}(:,9:10))
% title('x-direction translation (vestas coordinates)')
% xlabel('Time [s]')
% ylabel('Translation [m]')
% legend(legs(9:10))
% figs = [figs, f];


% zKf (z-direction translation)
% f = myfig(3, defFigSize);
% plot(Xdata{1}, sensorData{1}(:,11))
% title('z-direction translation (vestas coordinates)')
% xlabel('Time [s]')
% ylabel('Translation [m]')
% legend(legs(11))
% figs = [figs, f];


% xKF, yKf (x and y translation) and blade pitch
f = myfig(4, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata{1}, sensorData{1}(:,9:10))
title('x and y direction translation (vestas coordinates)')
xlabel('Time [s]')
ylabel('Translation [m]')
legend(legs(9:10))
ax2 = subplot(212);
plot(Xdata{1} , sensorData{1}(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% AlxKF & AlyKF (Pitch and roll angles)
% rad -> deg
AlxKFinDeg = sensorData{1}(:,12) .* 180/pi;
AlyKFinDeg = sensorData{1}(:,13) .* 180/pi;

f = myfig(5, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata{1}, AlxKFinDeg); hold on; plot(Xdata{1}, AlyKFinDeg); hold off;
title('Tower Pitch and roll')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(12:13))
ax2 = subplot(212);
plot(Xdata{1} , sensorData{1}(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% UxKF & UyKF (translation speeds) and Pi1 (Blade pitch)
f = myfig(6, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata{1}, sensorData{1}(:,15:16))
title('x and y translation velocity')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(legs(15:16))
ax2 = subplot(212);
plot(Xdata{1} , sensorData{1}(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% OMxKF & OMyKF (Pitch and roll angular velocity) and Pi1 (Blade pitch)
OMxKFinDeg = sensorData{1}(:,18) .* 180/pi;
OMyKFinDeg = sensorData{1}(:,19) .* 180/pi;

f = myfig(6, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata{1}, OMxKFinDeg); hold on; plot(Xdata{1}, OMyKFinDeg); hold off;
title('Pitch and roll angular velocity')
xlabel('Time [s]')
ylabel('Velocity [rad/s]')
legend(legs(18:19))
ax2 = subplot(212);
plot(Xdata{1} , sensorData{1}(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];

%% Plotting FFTs (of the first .int file data sensorData{1}!
% ---------------------------------

% blade pitch fft
Y = abs(fft(sensorData{1}(:,3)))/L{1};
Y = Y(1:((end+1)/2)); % OnL{1}y one half of fft (up to nyquist frequency)
f = myfig(20, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 2])
title('FFT of Blade 1 pitch')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(3))
figs = [figs, f];

% xKF fft
Y = abs(fft(sensorData{1}(:,9)))/L{1};
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(21, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 0.3])
title('FFT of x-direction translation (vestas coordinates)')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(9))
figs = [figs, f];


% yKF fft
Y = abs(fft(sensorData{1}(:,10)))/L{1};
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(22, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 4])
title('FFT of y-direction translation (vestas coordinates)')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(10))
figs = [figs, f];


% AlxKF (Pitch) fft
Y = abs(fft(sensorData{1}(:,12)))/L{1};
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(23, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 0.05])
title('FFT of tower pitch angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(12))
figs = [figs, f];


% AlyKF (Roll) fft
Y = abs(fft(sensorData{1}(:,13)))/L{1};
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(24, defFigSize);
plot(nf{1}, Y)
xlim([0 1])
ylim([0 0.05])
title('FFT of tower roll angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(13))
figs = [figs, f];


% AlxKF (Pitch) and ALyKF (Roll) fft
Y1 = abs(fft(sensorData{1}(:,12)))/L{1};
Y1 = Y1(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
Y2 = abs(fft(sensorData{1}(:,13)))/L{1};
Y2 = Y2(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)

f = myfig(25, defFigSize);
plot(nf{1}, Y1); hold on; plot(nf{1}, Y2); hold off
xlim([0 1])
ylim([0 0.05])
title('FFT of tower pitch and roll angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(12:13))
figs = [figs, f];


% OMxKF (Pitch) and OMyKF (Roll) velocity fft
Y1 = abs(fft(sensorData{1}(:,15)))/L{1};
Y1 = Y1(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
Y2 = abs(fft(sensorData{1}(:,16)))/L{1};
Y2 = Y2(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)

f = myfig(26, defFigSize);
plot(nf{1}, Y1); hold on; plot(nf{1}, Y2); hold off
xlim([0 1])
ylim([0 1])
title('FFT of tower pitch and roll angle velocity')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(15:16))
figs = [figs, f];

%% Plotting two int file comparisons THIS PART IS NOT DONE
% ---------------------------------


% Settings for myfig() functoin: Position and size of figure
defFigSize = [1 0.25 700 400];
defTwoSubFigSize = [1 0.25 700 600];
defThreeSubFigSize = [1 0.25 700 800];
defFourSubFigSize = [1 0.25 700 1000];

% Free wind and hub wind
f = myfig(1, defFourSubFigSize);
ax1 = subplot(411);
for ii = 1:Nsims
	plot(Xdata{ii}, sensorData{ii}(:,1))
	hold on
end
hold off
title('Free wind')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(simNames)
% Blade pitches
ax2 = subplot(412);
for ii = 1:Nsims
	plot(Xdata{ii}, sensorData{ii}(:,3))
	hold on
end
title('Blade 1-3 pitch angles')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(simNames)
% Rotor speed
ax3 = subplot(413);
for ii = 1:Nsims
	plot(Xdata{ii}, sensorData{ii}(:,7))
	hold on
end
title('Rotor speed')
xlabel('Time [s]')
ylabel('Rotational Velocity [rad/s]')
legend(simNames)
% Generator Torque
ax4 = subplot(414);
for ii = 1:Nsims
	plot(Xdata{ii}, sensorData{ii}(:,8))
	hold on
end
title('Generator Torque')
xlabel('Time [s]')
ylabel('Torque [Nm]')
legend(simNames)

figs = [figs, f];
% Lock x-axis for zooming collectively
linkaxes([ax1,ax2,ax3,ax4],'x');
%%
% Settings for myfig() functoin: Position and size of figure
defFigSize = [1 0.25 700 400];
defTwoSubFigSize = [1 0.25 700 600];
defThreeSubFigSize = [1 0.25 700 800];
defFourSubFigSize = [1 0.25 700 1000];

figNum = 1;
wantedPlots = [1 2 3];
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
f = myfig(figNum, figSize);
for ii = 1:length(wantedPlots)
	axs(ii) = subplot(length(wantedPlots), 1, ii);
	
	for nn = 1:Nsims
		plot(Xdata{nn}, sensorData{nn}(:,wantedPlots(ii)))
		hold on
	end
	hold off
	title(titles(wantedPlots(ii)))
	xlabel('Time [s]')
	ylabel(ylabels(wantedPlots(ii)))
	legend(simNames)
end
linkaxes(axs,'x');
figs = [figs, f];


f = myfigplot(1, [1 2], Nsims, Xdata, sensorData, titles, ylabels, simNames);


%%
% xKF, yKf (x and y translation) and blade pitch
f = myfig(4, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata{1}, sensorData{1}(:,9:10))
title('x and y direction translation (vestas coordinates)')
xlabel('Time [s]')
ylabel('Translation [m]')
legend(legs(9:10))
ax2 = subplot(212);
plot(Xdata{1} , sensorData{1}(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


%% Plotting correleations
% % ---------------------------------
% % Removing means
% sensorDataNomean = zeros(length(Ydata), length(sensorData));
% for ii = 1:length(sensorData(1,:))
% 	sensorDataNomean(:,ii) = sensorData(:,ii) - mean(sensorData(:,ii));
% end
% 
% f = myfig(40);
% plot(xcorr(sensorDataNomean(:,9), sensorDataNomean(:,3)))
% xlim([0 2*length(Xdata)])% ylim([ ])
% title('Correleation between xKF and Pitch angle')
% % xlabel('')
% % ylabel('f')
% % legend()
% figs = [figs, f];
% 
% f = myfig(41);
% plot(xcorr(sensorDataNomean(:,10), sensorDataNomean(:,3)))
% xlim([0 2*length(Xdata)])% ylim([ ])
% title('Correleation between yKF and Pitch angle')
% % xlabel('')
% % ylabel('f')
% % legend()
% figs = [figs, f];
% 
% % The covariances
% covx = cov(xFK_nomean, Pi1_nomean)
% covy = cov(yFK_nomean, Pi1_nomean)
% 
% 
% %% Templates
% % f = myfig(xx, defFigSize);
% % plot(, )
% % xlim([ ])
% % ylim([ ])
% % title('')
% % xlabel('')
% % ylabel('f')
% % legend()
% % figs = [figs, f];
% 
% 
% 
%% Functions

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


function myfigexport = myfigexport(saveDir, figures, fileNames, createNewFolder, folderName, resolution)
	% Export figures
	% Inputs: saveDir, figures, fileNames, createNewFolder, folderName, resolution
	% saveDir				: directory in '' string
	% figures				: figure array [figure() figure()]
	% fileNames				: file name array ["name1.png" "name2.png"]
	% createNewFolder: 'true' or 'false' - depending on whether you want to
	% folderName			: folder name in '' string
	% resolution			: absolute number.. Default: 300
	
	% Default resolution
	if nargin == 5
		resolution = 300;
	end

	% Just change savepath to whichever fits you!
	if createNewFolder == 'true'
		mkdir(saveDir, folderName);				% Create folder
		savePath = [saveDir '/' folderName];	% Save path for figures
	else
		savePath = saveDir;						% Save path for figures
	end
	
	fileName = fileNames;
	
	for i=1:length(figures)
    	f = fullfile(savePath, append(fileName(i)));
    	exportgraphics(figures(i), f,'Resolution', resolution);
	end

	
end


function f = myfigplot(figNum, wantedPlots, Nsims, Xdata, sensorData, titles, ylabels, simNames, plottype)
	% Plot chosen data sets for comparison
	% Inputs: figNum, wantedPlots, Nsims, Xdata, sensorData, titles,
	% ylabels, simNames, plottype
	% figNum			: The number of the figure
	% wantedPlots		: Ex. [1 2] - plot dataseries 1 and 2 for compare
	% Nsims				: The number of .int files which is used
	% Xdata				: The cell of Xdata (timeseries)
	% sensorData		: The cell of sensor data
	% titles			: An array of the titles relating to the chosen dataseries
	% ylabels			: An array of the y labels relating to the chosen dataseries
	% simNames			: An array of the simNames relating to the .int files
	% plottype			: 1 if timeseries, 0 if fft (sets xlabel)
	
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

		for nn = 1:Nsims
			plot(Xdata{nn}, sensorData{nn}(:,wantedPlots(ii)))
			hold on
		end
		hold off
		title(titles(wantedPlots(ii)))
		xlabel(xlabelstr)
		ylabel(ylabels(wantedPlots(ii)))
		legend(simNames)
	end
	linkaxes(axs,'x');
	
end