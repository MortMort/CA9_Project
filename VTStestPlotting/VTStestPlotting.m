clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.

if ispc
	% PC path
	addpath('C:\repo\lac-matlab-toolbox')
else
	% Mac path
	addpath('/Users/martin/Documents/Git/Repos/CA9_Project/lac-toolbox')
	% I DONT HAVE THE LAC TOOLBOX IN MY REPOOOO
end


% Go to the folder location of this script (such that ctrl + enter always
% works)
filePath = matlab.desktop.editor.getActiveFilename;
if ispc
	fileNameStartIndex = max(strfind(filePath, "\"));
else
	fileNameStartIndex = max(strfind(filePath, "/"));
end
scriptFolder = filePath(1:fileNameStartIndex);
cd(scriptFolder)
clear("filePath", "fileNameStartIndex")

% (Edit) Set name of .mat file folder save
saveFolderName = "";
% (Edit Set folder directory - Leave as <""> if you want folder in same location as this script
saveFolderPath = "";
% Ex: saveFolderPath = "C:\repo\mrotr_personal\"; (remember "\" at the end!)
% (Edit) Set file name of mat file
matFileName = "VTSintData";



% Pull data from int file and save as .mat file
% ---------------------------------


% (Edit) The names of the .int files (w.o. ".int")
intFileNames = [
				"1112a001"
				"1116a001"
				"1126a001"
			   ];
		   
% Create the simulation names for plotting legends later
wSpdStrArray = [" 12 m/s", " 16 m/s", " 26 m/s"];
% for ii = 1:length(wSpdStrArray)
% 	simNames(:,ii) = strcat([
% 			"LQI"
% 			"LQI (OP 12 m/s tuning)"
% 			"LQI (OP 26 m/s tuning)"
% 			"FLC PI w.o. FATD"
% 			"FLC PI detuned"
% 			"FLC PI w. FATD"
% 			], wSpdStrArray(ii));
% end

simNames= ["LQI"
			"LQI (OP 12 m/s par.)"
			"LQI (OP 26 m/s par.)"
			"FLC PI w.o. FATD"
			"FLC PI detuned"
			"FLC PI w. FATD"
			];



% (Edit) Put the folder paths to the .int files here
% simDirArray = [
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\023\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\021_op12ms\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\022_op26ms\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\002_BaselineV2\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\008_detunedFLCnoFATD\05_000\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\007_Baseline_fatdOn\001\Loads\INT\"
% 				];

if ispc
	simDirArray = [
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\023\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\021_op12ms\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\022_op26ms\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\002_BaselineV2\Loads\INT\"				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\008_detunedFLCnoFATD\05_000\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\007_Baseline_fatdOn\001\Loads\INT\"
				];
else
	% Mac
	simDirArray = [
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/lqi-023/"
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/lqi-021_op_12ms/"
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/lqi-022_op_26ms/"
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/nofatd-002_BaselineV2/"
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/detuned-05_00/"
		"/Users/martin/Documents/Git/Repos/CA9_Project/VTStestPlotting/intFiles/fatdOn-001/"
		];
end

simFolders = [	
				simDirArray(1)
				simDirArray(2)
				simDirArray(3)
				simDirArray(4)
				simDirArray(5)
				simDirArray(6)
			 ];
		 

% (Edit) Choose Tmin, Tmax and write the .int file names (intFileNames)
Tmin = 0;			% [s] - Start time of sample extraction
Tmax = 2000;		% [s] - End time of sample extraction


% Pull the data from the .int files and store them in .mat file
for nn = 1:length(simFolders)
	cd(simFolders(nn));
	for ii = 1:length(intFileNames)
		% Pull the data from the .int file
		[GenInfo{nn,ii}, Xdata{nn,ii}, Ydata{nn,ii}, ErrorString{nn,ii}] = LAC.timetrace.int.readint...
			(strcat(intFileNames(ii), ".int"), 1, [], Tmin, Tmax);

		% Handle no .int files found in folder.
		if length(GenInfo{nn,ii}) == 0
			str = strcat("Error! .int file name ", intFileNames(ii), sprintf(" not found for folder #%.0f", nn));
			disp(str)
		end
	end
end

% Go back to the script folder
cd(scriptFolder);
% Save data as .mat
if ispc
	save(strcat("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\",matFileName), "GenInfo", "simNames", "simFolders", "Xdata", "Ydata");
else
	% Mac
	save(strcat("/Users/martin/Library/CloudStorage/OneDrive-AalborgUniversitet/Control and Automation/3. Semester/POSC/Project/", matFileName), "GenInfo", "simNames", "simFolders", "Xdata", "Ydata");
end

%% Load and treat data
% ---------------------------------
clc; clear; close all;

matFileName = "VTSintData";
if ispc
	% Windoes computer
	load(strcat("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\", matFileName));
else
	% My mac
	load(strcat("/Users/martin/Library/CloudStorage/OneDrive-AalborgUniversitet/Control and Automation/3. Semester/POSC/Project/", matFileName));
end

% Treat data
% ---------------------------------
% Add path to setup files
if ispc
	% Windows
	addpath('c:\Users\Mrotr\Git\Repos\CA9_Project\intFileMatlabAnalysis\')
else
	% Mac
	addpath('../intFileMatlabAnalysis/')
end

% Init sensor arrays, names, and such
% sensorSetupInit_senSetup1 % Older setup with fewer sensors
sensorSetupInit_senSetup3



% Free wind, blade pitch, Rotor speed, Generator torque
% f = myfigplot(figNo00, [senIdx.Vhfree senIdx.Pi1 senIdx.Omega senIdx.GenMom], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "VfreeToMgen.png")];

dimYdata = size(Ydata);

% Create frequency indexes for ffts
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
% for nn = 1:size(Ydata,1)
% 	for ii = 1:size(Ydata,2)
% 		L{nn,ii} = length(Xdata{nn,ii});	% Number of samples
% 		nf{nn,ii} = Fs.*(0:(L{nn,ii}/2))/L{nn,ii};	% Frequency index
% 	end
% end

% Create ffts
for nn = 1:size(Ydata,1)
	for ii = 1:size(Ydata,2)
		L{nn,ii} = length(Xdata{nn,ii});	% Number of samples
		N = 2^nextpow2(L{nn,ii});			% Length of fourier window (i pad with zeros!)
% 		N = L{nn,ii};
		nf{nn,ii} = Fs.*(0:((N-1)/2))/N;	% Frequency index
		
		% Applying hamming window to whole signal:
		dataWindowed = Ydata{nn,ii}(:,sensorIDs).*hamming(L{nn,ii},'periodic');
		% Signal with no window
		dataNoWindow = Ydata{nn,ii}(:,sensorIDs);
		
		% Removing mean from data then applying window
		dataWinNoBias = (Ydata{nn,ii}(:,sensorIDs)-mean(Ydata{nn,ii}(:,sensorIDs))).*hamming(L{nn,ii},'periodic');
		% Removing mean from data and not using a window
		dataNoWinNoBias = dataNoWindow-mean(dataNoWindow);
		
		Y = abs(fft(dataWinNoBias, N))/L{nn,ii};
		sensorDataFFT{nn,ii}(:,sensorIDs) = Y(1:((end+1)/2),:); % Only one half of fft (up to nyquist frequency)
	end
end

% Testing
% myfig(-1);
% plot(dataNoWindow(:,1))
% hold on
% plot(dataNoWinNoBias(:,1))





%% 16 m/s compare Plotting
close all

% Start a figure cell array to later use for exporting figures
figArray = [];
figNameArray = [];

% Plotting setup is contained in different .m files to account for the
% possibility to save differnet plotting setups
setupPrefix = "";
% figPlotSetup_tj00


set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(groot, 'defaultTextInterpreter','latex');
set(groot, 'defaultBubblelegendInterpreter', 'latex')
set(groot, 'defaultPolaraxesTickLabelInterpreter', 'latex')
set(groot, 'defaultTextInterpreter', 'latex')


set(groot,'defaultAxesFontSize', 13)					% Default is 10
set(groot,'defaultAxesTitleFontSizeMultiplier', 1.1)	% Default is 1.1
% set(groot, 'defaultAxesLabelFontSize', 10);			% Default is ??

% set(groot, 'defaultLegendFontSize', 20);				% Default is 9 - doesnt work??
% set(groot, 'defaultBubblelegendFontSize', 20);			% Default is 9 - doesnt work??

% Get list of settings that can be changed:
% get(groot, 'factory')


xLimDef = [0 1000]; % Default xlim (0 -> 600 seconds)
xLimFftDef = [0 0.6]; % Default FFT xlim (0 -> 0.6 Hz)


% Wind speed index:
% 1 = 12 m/s
% 2 = 16 m/s
% 3 = 26 m/s
wSpdIdx = 2;


% FIGURE SET: LQI vs. FLC detuned vs. FLC
% --------------------------

% (EDIT)
wantedSims = [1 5 4];


% The 1P and 3P frequencies as observed in the Rotor Azimuth plot
P1 = 0.174; P3 = 0.522; % Hz

% Wind and power
figNo = 1;
f = myfigplot(figNo, [senIdx.Vhfree, senIdx.Power], wantedSims, Xdata(:,1), ...
	Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, xLimDef, ...
	{[13 19], [6000 8500]}, 1);
axes=findobj(f,'type','axes');
% legend(axes(2), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_wind_pow.png")];


% FFT: PSI
figNo = 2;
f = myfigplot(figNo, [senIdx.PSI], wantedSims, nf, sensorDataFFT(:,wSpdIdx), titleArray, ...
	ylabelArray, simNames, 0, xLimFftDef, {[0 30]}, 1);

axes=findobj(f,'type','axes');
xline(axes(1), P1, '--', {'1P'}, 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(1), P3, '--', {'3P'}, 'LabelOrientation', ...
				'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
legend(axes(1),'Location','north')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fftazi.png")];


% Pitch, gen spd, foreaft pos, foreaft vel
figNo = 3;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, ...
	xLimDef, {[0 15],[350 450],[0 25],[-3 3]}, 1);
axes=findobj(f,'type','axes');
legend(axes(4), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_th_w_py_vy.png")];


% FFT: foreaft pos
figNo = 4;
f = myfigplot(figNo, [senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames, 0, ...
	xLimFftDef, {[0 0.3], [0 2],[0 0.4],[0 0.1]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes, P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes, P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
legend(axes, 'Location', 'north')

annotation(f, 'textarrow',[0.25 0.18],[0.85 0.83],'String','1st mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_py.png")];



% FIGURE SET: LQI vs. FLC detuned
% --------------------------

% (EDIT)
wantedSims = [1 5];

% The 1P and 3P frequencies as observed in the Rotor Azimuth plots
P1 = 0.174; P3 = 0.522; % Hz

% Pitch, gen spd, foreaft pos, foreaft vel
figNo = 10;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, ...
	xLimDef, {[7 12],[375 425],[9 15],[-0.6 0.6]}, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_th_w_py_vy.png")];


% FFT: Pitch, gen spd, foreaft pos
figNo = 11;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames, 0, ...
	[0 0.1], {[0 0.12], [0 1.25],[0 0.23],[0 0.1]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(3), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(2), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_th_w_py.png")];


% Time ZOOM: Pitch, gen spd, foreaft vel
figNo = 12;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, [160 260], 0, 1);
axes=findobj(f,'type','axes');
legend(axes(3), 'Location', 'southeast')

annotation(f, 'textarrow',[0.36 0.42],[0.13 0.17],'String','2nd mode oscillations');
annotation(f, 'textarrow',[0.51 0.45],[1-0.15 1-0.19],'String','2nd mode oscillations');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_zoom_th_w_vy.png")];


% Y-axis ZOOM: FFT - Pitch, foreaft vel
figNo = 13;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames, 0, ...
	xLimFftDef, {[0 0.025], [0 0.013]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(2), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
% xline(axes(3), P1, '--', {'1P'}, 'LabelOrientation', ...
% 			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(1), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(2), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
% xline(axes(3), P3, '--', {'3P'}, 'LabelOrientation', ...
% 			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(1), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
legend(axes(2),'Location','best')

annotation(f, 'textarrow',[0.70 0.74],[0.79 0.72],'String','2nd mode');
annotation(f, 'textarrow',[0.67 0.73],[0.38 0.27],'String','2nd mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_zoom_fft_th_vy.png")];


% Bending moments of tower
figNo = 14;
f = myfigplot(figNo, [senIdx.Mxt17], wantedSims, Xdata, Ydata(:,wSpdIdx), ...
	titleArray, ylabelArray, simNames, 1, 0, 0, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
legend(axes,'Location','southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_mxt17.png")];


% FFT: Bending moments of tower zoom 1
figNo = 15;
f = myfigplot(figNo, [senIdx.Mxt17], wantedSims, nf, sensorDataFFT, ...
	titleArray, ylabelArray, simNames, 0, [0 0.1], 0, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
legend(axes,'Location','northeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_mxt17_z1.png")];

% FFT: Bending moments of tower zoom 2
figNo = 16;
f = myfigplot(figNo, [senIdx.Mxt17], wantedSims, nf, sensorDataFFT, ...
	titleArray, ylabelArray, simNames, 0, [.4 .6], 0, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
legend(axes, 'Location','northeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_mxt17_z2.png")];



%% 12 and 26 m/s


% 12, 16 and 26 m/s
% --------------------------


% Wind speed index:
% 1 = 12 m/s
% 2 = 16 m/s
% 3 = 26 m/s
wSpdIdx = 1;

% (EDIT)
wantedSims = [1 2 3];


% The 1P and 3P frequencies as observed in the Rotor Azimuth plot
P1 = 0.174; P3 = 0.522; % Hz

% Power, pitch, gen spd, foreaft pos, foreaft vel
figNo = 20;
f = myfigplot(figNo, [senIdx.Power, senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, ...
	xLimDef, {[6000 8500],[-4 6],[375 425],[12 23],[-1 1]}, 1);
axes=findobj(f,'type','axes');
legend(axes(5), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_pow_th_w_py_vy.png")];


% FFT: Pitch angle, omgen, foreaft pos, vel
figNo = 21;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames, 0, ...
	[0 0.1], {[0 0.4],[0 1.3],[0 0.45],[0 0.05]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(4), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(4), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');

% annotation(f, 'textarrow',[0.25 0.18],[0.85 0.83],'String','1st mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_th_w_py_vy.png")];


% 16 m/s and 26 m/s
% --------------------------


% Wind speed index:
% 1 = 12 m/s
% 2 = 16 m/s
% 3 = 26 m/s
wSpdIdx = 3;

% (EDIT)
wantedSims = [1 3];


% The 1P and 3P frequencies as observed in the Rotor Azimuth plot
P1 = 0.161; P3 = 0.483; % Hz
% Power, pitch, gen spd, foreaft pos, foreaft vel
figNo = 30;
f = myfigplot(figNo, [senIdx.Power, senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, ...
	xLimDef, {[6000 8500],[20 28],[355 385],[7.5 10],[-0.5 0.5]}, 1);
axes=findobj(f,'type','axes');
legend(axes(5), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_pow_th_w_py_vy.png")];


% FFT: Pitch angle, omgen, foreaft pos, vel
figNo = 31;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames, 0, ...
	xLimFftDef, {[0 0.25],[0 0.6],[0 0.07],[0 0.0275]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(4), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(4), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
legend(axes(4), 'Location', 'north')
% annotation(f, 'textarrow',[0.25 0.18],[0.85 0.83],'String','1st mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_th_w_py_vy.png")];


%% Data analysis

% simNames= ["LQI"
% 			"LQI (OP 12 m/s par.)"
% 			"LQI (OP 26 m/s par.)"
% 			"FLC PI w.o. FATD"
% 			"FLC PI detuned"
% 			"FLC PI w. FATD"
% 			];

% I am extracting data for only 16 m/s
% 2 = 16 m/s
wSpdIdx = 2;

data.LQI		= Ydata{1,wSpdIdx};
data.FLCdetuned	= Ydata{5,wSpdIdx};
data.FLC		= Ydata{4,wSpdIdx};

data.nt			= Xdata{1,1}; % Time indexes are the same for aaaaall simulations


% The DELs for 16 m/s
Ldel.LQI		= mydel(data.LQI(:,senIdx.Mxt17), data.nt);
Ldel.FLCdetuned = mydel(data.FLCdetuned(:,senIdx.Mxt17), data.nt);
Ldel.FLC		= mydel(data.FLC(:,senIdx.Mxt17), data.nt)

%% Pitch angle filtering and sum of change

% Creating the filter
% ----------------------

% Defining a fitting frequency 
ws = 0.2;
ws_equiv = ws/(Fs); 


% Create filter
d1 = designfilt("lowpassiir",FilterOrder=4, ...
    HalfPowerFrequency=ws_equiv,DesignMethod="butter");

% freqz(d1)

% Both filtering and calculating the sum of blade pitch changes of the
% blade pitch singal
[Pi1filtered.LQI,			pi1ChngSum.LQI]			= mypitchsum(data.LQI(:,senIdx.Pi1), d1);
[Pi1filtered.FLCdetuned,	pi1ChngSum.FLCdetuned]	= mypitchsum(data.FLCdetuned(:,senIdx.Pi1), d1);
[Pi1filtered.FLC,			pi1ChngSum.FLC]			= mypitchsum(data.FLC(:,senIdx.Pi1), d1)

% Plotting to give an impression of the result of the filtering
myfig(100);
subplot(311)
plot(data.nt, data.LQI(:,senIdx.Pi1), 'LineWidth', 1.3)
hold on
plot(data.nt, Pi1filtered.LQI, 'LineWidth', 1.3)
legend('Pitch angle 1 filtered', 'Pitch angle 1')
xlim([0 100])
title('LQI Pitch angle 1 filtered comparison zoomed at 0-100 s')

subplot(312)
plot(data.nt, data.FLCdetuned(:,senIdx.Pi1), 'LineWidth', 1.3)
hold on
plot(data.nt, Pi1filtered.FLCdetuned, 'LineWidth', 1.3)
legend('Pitch angle 1 filtered', 'Pitch angle 1')
xlim([0 100])
title('Detuned FLC Pitch angle 1 filtered comparison zoomed at 0-100 s')

subplot(313)
plot(data.nt, data.FLC(:,senIdx.Pi1), 'LineWidth', 1.3)
hold on
plot(data.nt, Pi1filtered.FLC, 'LineWidth', 1.3)
legend('Pitch angle 1 filtered', 'Pitch angle 1')
xlim([0 100])
title('FLC Pitch angle 1 filtered comparison zoomed at 0-100 s')

myfig(101);
plot(data.nt, Pi1filtered.LQI, 'LineWidth', 1.3)
hold on
plot(data.nt, Pi1filtered.FLCdetuned, 'LineWidth', 1.3)
legend('LQI', 'Detuned FLC')
xlim([0 300])
title('FLC Pitch angle 1 filtered LQI vs detuned FLC zoomed at 0-100 s')


dataFFT.LQI = sensorDataFFT{1,wSpdIdx};
dataPi1FFT.LQI = myfft(Pi1filtered.LQI, data.nt, Fs)


myfig(102);
plot(nf, dataPi1FFT.LQI, 'LineWidth', 1.3)
hold on
plot(nf, dataFFT.LQI(:,senIdx.Pi1), 'LineWidth', 1.3)
xlim([0 0.6])


%% Export figures
% ---------------------------------
if ispc
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\VTSplotting\";
else
	% Mac
	figSaveDir = "/Users/martin/Documents/Git/Repos/CA9_Writings/Graphics/TestResults/VTSplotting";
end
createNewFolder = 0;
% I set the name of the folder where the images are saved to the .mat file
% name:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, "false", "NoName", resolution)




%% functions
% ---------------------------------

function del = mydel(data, nt)
	% Calculating 1 Hz damege equivalent loads with rainflow count

	% Based on steel with Wohler constant of 4
	% Based on 1 Hz equivalent

	wcSteel = 4;					% Wohler coefficient for steel	
	feq = 1;						% [Hz] - 1 Hz equivalent
	Neq = 1/feq * nt(end);		% Product of 1/feq and the simulation time

	% Calculating rainflow count
	rainflowOut = rainflow(data, nt);

	% Creating Rainflow Count table
	rfT = array2table(rainflowOut, 'VariableNames',{'Count','Range','Mean','Start','End'});
	
	sum = 0;
	
	for ii = 1:length(rfT.Count)
		sum = sum + rfT.Count(ii)*rfT.Range(ii)^wcSteel;
	end
	
	% Damege equivalent load out
	del = (sum/Neq)^(1/wcSteel);
end

function [pitchFiltered, pitchChngSum] = mypitchsum(data, filter)
	% Filtering blade pitch data and calculating sum of pitch change
	
	% Filter signal
	pitchFiltered = filtfilt(filter,data);
	
	% Initialize sum variable
	pitchChngSum = 0;
	
	% Sum all changes
	for ii = 1:length(pitchFiltered)-1
		pitchChngSum = pitchChngSum + abs(pitchFiltered(ii+1) - pitchFiltered(ii));
	end

end


function out = myfft(data, nt, Fs)
	% FFT with:
	% - Padding of same length as singnal length
	% - No bias removed through mean of signal
	% - Windowed with a hamming window
	% INPUTS
	%	data	: Time series data
	%	nt		: time index
	%	Fs		: Sample time

	% Create ffts
	L = length(data);	% Number of samples
	N = 2^nextpow2(L);			% Length of fourier window (i pad with zeros!)
	nf = Fs.*(0:((N-1)/2))/N;	% Frequency index
	
	% Applying hamming window to whole signal:
	dataWindowed = data.*hamming(L,'periodic');
	
	% Removing mean from data then applying window
	dataWinNoBias = (data-mean(data)).*hamming(L,'periodic');
	
	Y = abs(fft(dataWinNoBias, N))/L;
	out = Y(1:((end+1)/2),:); % Only one half of fft (up to nyquist frequency)
end