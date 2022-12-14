function LoadExtrapolation_mainfunc(SimPath, PathDLC11, PathDLC13, DLC13All, Options)
colors = {'k','r','b','g','m','c'};         % define colors for plots. 

%% Check Inputs
switch nargin
    case 4 % all inputs are introduced apart from the Options structure
        optionflag = 1;
    case 3 % all fields are introduced apart from the Options and DLC13All structure
        optionflag = 1;
        DLC13flag  = 1;
    otherwise
        optionflag = 0;
        DLC13flag  = 0;        
end

% Set default Options
if optionflag == 1
    fprintf('\n\n User defined options are not introduced. Load extrapolation will be run with default settings: \n')
    
    Options.IDTag               = 'DefaultSettings';    % Optional string that is added as suffix to the name of the mat files and reports. Useful when using different sets of simulations, e.g. '_FirstSet', '_SecondSet', etc.
    Options.NExt                = 6;                    % Number of Extremes per time series (block maxima method) - Default: 1. Usually 1 or 6.
    fprintf('\n ... %d extremes are being considered per time-trace.', Options.NExt)
    Options.NSeeds              = 0;                    % Example: 60
    Options.EnableGravityPSF    = 0;                    % 0: Gravity correction disabled; 1: Gravity correction enabled
    fprintf('\n ... Gravity correction is disabled.')
    Options.MininumGravityPSF   = 1.1;                  % PLF factor for gravity correction (1.1 gives maximum benefit, see guideline)
    Options.Legend              = 'DefaultVariant';     % Legend which will be used when plotting the results
    Options.Edgefilter          = 0;                    % Present in the code for edgewise vibrations filtering, any reason for that?
    Options.TailFit             = [0.20];               % [0.2 ... n] Percentage of the tail where a fitting function is fitted. Applies only to single distribution fitting.
    Options.TailFitIgnore       = [0.00];               % [0.00 .. n] Percentage of the tail which is ignored when fitting a function to the tail (usually 0). Applies only to single distribution fitting.
    Options.HighlightFitting    = 1;                    % 1: points used for fitting the probability distribution are highlighted in red in plots. Only valid if single distribution fitting.
    Options.PlotDLC13           = 2;                    % 0: does not plot 1.3load, 1: plots 1.3 load for the given blade, 2 [default]: plot max of 1.3 loads from the 3 blades
    Options.Plots               = 1;                    % 0: does not plot results, 1: plots the results
    Options.DNV                 = 0;                    % 0 first (all distributions), then 1 when generating results for DNV (plots and reports are adapted to DNV requirements)
    Options.SaveFigs            = 1;                    % if 1, figures are saved in a separate folder
    Options.Fitting             = 1;                    % 0: Single distribution fitting, 1: Double distribution fitting
    fprintf('\n ... Double distribution fitting with 2-parameter Weibull distribution is selected.')
    Options.DoubleFamily        = 'W2';                 % If double distribution fitting is chosen, specify its family: N = normal, LN = lognormal, W2 = 2-parameter Weibull (default choice), G = Gumbel
    Options.OutliersConfidence  = 0.05;                 % replaces Outliers option (further explanation pending)  
    fprintf('\n ... Outliers are removed considering a confidence interval of %1.03f.', Options.OutliersConfidence)
end    

% Set all DLC13 seeds
if DLC13flag == 1
    fprintf('\n User defined DLC13All is not introduced. Load extrapolation will be run considering all seeds.\n\n')
    DLC13All.Path               = '';           % For seeds number analysis in DLC13. " '' " means no analysis is done here
    DLC13All.SeedStart          = 12;
end

if Options.Fitting == 1
   warning('Double distribution method requires the Optimisation Toolbox! Please check license availability.')
end

%% Attribute fitting functions to sensors
if ~exist(SimPath, 'dir')
    mkdir(SimPath)
end

if Options.Fitting == 0
    Sensors = [             % Do not change the first 2 columns (sensor name and family). Only change the last 3 columns (see manual).
        {'-Mx11r'} 1 1 1 1; % Family, if single distribution: logn, gbl, wbl3
        {'-Mx21r'} 1 1 1 1;
        {'-Mx31r'} 1 1 1 1;
        {'My11r'}  2 1 1 1;
        {'My21r'}  2 1 1 1;
        {'My31r'}  2 1 1 1;
        {'uy1'}    3 1 1 1;
        {'uy2'}    3 1 1 1;
        {'uy3'}    3 1 1 1;
        {'ux1'}    4 1 1 1;
        {'ux2'}    4 1 1 1;
        {'ux3'}    4 1 1 1;
        {'bldefl'} 5 1 1 1;
        {'My11r'}  6 1 1 1;
        {'My21r'}  6 1 1 1;
        {'My31r'}  6 1 1 1;];
