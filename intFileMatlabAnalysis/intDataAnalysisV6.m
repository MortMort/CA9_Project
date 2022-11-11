clc; clear; close all;
% This script is made to pull and analyse int data from one
% or more simulations. This first part does not have to be run more than
% once for every int file. One can start from "Work with data" and down.

addpath('C:\repo\lac-matlab-toolbox')

% Go to the folder location of this script
filePath = matlab.desktop.editor.getActiveFilename;
fileNameStartIndex = max(strfind(filePath, "\"));
scriptFolder = filePath(1:fileNameStartIndex);
cd(scriptFolder)
clear("filePath", "fileNameStartIndex")

% (Edit) Set name of .mat file folder save
saveFolderName = "matFiles";
% (Edit Set folder directory - Leave as <""> if you want folder in same location as this script
saveFolderPath = "";
% Ex: saveFolderPath = "C:\repo\mrotr_personal\"; (remember "\" at the end!)
% (Edit) Set file name of mat file
matFileName = "Baseline_fatdOff_14_16_18";



% Pull data from int file and save as .mat file
% ---------------------------------
% (Edit) Choose simulation names for the different simulations - is used
% for legends when plotting
% simNames = [
% 			"Frq = 0.01 Hz";
% 			"Frq = 0.02 Hz";
% 			"Frq = 0.03 Hz";
% 			"Frq = 0.04 Hz";
% 			"Frq = 0.05 Hz";
% 			"Frq = 0.06 Hz";
% 			"Frq = 0.07 Hz";
% 			"Frq = 0.08 Hz";
% 			"Frq = 0.09 Hz";
% 			"Frq = 0.1 Hz"
% 			];
simNames = [
			"14 m/s";
			"16 m/s";
			"18 m/s"
			];

% (Edit) The names of the .int files (w.o. ".int")
% intFileNames = [
% 				"SI_14_f0.01";
% 				"SI_14_f0.02";
% 				"SI_14_f0.03";
% 				"SI_14_f0.04";
% 				"SI_14_f0.05";
% 				"SI_14_f0.06";
% 				"SI_14_f0.07";
% 				"SI_14_f0.08";
% 				"SI_14_f0.09";
% 				"SI_14_f0.1"
% 			   ];
intFileNames = [
				"1114a001";
				"1116a001";
				"1118a001"
			   ];


% (Edit) Put the folder paths to the .int files here
% simFolders = [	
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\";
% 				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\"
% 			 ];

simDirArray = [
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\00_SimBaseline\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\01_SimBaseline_noturb\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\001_SimFATDparamChange\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\000_SimBaseline\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\001_SimParChngDefault\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\002_SimParChngDefault_noturb\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\004_SimParChngDefaultV2_2\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\003_Baseline_4\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\006_Baseline_6\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\"; ...
				"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\"
				];

simFolders = [	
				simDirArray(7);
				simDirArray(7);
				simDirArray(7)
			 ];
		 
% Directories i use:
% 1.  Baseline:					"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\00_SimBaseline\Loads\INT\"
% 2.  Baseline_noturb:			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\000_Baseline\01_SimBaseline_noturb\Loads\INT\"
% 3.  ParameterChange:			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\001_SimFATDparamChange\Loads\INT\"
% 4.  newCTR_baseline:			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\000_SimBaseline\Loads\INT\"
% 5.  newCTR_paramChange:		"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\001_SimParChngDefault\Loads\INT\"
% 6.  newCTR_parmChange_noturb: "h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\002_SimParChngDefault_noturb\Loads\INT\"
% 7.  newCTR_paramChangeV2:		"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\002_NewCTR\004_SimParChngDefaultV2_2\Loads\INT\"
% 8.  FrqSweep_baseline_4:		"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\003_Baseline_4\Loads\INT\"
% 9.  FrqSweep_baseline_6:		"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\006_Baseline_6\Loads\INT\"
% 10. FreqSweep_chng:			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\"
% 11. FreqSweep_chngV2:			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\003_SysIDFreqSweepSims\009_newSenCtr_parChngV2\Loads\INT\"


% (Edit) Choose Tmin, Tmax and write the .int file names (intFileNames)
Tmin = 0;			% [s] - Start time of sample extraction
Tmax = 2000;		% [s] - End time of sample extraction


% Pull the data from the .int files and store them in .mat file
for ii = 1:length(simFolders)
	% Save current folder and go to a simulation folder
	cd(simFolders(ii));
	% Pull the data from the .int file
	[GenInfo{ii}, Xdata{ii}, Ydata{ii}, ErrorString{ii}] = LAC.timetrace.int.readint...
		(strcat(intFileNames(ii), ".int"), 1, [], Tmin, Tmax);
	
	% Handle no .int files found in folder.
	if length(GenInfo{ii}) == 0
		str = sprintf("Error! No int files found in sim folder #%.0f!", ii);
		disp(str)
	end
end

% Go back to the script folder
cd(scriptFolder);
% Save data as .mat files in chosen location folder with chosen folder name
str = strcat(saveFolderPath, saveFolderName);
mkdir(str);
str = strcat(saveFolderPath, saveFolderName, "\", matFileName);
save(str, "GenInfo", "simNames", "simFolders", "Xdata", "Ydata");


%% Load and treat data
% ---------------------------------
clc; clear; close all;
% The .mat files only have to be generated once. Then they can just be
% loaded with this part of the matlab script.

% READ ME!: Write the folder 

% (Edit) Set path to matFiles folder
dirPath = "C:\Users\Mrotr\Git\Repos\CA9_Project\intFileMatlabAnalysis\matFiles";
% (Edit) Set name of the file to load
loadFileName = "Baseline_fatdOff_14_16_18";

str = strcat(dirPath, "\", loadFileName, ".mat");
load(str);
clear dirPath str
% clear dirPath loadFileName str

% Treat data
% ---------------------------------

% Init sensor arrays, names, and such
sensorSetupInit_senSetup1 % Older setup with fewer sensors
% sensorSetupInit_senSetup2



% Free wind, blade pitch, Rotor speed, Generator torque
% f = myfigplot(100, [senIdx.Vhfree senIdx.Pi1 senIdx.Omega senIdx.GenMom], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, xLimDef1, 0);
% figArray = [figArray f];
% figNameArray = [figNameArray strcat(setupPrefix, "VfreeToMgen.png")];



% Create frequency indexes for ffts
Ts = 0.04;				% Sampling period    
Fs = 1/Ts;				% Sampling frequency
for ii = 1:length(Ydata)
	L{ii} = length(Xdata{ii});	% Number of samples
	nf{ii} = Fs.*(0:(L{ii}/2))/L{ii};	% Frequency index
end

% Create ffts
for nn = 1:length(Ydata)
	Y = abs(fft(Ydata{nn}(:,sensorIDs)))/L{nn};
	sensorDataFFT{nn}(:,sensorIDs) = Y(1:((end+1)/2),:); % Only one half of fft (up to nyquist frequency)
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

figPlotSetup_tj02


%% Export figures
% ---------------------------------
figSaveDir = "C:\Users\Mrotr\Git\Repos\CA9_Project\intFileMatlabAnalysis\";
createNewFolder = 1;
% I set the name of the folder where the images are saved to the .mat file
% name:
folderName = strcat("Figures_", loadFileName);
resolution = 400;
myfigexport(figSaveDir, figArray, figNameArray, createNewFolder, folderName, resolution)





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

function f = myfigplot(figNum, wantedPlots, wantedSims, Xdata, sensorData, titles, ylabels, simNames, plottype, xlimits, ylimits)
	% Plot chosen data sets for comparison
	% Inputs: figNum, wantedPlots, wantedSims, Nsims, Xdata, sensorData, titles,
	% ylabels, simNames, plottype, xlimits, ylimits
	% figNum			: The number of the figure
	% wantedPlots		: Ex. [1 2] - Data from sensor 1 and 2
	% wantedSims		: Ex. [1 3] - Data from sim 1 and 3
	% Nsims				: The number of .int files which is used
	% Xdata				: The cell of Xdata (timeseries)
	% sensorData		: The cell of sensor data
	% titles			: An array of the titles relating to the chosen dataseries
	% ylabels			: An array of the y labels relating to the chosen dataseries
	% simNames			: An array of the simNames relating to the .int files
	% plottype			: 1 if timeseries, 0 if fft (sets xlabel)
	% xlimits			: ex. xlimits = [0 1]. if xlimits = 0 then it's not set
	% ylimits			: ex. ylimits = [0 100]. if ylimits = 0 then it's not set
	
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

		for nn = wantedSims
			plot(Xdata{nn}, sensorData{nn}(:,wantedPlots(ii)))
			hold on
		end
		hold off
		
		% Set limits if they are specified as an input other than 0
		if length(xlimits) > 1
			xlim(xlimits)
		end
		if length(ylimits) > 1
			ylim(ylimits)
		end

		title(titles(wantedPlots(ii)))
		xlabel(xlabelstr)
		ylabel(ylabels(wantedPlots(ii)))
		legend(simNames(wantedSims))
	end
	linkaxes(axs,'x');
	
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
	if createNewFolder == 1
		mkdir(saveDir, folderName);					% Create folder
% 		savePath = [saveDir '/' folderName];		% Save path for figures
		savePath = strcat(saveDir, "/", folderName);% Save path for figures
	else
		savePath = saveDir;						% Save path for figures
	end
	
	fileName = fileNames;
	
	for i=1:length(figures)
    	f = strcat(savePath, "\", fileName(i));
    	exportgraphics(figures(i), f,'Resolution', resolution);
	end

	
end