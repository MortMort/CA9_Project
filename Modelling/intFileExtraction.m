%% Pull data for simulations
% -------------------------------
% The following script is dedicatd to pulling fata from .int files to use
% for inputs to a time simulation.


% lax toolbox used for extracting data from .int files
addpath('C:\repo\lac-matlab-toolbox')

% (Edit) Ends up being the legend of the plots
simNames = [
			"fatd off, W = 16 m/s"
			"fatd off,lowturb W = 16 m/s"
			];

% (Edit) The names of the .int files (w.o. ".int")
intFileNames = [
				"1116a001"
				"1116a001"
			   ];

% (Edit) Put the folder paths to the .int files here
simDirArray = [
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\000_Baseline\Loads\INT\"
			"h:\Offshore_TEMP\USERS\MROTR\Investigations\001_DLC11_V164_8MW\005_Baseline2\001_lowturb\Loads\INT\"
				];

simFolders = [	
				simDirArray(1)
				simDirArray(2)
			 ];	
			
% (Edit) Choose Tmin, Tmax and write the .int file names (intFileNames)
Tmin = 0;		% [s] - Start time of sample extraction
Tmax = 1000;		% [s] - End time of sample extraction

% Current directory:
currentDir = pwd;

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


% Go back to original dir
cd(currentDir);

% Save simulation data
save('intFileData.mat', "GenInfo", "Xdata", "Ydata", "senIdx");


% Plotting
% ---------------------------------------


% An initialization script which defines a bunch of arrays with sensor
% labels and such:
run C:\repo\mrotr_personal\intFileMatlabAnalysis\sensorSetupInit

% Plotted sensors:
% - Generator speed reference
% - Power reference
% - FLC Pitch position reference
wantedSims = [1 2];
f = myfigplot(100, [senIdx.pnt413 senIdx.pfo017, senIdx.pft105], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, 0, 0);
% For exporting figures:
% figArray = [figArray f]; 
% figNameArray = [figNameArray strcat(setupPrefix, "figurename.png")]; %
wantedSims = [1 2];
f = myfigplot(101, [senIdx.Vhfree], wantedSims, Xdata, Ydata, titleArray, ylabelArray, simNames, 1, 0, 0);
% For exporting figures:
% figArray = [figArray f]; 
% figNameArray = [figNameArray strcat(setupPrefix, "figurename.png")]; %


% Simulation setup
% -----------------
fs = 25;	% Sample frequencye
Ts = 1/fs;	% Sample period
nT = (0:length(Xdata{1})-1) * Ts;	% Time index


% Timetable for data input to simulink
% -----------------

%
vfree = Ydata{1}(:,senIdx.Vhfree);
tt_vfree = timetable(seconds(Xdata{1,1}), vfree);