else
    Sensors = [                 % Do not change the first 2 columns (sensor name and family). Only change the last 5 columns (see manual).
        {'-Mx11r'} 1 1 1 1 1 1; % Type, if double distribution: fit and aggregate single distribution, sum of distributions, joint distribution; 
        {'-Mx21r'} 1 1 1 1 1 1; % aggregate amd fit sum of distributions, joint distribution
        {'-Mx31r'} 1 1 1 1 1 1;
        {'My11r'}  2 1 1 1 1 1;
        {'My21r'}  2 1 1 1 1 1;
        {'My31r'}  2 1 1 1 1 1;
        {'uy1'}    3 1 1 1 1 1;
        {'uy2'}    3 1 1 1 1 1;
        {'uy3'}    3 1 1 1 1 1;
        {'ux1'}    4 1 1 1 1 1;
        {'ux2'}    4 1 1 1 1 1;
        {'ux3'}    4 1 1 1 1 1;
        {'bldefl'} 5 1 1 1 1 1;
        {'My11r'}  6 1 1 1 1 1;
        {'My21r'}  6 1 1 1 1 1;
        {'My31r'}  6 1 1 1 1 1;];
end

%% Check NTM and ETM matrices
% Do not change name_ntm and name_etm, as they are used for checks in the LoadExtrapolationExtremes script!!
switch optionflag 
    case 0
        Options.NameStr             = [Options.VariantName '_' num2str(Options.NExt) 'xtrem_' num2str(Options.NSeeds) 'seeds_gravityPSF_'];
    case 1
        Options.NameStr             = [num2str(Options.NExt) 'xtrem_gravityPSF_'];
end

name_ntm                    = ['NTM_' Options.NameStr];
if Options.EnableGravityPSF == 1
     Options.NameStr         = [Options.NameStr num2str(Options.MininumGravityPSF)];
     name_ntm                = [name_ntm '1.1']; %NTM PLF factor is hardcoded to 1.1
     else
     Options.NameStr         = [Options.NameStr 'off'];
     name_ntm                = [name_ntm 'off'];
end
if isempty(Options.IDTag)
    name_ntm                = [name_ntm '.mat']; % Name given to the output mat file for DLC11
    name_etm                = ['ETM_' Options.NameStr '.mat']; % Name given to the output mat file for DLC13
    Options.OutFilemax      = ['Report_' Options.NameStr]; % Name of the output file with results from the load extrapolation
    Options.OutFileDNV      = ['Report_' Options.NameStr '_DNV']; % Name of the output file for DNV with results from the load extrapolation
else
    name_ntm                = [name_ntm '_' Options.IDTag '.mat']; % Name given to the output mat file for DLC11
    name_etm                = ['ETM_' Options.NameStr '_' Options.IDTag '.mat']; % Name given to the output mat file for DLC13
    Options.OutFilemax      = ['Report_' Options.NameStr '_' Options.IDTag]; % Name of the output file with results from the load extrapolation
    Options.OutFileDNV      = ['Report_' Options.NameStr '_' Options.IDTag '_DNV']; % Name of the output file for DNV with results from the load extrapolation   
end

Options.SaveDLC11           = name_ntm;     % Name of the file where extremes from normal production time series are saved 
Options.SaveDLC13           = name_etm;     % Name of the file where extremes from etm DLC time series are saved 

cd (SimPath)
mat_Check_NTM = 0; %Check for NTM mat file
mat_Check_ETM = 0; %Check for ETM mat file
if exist(Options.SaveDLC11,'file') %Stored NTM mat file has the correct name
    tmp_NTM = load(Options.SaveDLC11);
    if isequaln(Options,tmp_NTM.Options)
        mat_Check_NTM = 1; %Stored NTM mat file has the same Options struct as the one set in the current run
    elseif Options.SaveDLC11 == tmp_NTM.Options.SaveDLC11
        mat_Check_NTM = 2; %Stored NTM mat file doesn't have the same Options struct as the one set in the current run
    end
