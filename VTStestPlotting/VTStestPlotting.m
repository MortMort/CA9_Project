clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.

addpath('C:\repo\lac-matlab-toolbox')

% Go to the folder location of this script (such that ctrl + enter always
% works)
filePath = matlab.desktop.editor.getActiveFilename;
fileNameStartIndex = max(strfind(filePath, "\"));
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
for ii = 1:length(wSpdStrArray)
	simNames(:,ii) = strcat([
			"LQI"
			"LQI (OP 12 m/s)"
			"LQI (OP 26 m/s)"
			"FLC PI w.o. FATD"
			"FLC PI detuned"
			"FLC PI w. FATD"
			], wSpdStrArray(ii));
end



% (Edit) Put the folder paths to the .int files here
% simDirArray = [
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\023\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\021_op12ms\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\006_CustomController\022_op26ms\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\002_BaselineV2\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\008_detunedFLCnoFATD\05_000\Loads\INT\"
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\007_Baseline_fatdOn\001\Loads\INT\"
% 				];
			
simDirArray = [
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\lqi-023\"
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\lqi-021_op_12ms\"
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\lqi-022_op_26ms\"
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\nofatd-002_BaselineV2\"
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\detuned-05_00\"
	"c:\Users\Mrotr\Git\Repos\CA9_Project\VTStestPlotting\intFiles\fatdOn-001\"
	];

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
save(strcat("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\",matFileName), "GenInfo", "simNames", "simFolders", "Xdata", "Ydata");


%% Load and treat data
% ---------------------------------
clc; clear; close all;

load("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\VTSintData");

% Treat data
% ---------------------------------
% Add path to setup files
if ispc
	% Windows
	addpath('c:\Users\Mrotr\Git\Repos\CA9_Project\intFileMatlabAnalysis\')
else
	% Mac
end

% Init sensor arrays, names, and such
% sensorSetupInit_senSetup1 % Older setup with fewer sensors
sensorSetupInit_senSetup2



% Free wind, blade pitch, Rotor speed, Generator torque
% f = myfigplot(100, [senIdx.Vhfree senIdx.Pi1 senIdx.Omega senIdx.GenMom], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, "VfreeToMgen.png")];

dimYdata = size(Ydata)

% Create frequency indexes for ffts
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
for nn = 1:dimYdata(1)
	for ii = 1:dimYdata(2)
		L{nn,ii} = length(Xdata{nn,ii});	% Number of samples
		nf{nn,ii} = Fs.*(0:(L{nn,ii}/2))/L{nn,ii};	% Frequency index
	end
end

% Create ffts
for nn = 1:dimYdata(1)
	for ii = 1:dimYdata(2)
		Y = abs(fft(Ydata{nn,ii}(:,sensorIDs)))/L{nn,ii};
		sensorDataFFT{nn,ii}(:,sensorIDs) = Y(1:((end+1)/2),:); % Only one half of fft (up to nyquist frequency)
	end
end


%% Compare Plotting
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


set(groot,'defaultAxesFontSize', 11)					% Default is 10
set(groot,'defaultAxesTitleFontSizeMultiplier', 1.1)	% Default is 1.1
% set(groot, 'defaultAxesLabelFontSize', 10);			% Default is ??

% set(groot, 'defaultLegendFontSize', 20);				% Default is 9 - doesnt work??
% set(groot, 'defaultBubblelegendFontSize', 20);			% Default is 9 - doesnt work??

% Get list of settings that can be changed:
% get(groot, 'factory')


% (EDIT)
selectedSimSetup = 1;

if selectedSimSetup == 1
	wantedSims = [1 4 5];
elseif selectedSimSetup == 2
	wantedSims = [1 2];
elseif selectedSimSetup == 3
	wantedSims = [1 2 3];
elseif selectedSimSetup == 4
	wantedSims = [1 2 3 4];
elseif selectedSimSetup == 5
	wantedSims = [1 2 3 4 5];
elseif selectedSimSetup == 6
	wantedSims = [1 2 3 4 5 6];
% elseif selectedSimSetup == 7
% 	wantedSims = [1 2 3 4 5 6 7];
% elseif selectedSimSetup == 8
% 	wantedSims = [1 2 3 4 5 6 7 8];
end

% Wind speed index:
% 1 = 12 m/s
% 2 = 16 m/s
% 3 = 26 m/s
wSpdIdx = 2;

xLimDef1 = [0 1000]; % Default xlim (0 -> 600 seconds)
xLimFftDef1 = [0 0.6]; % Default FFT xlim (0 -> 0.6 Hz)
yLimDef1 = [0 1];

ylimTest = [0 1;0 2;0 3;0 4]

% Wind and power
f = myfigplot(1, [senIdx.Vhfree, senIdx.Power], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 1, xLimDef1, 0, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "00_.png")];

% FFT: PSI
f = myfigplot(2, [senIdx.PSI], wantedSims, nf, sensorDataFFT(:,wSpdIdx), titleArray, ...
	ylabelArray, simNames, 0, xLimFftDef1, [0 60], 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "01_.png")];

% Pull axes from previous figure.
% axes=findobj(f,'type','axes')
% xline(axes(1), 100) % Put a vertical line at first axes

% Pitch, gen spd, foreaft pos, foreaft vel
f = myfigplot(3, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames, 1, xLimDef1, 0, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "02_.png")];


% FFT: Pitch, gen spd, foreaft pos, foreaft vel
f = myfigplot(4, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, nf, sensorDataFFT(:,wSpdIdx), titleArray, ...
	ylabelArray, simNames, 0, xLimFftDef1, [0 0.5; 0 3;0 1;0 0.2], 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, "01_.png")];


% Plotting FFTs
% ---------------
% Changes Ydata -> sensorDataFFT, Xdata -> nf, 1 -> 0

% x and y translation position and roll and pitch angle
% f = myfigplot(200, [senIdx.xKF senIdx.yKF], wantedSims, nf, sensorDataFFT, ...
% 	titleArray, ylabelArray, simNames, 0, xLimFftDef1, [0 1]);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, "xPosyPosFFT.png")];





%% OTHER PLOTTING SECTION

% % Pitch reference and pitch reference derivative
% nt = Xdata{1,1};
% 
% figSize.one =	[1 0.25 700 300];
% figSize.two =	[1 0.25 700 400];
% figSize.three = [1 0.25 700 550];
% figSize.four =	[1 0.25 700 670];
% 
% f = myfig(1000, figSize.two);
% subplot(211)
% plot(nt, Ydata{1,2}(:,senIdx.Vhfree))
% % hold on
% % plot(nt, Ydata{1,1}(:,senIdx.Power))
% % plot(nt, Ydata{1,1}(:,senIdx.OmGen))
% % plot(nt, Ydata{1,1}(:,senIdx.PSI))
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




%% Export figures
% ---------------------------------
if ispc
	figSaveDir = "c:\Users\Mrotr\Git\Repos\CA9_Writings\Graphics\TestResults\VTSplotting\";
else
	% Mac
	disp('MAC PATH NOT DEFINED')
end
createNewFolder = 0;
% I set the name of the folder where the images are saved to the .mat file
% name:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, "NoName", resolution)
