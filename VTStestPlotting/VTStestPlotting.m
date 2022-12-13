clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.

if ispc
	% PC path
	addpath('C:\repo\lac-matlab-toolbox')
else
	% Mac path
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
save(strcat("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\",matFileName), "GenInfo", "simNames", "simFolders", "Xdata", "Ydata");


%% Load and treat data
% ---------------------------------
clc; clear; close all;

if ispc
	load("c:\Users\Mrotr\OneDrive - Aalborg Universitet\Control and Automation\3. Semester\POSC\Project\VTSintData");
else
	load("/Users/martin/Library/CloudStorage/OneDrive-AalborgUniversitet/Control and Automation/3. Semester/POSC/Project/VTSintData");
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
sensorSetupInit_senSetup2



% Free wind, blade pitch, Rotor speed, Generator torque
% f = myfigplot(figNo00, [senIdx.Vhfree senIdx.Pi1 senIdx.Omega senIdx.GenMom], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "VfreeToMgen.png")];

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


% FIGURE SET 1
% --------------------------

% (EDIT)
wantedSims = [1 5 4];


% The 1P and 3P frequencies as observed in the Rotor Azimuth plot
P1 = 0.174; P3 = 0.522; % Hz

% Wind and power
figNo = 1;
f = myfigplot(figNo, [senIdx.Vhfree, senIdx.Power], wantedSims, Xdata(:,1), ...
	Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 1, xLimDef, ...
	{[13 19], [6000 8500]}, 1);
axes=findobj(f,'type','axes');
legend(axes(1), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_wind_pow.png")];


% FFT: PSI
figNo = 2;
f = myfigplot(figNo, [senIdx.PSI], wantedSims, nf, sensorDataFFT(:,wSpdIdx), titleArray, ...
	ylabelArray, simNames(:,wSpdIdx), 0, xLimFftDef, {[0 60]}, 1);

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
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 1, xLimDef, 0, 1);
axes=findobj(f,'type','axes');
legend(axes(4), 'Location', 'southeast')

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_th_w_py_vy.png")];


% FFT: Pitch, gen spd, foreaft pos, foreaft vel
figNo = 4;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 0, ...
	xLimFftDef, {[0 0.3], [0 2],[0 0.4],[0 0.1]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(4), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
% xline(axes(3), P3, '--', {'3P'}, 'LabelOrientation', ...
% 			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');

annotation(f, 'textarrow',[0.25 0.18],[0.9 0.88],'String','1st mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_th_w_py_vy.png")];



% FIGURE SET 2
% --------------------------

% (EDIT)
wantedSims = [1 5];

% The 1P and 3P frequencies as observed in the Rotor Azimuth plots
P1 = 0.174; P3 = 0.522; % Hz

% Pitch, gen spd, foreaft pos, foreaft vel
figNo = 10;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 1, xLimDef, 0, 1);

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_th_w_py_vy.png")];


% FFT: Pitch, gen spd, foreaft pos, foreaft vel
figNo = 11;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 0, ...
	xLimFftDef, {[0 0.3], [0 2],[0 0.4],[0 0.1]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(4), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(3), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_fft_th_w_py_vy.png")];


% Time ZOOM: Pitch, gen spd, foreaft pos, foreaft vel
figNo = 12;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	Xdata(:,1), Ydata(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 1, [160 260], 0, 1);
axes=findobj(f,'type','axes');
legend(axes(4), 'Location', 'southeast')

annotation(f, 'textarrow',[0.35 0.41],[0.13 0.16],'String','2nd mode oscillations');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_zoom_th_w_py_vy.png")];


% Y-axis ZOOM: FFT - Pitch, gen spd, foreaft pos, foreaft vel
figNo = 13;
f = myfigplot(figNo, [senIdx.Pi1, senIdx.OmGen, senIdx.yKF, senIdx.UyKF], wantedSims, ...
	nf, sensorDataFFT(:,wSpdIdx), titleArray, ylabelArray, simNames(:,wSpdIdx), 0, ...
	xLimFftDef, {[0 0.04], [0 0.6],[0 0.1],[0 0.02]}, 1);

% Pull axes from previous figure.
axes=findobj(f,'type','axes');
xline(axes(4), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(3), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(1), P1, '--', {'1P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(4), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(3), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
xline(axes(1), P3, '--', {'3P'}, 'LabelOrientation', ...
			'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
legend(axes(4),'Location','best')

annotation(f, 'textarrow',[0.70 0.74],[0.89 0.84],'String','2nd mode');
annotation(f, 'textarrow',[0.65 0.73],[0.24 0.18],'String','2nd mode');

figArray = [figArray f];
figNameArray = [figNameArray strcat(setupPrefix, string(figNo), "_zoom_fft_th_w_py_vy.png")];

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
% 				'horizontal', 'LabelVerticalAlignment','top', 'HandleVisibility','off');
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
	figSaveDir = "/Users/martin/Documents/Git/Repos/CA9_Writings/Graphics/TestResults/VTSplotting";
end
createNewFolder = 0;
% I set the name of the folder where the images are saved to the .mat file
% name:
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, "NoName", resolution)