end
if exist(Options.SaveDLC13,'file')
    tmp_ETM = load(Options.SaveDLC13);
    if isequaln(Options,tmp_ETM.Options)
        mat_Check_ETM = 1;
    elseif Options.SaveDLC11 == tmp_NTM.Options.SaveDLC11
        mat_Check_ETM = 2;
    end
end
if (mat_Check_NTM ~= 1) || (mat_Check_ETM ~= 1) %Either any of the two mat files do not exist, or their Options struct doesn't match the one in the urrent run
    [DLC13,Frq,Extremes,ExtremesSorted,NonExceedanceProb,flag] = LAC.scripts.LoadExtrapolation.LoadExtrapolationLoadExtremes(SimPath,PathDLC11,PathDLC13,Options,Sensors,mat_Check_NTM,mat_Check_ETM);
    if (~strcmpi(Options.SaveDLC11,'')) && (flag(1)==1) %A new NTM mat file was generated
        fprintf('DLC 11 extremes will be saved in: \n %s \n',fullfile(SimPath,Options.SaveDLC11))
        save(Options.SaveDLC11,'ExtremesSorted','NonExceedanceProb','PathDLC11','Options','Sensors','Frq','Extremes');
    else %A new NTM mat file was not generated, but the Options struct was updated
        fprintf('%s loaded from: \n %s \n',Options.SaveDLC11,SimPath)
        fprintf('WARNING: Options stored in the mat file will be updated, because they do NOT match those set in the current load extrapolation \n')
        save(Options.SaveDLC11,'Options','-append')
    end
    if (~strcmpi(Options.SaveDLC13,'')) && (flag(2)==1)
        fprintf('DLC 13 extremes will be saved in: \n %s \n',fullfile(SimPath,Options.SaveDLC13))
        save(Options.SaveDLC13,'DLC13','PathDLC13','Options','Sensors');
    else
        fprintf('%s loaded from: \n %s \n', Options.SaveDLC13, SimPath)
        fprintf('WARNING: Options stored in the mat file will be updated, because they do NOT match those set in the current load extrapolation \n')
        save(Options.SaveDLC13,'Options','-append')
    end
else
      fprintf('%s loaded from: \n %s \n', Options.SaveDLC13, SimPath)
end 
warning('Warning: PLF of DLC 1.3 is hardcoded to 1.35! Please manually adjust this if a different PLF is to be considered.')

%% Fitting Distributions
% Standard plots
if Options.DNV == 0
        i = 1;
        DLC11File{i}   = strcat([SimPath Options.SaveDLC11]); i=i+1; % Fill in the name of the .mat file which contain the extremes of the normal production time series (generated with LoadExt_LoadExtremesRun.m)
        DLC13File      = strcat([SimPath Options.SaveDLC13]);        % Fill in the name of the .mat file which contain the extremes of the etm DLC time series (generated with LoadExt_LoadExtremesRun.m)
        Options.OutFile = Options.OutFilemax;
        if Options.Fitting == 0
            [DLC11] = LAC.scripts.LoadExtrapolation.LoadExtrapolationSingleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors);
        elseif Options.Fitting == 1
            [DLC11] = LAC.scripts.LoadExtrapolation.LoadExtrapolationDoubleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors);
        end
        
