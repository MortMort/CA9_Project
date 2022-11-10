clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.


% Pull data from int file
% ---------------------------------
% Step 1: Set folder path to .int file
sim1Name = "Baseline";
sim2Name = "NoForeaftCtrlGain";
simFolder1 = "h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\00_SimBaseline\Loads\INT\";
simFolder2 = "h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\001_SimFATDparamChange\Loads\INT\";

% Step 2: Choose Tmin, Tmax and write the .int file name (intFileName)
Tmin = 0;   % [s] - Start time of sample extraction
Tmax = 2000;   % [s] - End time of sample extraction
intFileName1 = "1114a001.int";
intFileName2 = "1114a001.int";

% Data 1:

% Save current folder and go to simulation folder
scriptFolder = cd(simFolder1);

% Pull data from int file
[GenInfo1,Xdata1,Ydata1,ErrorString1] = LAC.timetrace.int.readint...
(intFileName1, 1, [], Tmin, Tmax);

% Save data in .mat file so it doesn't have to be extracted every time this
% script is run
cd(scriptFolder)
save('intData1.mat')


% Data 2:

% Save current folder and go to simulation folder
scriptFolder = cd(simFolder2);

% Pull data from int file
[GenInfo2,Xdata2,Ydata2,ErrorString2] = LAC.timetrace.int.readint...
(intFileName2, 1, [], Tmin, Tmax);

% Save data in .mat file so it doesn't have to be extracted every time this
% script is run
cd(scriptFolder)
save('intData2.mat')



%% Load and treat data
% ---------------------------------
clc; clear; close all;

% Load data
load('intData1.mat')
load('intData2.mat')
% Start a figure cell array to later use for exporting figures
figs = [];

% Create frequency indexes
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
L = length(Xdata1);		% Number of samples
nf = Fs*(0:(L/2))/L;	% Frequency index

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
% Sensors 478 -> 495 are the xKF -> OMPzKF sensors



% Sensor names. Used for legends when plotting
legs = ["Vfree", "Vhub", "Pi1", "Pi2", "Pi3", "PSI", "Omega", "GenMom", "xKF", ...
	"yKF", "zKF", "AlxKF", "AlyKF", "AlzKF", "UxKF", "UyKF", "UzKF","OMxKF", ...
	"OMyKF", "OMzKF", "AxKF", "AyKF", "AzKF","OMPxKF", "OMPyKF", "OMPzKF"];

% Data of sensors of interest
sensorData1 = Ydata1(:,sensorIDs);
sensorData2 = Ydata2(:,sensorIDs);

sensorData{1} = sensorData1; sensorData{2} = sensorData2;
Xdata{1} = Xdata1; Xdata{2} = Xdata;

%% Plotting
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
plot(Xdata, sensorData(:,1:2))
title('Free wind and hub wind')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(legs(1:2))
% Blade pitches
ax2 = subplot(412);
plot(Xdata , sensorData(:,3:5))
title('Blade 1-3 pitch angles')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3:5))
% Rotor speed
ax3 = subplot(413);
plot(Xdata , sensorData(:,7))
title('Rotor speed')
xlabel('Time [s]')
ylabel('Rotational Velocity [rad/s]')
legend(legs(7))
% Generator Torque
ax4 = subplot(414);
plot(Xdata , sensorData(:,8))
title('Generator Torque')
xlabel('Time [s]')
ylabel('Torque [Nm]')
legend(legs(8))

figs = [figs, f];
% Lock x-axis for zooming collectively
linkaxes([ax1,ax2,ax3,ax4],'x');


% xKF, yKf
% f = myfig(2, defFigSize);
% plot(Xdata, sensorData(:,9:10))
% title('x-direction translation (vestas coordinates)')
% xlabel('Time [s]')
% ylabel('Translation [m]')
% legend(legs(9:10))
% figs = [figs, f];


% zKf (z-direction translation)
% f = myfig(3, defFigSize);
% plot(Xdata, sensorData(:,11))
% title('z-direction translation (vestas coordinates)')
% xlabel('Time [s]')
% ylabel('Translation [m]')
% legend(legs(11))
% figs = [figs, f];


