%% Main script to run a Master Model down-selection (without GUI)
%
% Inputs:   list of paths to postloads folders in the database
% Outputs:  list of down-selected models and respective load factors

clear all; close all; fclose all; clc;

%% Inputs
% pathlist, tolerance, approach, vld.

% Pathlist containing PostLoads folders of interest in the database
PathList = 'c:\Repo\lac-matlab-toolbox\+LAC\+scripts\+MasterModel\+test\Pathlist.txt';

% Tolerance threshold used in the algorithm (suggested: [0.01 - 0.05])
tolerance = 0.01;

% Approach definition
% 0 (default) - uses normal Postloads folder
% 1 - uses _ChangedDLC14 for MxMBf and tower
% 2 - uses _ChangedDLC14 for all except blades and hub
approach = 0;

% Read VLD proxies from DRTload.txt (new method). Alternatively the script uses legacy scripts to calculate the proxies (legacy).
useVLDcodec = true; % false/true

%% Checks
% Check the list of variants provided (code will consider datapaths with content available)  
[path_info,path_funcs] = LAC.scripts.MasterModel.tools.PathInfo(PathList);
disp('Status of data availability in paths provided by user')
disp(' ')
disp(path_info)

% List of paths to consider
database_variants = path_info.Availability;
database_paths = path_funcs.path(database_variants);

% GRS check
refsys = LAC.scripts.MasterModel.tools.detectRefSys(path_info);

%% Loading data and running algorithm
[loadData, sensors] = LAC.scripts.MasterModel.tools.get_data_DRT_TWR(database_paths,refsys,approach,useVLDcodec);

Solution = LAC.scripts.MasterModel.choose_turbines_glpk(loadData,tolerance,false);
Solution.sensors = sensors;
Solution.varPaths = path_info.Paths(Solution.choices);

%% Outputs
% output to excel file with summary of everything ...
outDir=dir(PathList);
fileIdx=size(outDir,1)-1;
timerun=datetime('now');
dateref=datestr(timerun,'yyyymmdd_HHMM');
fileName=sprintf('%03d_MasterModelSummary_%s.xls',fileIdx,dateref);

excelStatus = LAC.scripts.MasterModel.tools.outToExcel(fileName,outDir.folder,database_paths,loadData,Solution);
if excelStatus == 1
    fprintf('Summary of down-selection available in %s\n',[outDir.folder filesep fileName])
else
    disp('An error occured when writing the summary to the excel file');
end