% Generate plots formatted for report to DNV        
elseif Options.DNV == 1
        i = 1;
        DLC11File{1}   = strcat([SimPath Options.SaveDLC11]); i=i+1; % Fill in the name of the .mat file which contain the extremes of the normal production time series (generated with LoadExt_LoadExtremesRun.m)
        DLC13File      = strcat([SimPath Options.SaveDLC13]);        % Fill in the name of the .mat file which contain the extremes of the etm DLC time series (generated with LoadExt_LoadExtremesRun.m)

        if Options.Fitting == 0
            prompt = ['Please enter which distribution family you would like to use for Mx (1: logn; 2: Gbl; 3: Wbl): '];
            x1 = input(prompt);     
            prompt = ['Please enter which distribution family you would like to use for My (1: logn; 2: Gbl; 3: Wbl): '];
            x2 = input(prompt);         
            prompt = ['Please enter which distribution family you would like to use for Uy (1: logn; 2: Gbl; 3: Wbl): '];
            x3 = input(prompt);       
            prompt = ['Please enter which distribution family you would like to use for Ux (1: logn; 2: Gbl; 3: Wbl): '];
            x4 = input(prompt);       
            prompt = ['Please enter which distribution family you would like to use for blddfl (1: logn; 2: Gbl; 3: Wbl): '];
            x5 = input(prompt);               
            prompt = ['Please enter which distribution family you would like to use for -My (1: logn; 2: Gbl; 3: Wbl): '];       
            x6 = input(prompt);
            
            zer         = zeros(3,3);
            Mxsr        = zer;
            Mxsr(:,x1)  = 1;
            Mysr        = zer;
            Mysr(:,x2)  = 1;
            Uysr        = zer;
            Uysr(:,x3)  = 1;
            Uxsr        = zer;
            Uxsr(:,x4)  = 1;        
            Bldsr       = zer(1,:);
            Bldsr(:,x5) = 1;      
            Mysr_neg    = zer;
            Mysr_neg(:,x6)  = 1;

            Sensors = [                               % Do not change the first 2 columns (sensor name and family). Only change the last 3 columns (see manual).
                {'-Mx11r'} 1 Mxsr(1) Mxsr(4) Mxsr(7); % Family, if single distribution: logn, gbl, wbl3
                {'-Mx21r'} 1 Mxsr(2) Mxsr(5) Mxsr(8);
                {'-Mx31r'} 1 Mxsr(3) Mxsr(6) Mxsr(9);
                {'My11r'}  2 Mysr(1) Mysr(4) Mysr(7);
                {'My21r'}  2 Mysr(2) Mysr(5) Mysr(8);
                {'My31r'}  2 Mysr(3) Mysr(6) Mysr(9);
                {'uy1'}    3 Uysr(1) Uysr(4) Uysr(7);
                {'uy2'}    3 Uysr(2) Uysr(5) Uysr(8);
                {'uy3'}    3 Uysr(3) Uysr(6) Uysr(9);
                {'ux1'}    4 Uxsr(1) Uxsr(4) Uxsr(7);
                {'ux2'}    4 Uxsr(2) Uxsr(5) Uxsr(8);
                {'ux3'}    4 Uxsr(3) Uxsr(6) Uxsr(9);
                {'bldefl'} 5 Bldsr(1) Bldsr(2) Bldsr(3);
                {'My11r'}  6 Mysr_neg(1) Mysr_neg(4) Mysr_neg(7);
                {'My21r'}  6 Mysr_neg(2) Mysr_neg(5) Mysr_neg(8);
                {'My31r'}  6 Mysr_neg(3) Mysr_neg(6) Mysr_neg(9);];
        
        elseif Options.Fitting == 1 % Manual choice of distribution type disabled when DNV option is selected and double distribution is run
