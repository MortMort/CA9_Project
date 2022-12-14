clear all; close all; clc;

% Before carrying out a load extrapolation, read 0039-4123 for load extrapolation guidelines, and 0039-4124 for user manual of this script.

i = 1;
DLC11File{i}   = 'NTM_'; i=i+1; % Fill in the name of the .mat file which contain the extremes of the normal production time series (generated with LoadExt_LoadExtremesRun.m)
DLC13File      = 'ETM_';        % Fill in the name of the .mat file which contain the extremes of the etm DLC time series (generated with LoadExt_LoadExtremesRun.m)

Sensors = [                 % Do not change the first 2 columns (sensor name and family). Only change the last 3 columns (see manual).
    {'-Mx11r'} 1 1 0 0; % Family, logn, gbl, wbl3
    {'-Mx21r'} 1 1 0 0;
    {'-Mx31r'} 1 1 0 0;
    {'My11r'}  2 0 1 0;
    {'My21r'}  2 0 1 0;
    {'My31r'}  2 0 1 0;
    {'uy1'}    3 1 0 0;
    {'uy2'}    3 1 0 0;
    {'uy3'}    3 1 0 0;
    {'ux1'}    4 1 0 0;
    {'ux2'}    4 1 0 0;
    {'ux3'}    4 1 0 0;
    {'bldefl'} 5 1 0 0];

Options.OutFile             = 'Report_';    % Name of the output file with results from the load extrapolation
Options.TailFit             = [0.15];       % Percentage of the tail where a fitting function is fitted
Options.TailFitIgnore       = [0];          % Percentage of the tail which is ignored when fitting a function to the tail (usually 0)
Options.HighlightFitting    = 1;            % 1: points used for fitting the probability distribution are highlighted in red in plots. Only valid if one fitting.
Options.PlotDLC13           = 0;            % 0: does not plot 1.3load, 1: plots 1.3 load for the given blade, 2: plot max of 1.3 loads from the 3 blades
Options.Plots               = 0;            % 0: does not plot results, 1: plots the results
Options.DNV                 = 1;            % should be 1 when generating results for DNV (plots and reports are adapted to DNV requirements)
Options.SaveFigs            = 0;            % if 1, figures are saved in a separate folder

colors = {'k','r','b','g','m','c'};         % colors for plots. 

%% This part should not be changed unless a special investigation is required (check manual)
DLC13All.Path = '';
DLC13All.SeedStart   = 12;


%% DO NOT CHANGE THIS PART
%% Run the script
LAC.scripts.LoadExtrapolation.LoadExtrapolationScript(DLC11File,DLC13File,Options,Sensors,DLC13All,colors);