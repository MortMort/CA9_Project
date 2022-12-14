%Load extrapolation process

clear all
close all
clc

%% Beginning of editable part

SimPath     = ''; %Load Extrapolation folder (E.g. : "o:\VY\V1749600.107\IEC1B.001\LoadExtrapolation\")
SimPathDLC  = ''; %Root folder with NTM and ETM simulations (could be the same as SimPath)

PathDLC11   = strcat([SimPathDLC 'NTM\Loads\']); % Path to frequency file where 1.1 LC (or variants) are run.
PathDLC13   = strcat([SimPathDLC 'ETM\Loads\']); % Path to frequency file where 1.3 LC are run. Leave it blank if comparison to DLC1.3 extreme values is not required.

% Changing any of the options TurbineName, IDTag, NExt, NSeeds, EnableGravityPSF or MininumGravityPSF will generate two new mat files, name_ntm and name_etm
Options.VariantName = 'VXXX_HHXXX';         % Variant name, e.g. V150_HH105
Options.IDTag   = '';                       % Optional string that is added as suffix to the name of the mat files and reports. Useful when using different sets of simulations, e.g. '_FirstSet', '_SecondSet', etc.
Options.NExt    = 1;                        % Number of Extremes per time series (block maxima method) - Default: 6. Usually 1 or 6.
Options.NSeeds  = 60;                       % Example: 60 - The number of seeds is not used while reading the STA data
Options.EnableGravityPSF    = 0;            % 0: Gravity correction disabled; 1: Gravity correction enabled
Options.MininumGravityPSF   = 1.1;          % PLF factor for gravity correction (1.1 gives maximum benefit, see guideline)

% Changing any of the following options will not generate two new mat files. However, an update of the Options structure in the two mat files name_ntm and name_etm will be carried out and a warning will be displayed
Options.Legend              = 'VXXX HHXXX'; % Legend which will be used when plotting the results
Options.Edgefilter          = 0;            % Present in the code for edgewise vibrations filtering, any reason for that?
Options.TailFit             = [0.20];       % [0.2 ... n] Percentage of the tail where a fitting function is fitted. Applies only to single distribution fitting.
Options.TailFitIgnore       = [0.00];       % [0.00 .. n] Percentage of the tail which is ignored when fitting a function to the tail (usually 0). Applies only to single distribution fitting.
Options.HighlightFitting    = 1;            % 1: points used for fitting the probability distribution are highlighted in red in plots. Only valid if single distribution fitting.
Options.PlotDLC13           = 2;            % 0: does not plot 1.3load, 1: plots 1.3 load for the given blade, 2 [default]: plot max of 1.3 loads from the 3 blades
Options.Plots               = 1;            % 0: does not plot results, 1: plots the results
Options.DNV                 = 0;            % 0 first (all distributions), then 1 when generating results for DNV (plots and reports are adapted to DNV requirements)
Options.SaveFigs            = 1;            % if 1, figures are saved in a separate folder
Options.Fitting             = 0;            % 0: Single distribution fitting, 1: Double distribution fitting - Default: 1
Options.DoubleFamily        = 'W2';         % If double distribution fitting is chosen, specify its family: N = normal, LN = lognormal, W2 = 2-parameter Weibull (default choice), G = Gumbel
Options.OutliersConfidence  = 0.00;         % replaces Outliers option (further explanation pending) - Default: 0

DLC13All.Path               = '';           % For seeds number analysis in DLC13. " '' " means no analysis is done here
DLC13All.SeedStart          = 12;

%% End of editable part

LoadExtrapolation_mainfunc(SimPath, PathDLC11, PathDLC13, DLC13All, Options)
