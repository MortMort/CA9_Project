clear all; close all; clc;

% Before carrying out a load extrapolation, read 0039-4123 for load extrapolation guidelines, and 0039-4124 for user manual of this script.

PathDLC11 = ''; % Path to frequency file where 1.1 LC (or variants) are run.
PathDLC13 = ''; % Path to frequency file where 1.3 LC are run. Leave it blank if comparison to DLC1.3 extreme values is not required.

Options.SaveDLC11       = 'NTM_';   % Name of the file where extremes from normal production time series are saved 
Options.SaveDLC13       = 'ETM_';   % Name of the file where extremes from etm DLC time series are saved 
Options.Legend          = '';       % Legend which will be used when plotting the results (for example 'V100 Mk10B')
Options.NExt            = 1;        % Number of Extremes per time series (block maxima method). Usually is 1 or 6.

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
    {'ux1'}    4 0 1 0;
    {'ux2'}    4 0 1 0;
    {'ux3'}    4 0 1 0;
    {'bldefl'} 5 1 0 0];


%% DO NOT CHANGE THE CODE AFTER THIS LINE

% Load extremes and calculate non exceedance probability

[DLC13,Frq,Extremes,ExtremesSorted,NonExceedanceProb,flag] = LAC.scripts.LoadExtrapolation.LoadExtrapolationLoadExtremes(PathDLC11,PathDLC13,Options,Sensors);
if (~strcmpi(Options.SaveDLC11,'')) && (flag(1)==1)
    save(Options.SaveDLC11,'ExtremesSorted','NonExceedanceProb','PathDLC11','Options','Sensors','Frq','Extremes');
end
if (~strcmpi(Options.SaveDLC11,'')) && (flag(2)==1)
    save(Options.SaveDLC13,'DLC13','PathDLC13','Options','Sensors');
end


