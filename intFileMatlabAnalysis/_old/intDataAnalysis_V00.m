clc; clear; close all;
% This script is initially made to pull and later analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every data pull. One can start from "Work with data" and down.

% The matlab "Current Folder" has to be the Loads\INT folder when
% extracting data

% Settings for myfig() functoin: Position and size of figure
defFigSize = [1 0.25 700 300];
defTwoSubFigSize = [1 0.25 700 500];
defTripleSubFigSize = [1 0.25 700 700];

% Pull data from int file
% ---------------------------------
% Step 1: What is the name of the simulation folder:
simFolderName = "001_InitialSimulation2";
% Make folderpath
simFolder = strcat("H:\Offshore_TEMP\USERS\MROTR\Investigations\000_EarlyTesting\" ...
	, simFolderName , "\Loads\INT");

% Save current folder and go to simulation folder
scriptFolder = cd(simFolder);

% Step 2: Choose Tmin, Tmax and write the .int file name (intFileName)
Tmin = 0;   % [s] - Start time of sample extraction
Tmax = 600;   % [s] - End time of sample extraction
intFileName = "12_14_05_000_150_20_036_120_33_000_000_012.int"
% Pull data from int file
[GenInfo,Xdata,Ydata,ErrorString] = LAC.timetrace.int.readint...
(intFileName, 1, [], Tmin, Tmax);

% Save data in .mat file so it doesn't have to be extracted every time this
% script is run
cd(scriptFolder)
save('intData.mat')



%% Load and treat data
% ---------------------------------
clc; clear; close all;

% Load data
load('intData.mat')
% Start a figure cell array to later use for exporting figures
figs = [];

% Checking sampling time. It"s constant and = 0.04 (25 Hz). The sample avg
% is also available in "GetInfo"
XdataDiff = diff(Xdata);

% Create frequency indexes
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
L = length(Xdata);		% Number of samples
nf = Fs*(0:(L/2))/L;	% Frequency index

% The below vector contains the IDs of the sensors which are of interest.
% If the # of sensors prepped for simulation is changed then these IDs maybe will
% change as well
sensorIDs = [1,		2,		8,		11,		14,		17,		18,		22,		478:495];
%           Vfree	Vhub	Pi1		Pi2		Pi3		PSI		Omega	GenMom
% Sensors 478 -> 495 are the xKF -> OMPzKF sensors

% Sensor names. Used for legends when plotting
legs = ["Vfree", "Vhub", "Pi1", "Pi2", "Pi3", "PSI", "Omega", "GenMom", "xKF", ...
	"yKF", "zKF", "AlxKF", "AlyKF", "AlzKF", "UxKF", "UxKF", "UyKF","OMxKF", ...
	"OMxKF", "OMyKF", "AxKF", "AyKF", "AzKF","OMPzKF", "OMPyKF", "OMPzKF"];

% Data of sensors of interest
sensorData = Ydata(:,sensorIDs);


%% Plotting
% ---------------------------------
close all

% Free wind and hub wind
f = myfig(1, defTwoSubFigSize);
plot(Xdata, sensorData(:,1:2))
title('Free wind and hub wind timeseries')
xlabel('Time [s]')
ylabel('Amplitude')
legend(legs(1:2))
figs = [figs, f];

% Blade pitches
f = myfig(2, defFigSize);
plot(Xdata , sensorData(:,3:5))
title('Blade pitches 1-3 timeseries')
xlabel('Time [s]')
ylabel('Amplitude')
legend(legs(3:5))
figs = [figs, f];

% Rotor speed
f = myfig(3, defFigSize);
plot(Xdata , sensorData(:,7))
title('Rotor speed timeseries')
xlabel('Time [s]')
ylabel('Amplitude')
legend(legs(7))
figs = [figs, f];

% Generator torque
f = myfig(4, defFigSize);
plot(Xdata , sensorData(:,8))
title('Generator Torque timeseries')
xlabel('Time [s]')
ylabel('Amplitude')
legend(legs(8))
figs = [figs, f];

% xKF, yKf
f = myfig(5, defFigSize);
plot(Xdata, sensorData(:,9:10))
title('x-direction translation (vestas coordinates)')
xlabel('frequency (Hz)')
ylabel('Amplitude')
legend(legs(9:10))
figs = [figs, f];

% zKf
f = myfig(7, defFigSize);
plot(Xdata, sensorData(:,11))
title('y-direction translation (vestas coordinates)')
xlabel('frequency (Hz)')
ylabel('Magnitude')
legend(legs(11))
figs = [figs, f];


% xKF, yKf and blade pitch
f = myfig(8, defTwoSubFigSize);
subplot(211)
plot(Xdata, sensorData(:,9:10))
legend(legs(9:10))
subplot(212)
plot(Xdata , sensorData(:,3))
title('x-direction translation (vestas coordinates)')
xlabel('frequency (Hz)')
ylabel('Amplitude')
legend(legs(3))
figs = [figs, f];

%% Plotting FFTs
% ---------------------------------

% xKF fft
Y = abs(fft(sensorData(:,9)))/L;
Y = Y(1:(end/2+1)); % Only one half of fft (up to nyquist frequency)
f = myfig(20, defFigSize)
plot(nf, Y)
xlim([0 1])
ylim([0 1])
title('FFT of x-direction translation (vestas coordinates)')
xlabel('frequency (Hz)')
ylabel('Magnitude')
legend(legs(9))
figs = [figs, f];

% yKF fft
Y = abs(fft(sensorData(:,10)))/L;
Y = Y(1:(end/2+1)); % Only one half of fft (up to nyquist frequency)
f = myfig(21, defFigSize)
plot(nf, Y)
xlim([0 1])
ylim([0 1])
title('FFT of y-direction translation (vestas coordinates)')
xlabel('frequency (Hz)')
ylabel('frequency frequency')
legend(legs(10))
figs = [figs, f];


%% Plotting correleations
% ---------------------------------
% Removing means
sensorDataNomean = zeros(length(Ydata), length(sensorData));
for ii = 1:length(sensorData(1,:))
	sensorDataNomean(:,ii) = sensorData(:,ii) - mean(sensorData(:,ii));
end

f = myfig(40)
plot(xcorr(sensorDataNomean(:,9), sensorDataNomean(:,3)))
xlim([0 2*length(Xdata)])% ylim([ ])
title('Correleation between xKF and Pitch angle')
% xlabel('')
% ylabel('f')
% legend()
figs = [figs, f];

f = myfig(41)
plot(xcorr(sensorDataNomean(:,10), sensorDataNomean(:,3)))
xlim([0 2*length(Xdata)])% ylim([ ])
title('Correleation between yKF and Pitch angle')
% xlabel('')
% ylabel('f')
% legend()
figs = [figs, f];

% The covariances
covx = cov(xFK_nomean, Pi1_nomean)
covy = cov(yFK_nomean, Pi1_nomean)


%% Templates
% f = myfig(xx, defFigSize);
% plot(, )
% xlim([ ])
% ylim([ ])
% title('')
% xlabel('')
% ylabel('f')
% legend()
% figs = [figs, f];



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
