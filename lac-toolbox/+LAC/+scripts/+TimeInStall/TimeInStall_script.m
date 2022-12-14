%% Time in Stall script
% Calculates the time in stall percentage for DLC 1.1 cases. 
% This version can be run automatically as a hook in FAT1 by creating a folder called 'MainHooks'
% in the FAT1 directory, copying this script into it and also adding a file called 
% 'VtsAllSimDistributed_PostHook.bat' which contains the following text:
% "C:\Program Files\MATLAB\R2017b\bin\"Matlab.exe -noFigureWindows -r "addpath('..\MainHooks'); TimeInStall; exit;"
% or if the default Matlab version is compatable with the TimeInStall script:
% matlab -noFigureWindows -r "addpath('..\MainHooks'); TimeInStall; exit;"
%
% The output folder will be located in the Loads folder if the script is run automatically. 
% If the script does not run, then it is possible to run the TimeInStall.m
% from the MainHooks folder without modifications. In this case the output
% folder will be in the MainHooks folder
% 
% Last revision: 30-Oct-2018, MAFBE

clear all; close all; clc;
import LAC.scripts.TimeInStall.*
%% Inputs %%

% Path to text file with a list of paths to evaluate (not currently functional)
%pathlist = 'h:\3MW\MK3\Investigations\411_Mk3E\V150\002_BladeDesign\L03\A03\TimeInStall\pathlist.txt'; %(AoA output should be included in all blade sections)
path = '..\Loads\'
                  % If a relative path, starting at the current directory, 
                  % then start with .\
                  % If a relative path, starting one directory higher than
                  % the current directory, then start with ..\
% Stall angles for different AOA
%LS.StallTR = []; % Thickness Ratio at which the Stall AoA are input in LS{i}.NveStallAoA and LS{i}.PveStallAoA.
%LS.NveStallAoA = []; Negative stall points
%LS.PveStallAoA = []; Positive stall points
LS.LC   = '11';          % Investigation will be done only on load cases starting with LS{i}.LC. For study of min, mean and max AoA, LS{i}.LC has to contain 2 and only 2 digits.
LS.StallMethod = 'auto';    % 'auto': stall AoA = point where slope of Cl curve reaches LS.gradientStallLimit
                             % 'inpTR': stall AoA are input for each T/C in profile files in following variables LS{i}.NveStallAoA and LS{i}.PveStallAoA

LS.gradientStallLimit = 0.05; % This value should not be changed. Stall is reached when dCl/dAoA is below this value. The gradient is defned by the Aero team. 

% Time in stall limits along the blade length to be plot against the time in stall results
LS.StallLim_r = 0:0.05:1; % Normalized blade radial location
LS.PosStallLim = [100 100 100 100 50 50 10 10 10 5 5 3 3 3 3 2 1 1 1 1 1]./100; % Allowed fraction of time in positive stall
LS.NegStallLim = [NaN*ones(1,10) 5*ones(1,11)]./100; % Allowed fraction of time in negative stall

% Definition of plots with min, mean and max AoA, at a given WS and a given
% Radius. Format is [WS1 Radius1; WS2 Radius2 etc.]. For example [10 0.1;
% 10 0.8] will output plots at 10m/s wind speed, 10% and 80% radius. Leave
% empty if this output not required.
Outputs.MinMeanMaxAoA = [10 0.8; 18 0.8];

% Make plots of Cl & Cd curves incl stall points. 1: Enable plots, 0: Disable plots
Outputs.StallPoint = 1; % 

% Definition of plots and txt files for time in stall, at a given wind
% speed. Format is [WS1 WS2 etc.]. Leave empty if this output is not
% required.
Outputs.TimeInStall = [4 6 8 10 12 14 16 18];

Setup.Plot = 1;             % 1 of you want to plot the time in stall results, 0 if not.
Setup.AoASensor = 'AoA2';   % Sensor name, should be AoA1, AoA2 or AoA3 depending on which blade you want to post process
Setup.WSPrecision = 0.5;    % Wind speed precision

%% End of inputs

% Initiate.
output_folder = fullfile(cd,'output');

% % Read all lines.
% filename = fullfile(pathlist);
% Fid = fopen(filename);
% Lines = textscan(Fid,'%s','Delimiter','\n');
% loads_folder_list = Lines{1};
% fclose(Fid);

if strcmp(path(1:2),'.\') % If relative path down
    path = [pwd path(2:end)];
end
if strcmp(path(1:3),'..\') % If relative path one up
    folder = pwd;
    i   = strfind(folder,filesep);
    path = [folder(1:i(end)-1) path(3:end)];
end
if ~strcmp(path(end),'\') && ~strcmp(path(end),'/') % Make end with \
    path = [path '\'];
end
loads_folder_list{1}=path;

%%
% Loop.
for iVariant=1:length(loads_folder_list)

    % Set local.
%     loads_folder = loads_folder_list{iVariant};
%     int_folder = fullfile(loads_folder, 'INT');
    
    LS.Path = path;
    LS.Name = num2str(iVariant);
    LS.OutPutFolder = fullfile(output_folder,'\',LS.Name,'\');
    if exist(LS.OutPutFolder,'dir') 
        disp(['Old results moved to: ' LS.OutPutFolder(1:end-1) '_old'])
        movefile(LS.OutPutFolder(1:end-1),[LS.OutPutFolder(1:end-1) '_old'])
    end
    mkdir(LS.OutPutFolder)

    fBlade_CheckStall(LS, Outputs, Setup);
    %result(LS.OutPutFolder);
    
    close all;
%     save('w:\2mw\Mk11B\TR2_001\012_time_in_stall\matlab_processing\output\V116_IECS_HH110_50HZ\','123.png');
end

% Extract values and save to new text-file
for iFiles = 1:length(Outputs.TimeInStall)
    
    path = [LS.OutPutFolder,'\TimeInStall_WS_',num2str(round(Outputs.TimeInStall(iFiles)/Setup.WSPrecision)*Setup.WSPrecision),'_DLC_',LS.LC,'.txt'];
    A10 = readtable(path);

    Index50(iFiles) = find(A10.Var1>0.50,1);
    Index70(iFiles) = find(A10.Var1>0.70,1);

    PosStalLast30(iFiles) = 100*max(A10.Var2(Index70(iFiles):end));
    PosStalLast50(iFiles) = 100*max(A10.Var2(Index50(iFiles):end));
    if round(Outputs.TimeInStall(iFiles)/Setup.WSPrecision)*Setup.WSPrecision < 16
        NegStall(iFiles) = 0;
    else
        NegStall(iFiles)      = 100*max(A10.Var3);
    end
        
end

Table = table(Outputs.TimeInStall', round(PosStalLast30',3), round(PosStalLast50',3), round(NegStall',3));
Table.Properties.VariableNames = {'WindSpeed','PosStallLast30','PosStallLast50','NegStall'};

pathRes = [LS.OutPutFolder,'\Results','.txt'];
writetable(Table,pathRes,'Delimiter','tab');

fid = fopen(pathRes, 'a');
fprintf(fid, '\nValues are time in stall in percent.\n \nRequirements are < 1 %% time in stall for Pos and <5 %% for Neg.\n');
fclose(fid);