% xKF, yKf (x and y translation) and blade pitch
f = myfig(4, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata, sensorData(:,9:10))
title('x and y direction translation (vestas coordinates)')
xlabel('Time [s]')
ylabel('Translation [m]')
legend(legs(9:10))
ax2 = subplot(212);
plot(Xdata , sensorData(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% AlxKF & AlyKF (Pitch and roll angles)
% rad -> deg
AlxKFinDeg = sensorData(:,12) .* 180/pi;
AlyKFinDeg = sensorData(:,13) .* 180/pi;

f = myfig(5, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata, AlxKFinDeg); hold on; plot(Xdata, AlyKFinDeg); hold off;
title('Tower Pitch and roll')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(12:13))
ax2 = subplot(212);
plot(Xdata , sensorData(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% UxKF & UyKF (translation speeds) and Pi1 (Blade pitch)
f = myfig(6, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata, sensorData(:,15:16))
title('x and y translation velocity')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(legs(15:16))
ax2 = subplot(212);
plot(Xdata , sensorData(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];


% OMxKF & OMyKF (Pitch and roll angular velocity) and Pi1 (Blade pitch)
OMxKFinDeg = sensorData(:,18) .* 180/pi;
OMyKFinDeg = sensorData(:,19) .* 180/pi;

f = myfig(6, defTwoSubFigSize);
ax1 = subplot(211);
plot(Xdata, OMxKFinDeg); hold on; plot(Xdata, OMyKFinDeg); hold off;
title('Pitch and roll angular velocity')
xlabel('Time [s]')
ylabel('Velocity [rad/s]')
legend(legs(18:19))
ax2 = subplot(212);
plot(Xdata , sensorData(:,3))
title('Blade pitch angle')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(legs(3))

linkaxes([ax1,ax2],'x');
figs = [figs, f];

%% Plotting FFTs
% ---------------------------------

% blade pitch fft
Y = abs(fft(sensorData(:,3)))/L;
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(20, defFigSize);
plot(nf, Y)
xlim([0 1])
ylim([0 2])
title('FFT of Blade 1 pitch')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(3))
figs = [figs, f];

% xKF fft
Y = abs(fft(sensorData(:,9)))/L;
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(21, defFigSize);
plot(nf, Y)
xlim([0 1])
ylim([0 0.3])
title('FFT of x-direction translation (vestas coordinates)')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(9))
figs = [figs, f];


% yKF fft
Y = abs(fft(sensorData(:,10)))/L;
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(22, defFigSize);
plot(nf, Y)
xlim([0 1])
ylim([0 4])
title('FFT of y-direction translation (vestas coordinates)')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(10))
figs = [figs, f];


% AlxKF (Pitch) fft
Y = abs(fft(sensorData(:,12)))/L;
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(23, defFigSize);
plot(nf, Y)
xlim([0 1])
ylim([0 0.05])
title('FFT of tower pitch angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(12))
figs = [figs, f];


% AlyKF (Roll) fft
Y = abs(fft(sensorData(:,13)))/L;
Y = Y(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
f = myfig(24, defFigSize);
plot(nf, Y)
xlim([0 1])
ylim([0 0.05])
title('FFT of tower roll angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(13))
figs = [figs, f];


% AlxKF (Pitch) and ALyKF (Roll) fft
Y1 = abs(fft(sensorData(:,12)))/L;
Y1 = Y1(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
Y2 = abs(fft(sensorData(:,13)))/L;
Y2 = Y2(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)

f = myfig(25, defFigSize);
plot(nf, Y1); hold on; plot(nf, Y2); hold off
xlim([0 1])
ylim([0 0.05])
title('FFT of tower pitch and roll angle')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(12:13))
figs = [figs, f];


% OMxKF (Pitch) and OMyKF (Roll) velocity fft
Y1 = abs(fft(sensorData(:,15)))/L;
Y1 = Y1(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)
Y2 = abs(fft(sensorData(:,16)))/L;
Y2 = Y2(1:((end+1)/2)); % Only one half of fft (up to nyquist frequency)

f = myfig(26, defFigSize);
plot(nf, Y1); hold on; plot(nf, Y2); hold off
xlim([0 1])
ylim([0 1])
title('FFT of tower pitch and roll angle velocity')
xlabel('Frequency (Hz)')
ylabel('Magnitude')
legend(legs(15:16))
figs = [figs, f];

%% Plotting two int file comparisons
% ---------------------------------

% Settings for myfig() functoin: Position and size of figure
defFigSize = [1 0.25 700 400];
defTwoSubFigSize = [1 0.25 700 600];
defThreeSubFigSize = [1 0.25 700 800];
defFourSubFigSize = [1 0.25 700 1000];

% Free wind and hub wind
f = myfig(1, defFourSubFigSize);
ax1 = subplot(411);
plot(Xdata1, sensorData1(:,1)); hold on; plot(Xdata1, sensorData2(:,1))
hold off
title('Free wind')
xlabel('Time [s]')
ylabel('Velocity [m/s]')
legend(sim1Name, sim2Name)
% Blade pitches
ax2 = subplot(412);
plot(Xdata1, sensorData1(:,3)); hold on; plot(Xdata1, sensorData2(:,3))
hold off
title('Blade 1-3 pitch angles')
xlabel('Time [s]')
ylabel('Angle [deg]')
legend(sim1Name, sim2Name)
% Rotor speed
ax3 = subplot(413);
plot(Xdata1, sensorData1(:,7)); hold on; plot(Xdata1, sensorData2(:,7))
hold off
title('Rotor speed')
xlabel('Time [s]')
ylabel('Rotational Velocity [rad/s]')
legend(sim1Name, sim2Name)
% Generator Torque
ax4 = subplot(414);
plot(Xdata1, sensorData1(:,8)); hold on; plot(Xdata1, sensorData2(:,8))
hold off
title('Generator Torque')
xlabel('Time [s]')
ylabel('Torque [Nm]')
legend(sim1Name, sim2Name)

figs = [figs, f];
% Lock x-axis for zooming collectively
linkaxes([ax1,ax2,ax3,ax4],'x');


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