%             prompt = ['Please enter which distribution type you would like to use for Mx\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x1 = input(prompt);     
%             prompt = ['Please enter which distribution type you would like to use for My\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x2 = input(prompt);         
%             prompt = ['Please enter which distribution type you would like to use for Uy\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x3 = input(prompt);       
%             prompt = ['Please enter which distribution type you would like to use for Ux\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x4 = input(prompt);       
%             prompt = ['Please enter which distribution type you would like to use for blddfl\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x5 = input(prompt);               
%             prompt = ['Please enter which distribution type you would like to use for -My\n'...
%                 '(1: fit and aggregate single; 2: fit and aggregate sum; 3: fit and aggregate joint;\n'...
%                 ' 4 aggregate and fit sum; 5: aggregate and fit joint): '];
%             x6 = input(prompt);
%             
%             zer         = zeros(3,5);
%             Mxsr        = zer;
%             Mxsr(:,x1)  = 1;
%             Mysr        = zer;
%             Mysr(:,x2)  = 1;
%             Uysr        = zer;
%             Uysr(:,x3)  = 1;
%             Uxsr        = zer;
%             Uxsr(:,x4)  = 1;        
%             Bldsr       = zer(1,:);
%             Bldsr(:,x5) = 1;      
%             Mysr_neg    = zer;
%             Mysr_neg(:,x6)  = 1;
% 
%             Sensors = [                                                 % Do not change the first 2 columns (sensor name and family). Only change the last 3 columns (see manual).
%                 {'-Mx11r'} 1 Mxsr(1) Mxsr(4) Mxsr(7) Mxsr(10) Mxsr(13); % Type, if double distribution: fit and aggregate single distribution, sum of distributions, joint distribution;
%                 {'-Mx21r'} 1 Mxsr(2) Mxsr(5) Mxsr(8) Mxsr(11) Mxsr(14); % aggregate amd fit sum of distributions, joint distribution
%                 {'-Mx31r'} 1 Mxsr(3) Mxsr(6) Mxsr(9) Mxsr(12) Mxsr(15);
%                 {'My11r'}  2 Mysr(1) Mysr(4) Mysr(7) Mysr(10) Mysr(13);
%                 {'My21r'}  2 Mysr(2) Mysr(5) Mysr(8) Mysr(11) Mysr(14);
%                 {'My31r'}  2 Mysr(3) Mysr(6) Mysr(9) Mysr(12) Mysr(15);
%                 {'uy1'}    3 Uysr(1) Uysr(4) Uysr(7) Uysr(10) Uysr(13);
%                 {'uy2'}    3 Uysr(2) Uysr(5) Uysr(8) Uysr(11) Uysr(14);
%                 {'uy3'}    3 Uysr(3) Uysr(6) Uysr(9) Uysr(12) Uysr(15);
%                 {'ux1'}    4 Uxsr(1) Uxsr(4) Uxsr(7) Uxsr(10) Uxsr(13);
%                 {'ux2'}    4 Uxsr(2) Uxsr(5) Uxsr(8) Uxsr(11) Uxsr(14);
%                 {'ux3'}    4 Uxsr(3) Uxsr(6) Uxsr(9) Uxsr(12) Uxsr(15);
%                 {'bldefl'} 5 Bldsr(1) Bldsr(2) Bldsr(3) Bldsr(4) Bldsr(5);
%                 {'My11r'}  6 Mysr_neg(1) Mysr_neg(4) Mysr_neg(7) Mysr_neg(10) Mysr_neg(13);
%                 {'My21r'}  6 Mysr_neg(2) Mysr_neg(5) Mysr_neg(8) Mysr_neg(11) Mysr_neg(14);
%                 {'My31r'}  6 Mysr_neg(3) Mysr_neg(6) Mysr_neg(9) Mysr_neg(12) Mysr_neg(15);];
            
            Sensors = [                 % Do not change! The cell array will be updated automatically during execution of LoadExtrapolationDoubleDistribution,
                {'-Mx11r'} 1 0 0 0 0 0; % as the script automatically chooses the best fit for each sensor. Manual choice is disabled
                {'-Mx21r'} 1 0 0 0 0 0; 
                {'-Mx31r'} 1 0 0 0 0 0;
                {'My11r'}  2 0 0 0 0 0;
                {'My21r'}  2 0 0 0 0 0;
                {'My31r'}  2 0 0 0 0 0;
                {'uy1'}    3 0 0 0 0 0;
                {'uy2'}    3 0 0 0 0 0;
                {'uy3'}    3 0 0 0 0 0;
                {'ux1'}    4 0 0 0 0 0;
                {'ux2'}    4 0 0 0 0 0;
                {'ux3'}    4 0 0 0 0 0;
                {'bldefl'} 5 0 0 0 0 0;
                {'My11r'}  6 0 0 0 0 0;
                {'My21r'}  6 0 0 0 0 0;
                {'My31r'}  6 0 0 0 0 0;];
        end

%         % This part should not be changed unless a special investigation is required (check manual)
%         DLC13All.Path = '';%strcat([SimPath 'ETM\Loads\INPUTS\IEC1B_9p525_vr12p4_r1_typhoon.frq']);
%         DLC13All.SeedStart   = 12;
        Options.OutFile = Options.OutFileDNV;
        % LAC.scripts.LoadExtrapolation.LoadExtrapolationScript_LF14(DLC11File,DLC13File,Options,Sensors,DLC13All,colors);
        if Options.Fitting == 0
            [DLC11] = LAC.scripts.LoadExtrapolation.LoadExtrapolationSingleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors);
        elseif Options.Fitting == 1
            [DLC11] = LAC.scripts.LoadExtrapolation.LoadExtrapolationDoubleDistribution(SimPath,DLC11File,DLC13File,Options,Sensors,DLC13All,colors);
        end
end

%% Save Outputs
% Append Fitting Data to NTM structure
FittingData = DLC11{1}.Fitting;
save(Options.SaveDLC11,'FittingData','-append');

end
