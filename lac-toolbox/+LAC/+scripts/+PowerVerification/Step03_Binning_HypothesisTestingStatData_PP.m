function Step03_Binning_HypothesisTestingStatData_PP(WTG,bin_Vn, FlagInterpolAll)
%% Purpose of this script:- ------------------------------------------------------------
% (i) Performing hypothesis test to assess the difference between meas. & VTS simulation for all important signals.
%     It includes 2-sample t-test analysis to get 95% CI over differences.
%     Link for T-table : http://www.acastat.com/Statbook/ttest2.htm
% (ii)Binning w.r.t wind speed bin for both meas. & simulation
%% Given below are the few points to follow -
%  1. Load the measured and simulation processed data in matlab.. data.dat1 & Simdata.dat1
%  2. Change the following inputs according to the requirements.
%  3. Change the main code only if needed.
%  4. Output of this script is saved in .mat format. This is recalled while comparing meas & simu.
%  5. Remember that everything is been cleared from work  space at the end of this script.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 07/05/2019 - by MODFY for Power Performance
% 23/10/2020 - Wind Direction binning added by ATRSN for MK3A V174 
% 08/2021 - Updated AEP calculation - by SEHIK, MACVL

% This script has been modify to solely consider the needed information for 
% the power performance.
% Updates:
% - the wind spedd bin is centered in the multiple of the bin size
% - fatigue calcultion is disregarded

% input bin_Vn is a logical 
%   - bin_Vn = 1 if the wind speed binning should be done in function of
%   the normalised wind speed
%   - bin_Vn = 0 if the wind speed binning should be done in function of
%   the wind speed at the met mast level
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Input starts: ------------------------------------------------------------
	
	import LAC.scripts.PowerVerification.auxiliary.*
	import LAC.scripts.PowerVerification.auxiliary.Step03.*
	
    % change directory to the output one
    curr = pwd;
    cd([pwd '\Output\'])
    
%     % Load the measurement data "data.dat1" format
%     load MeasurementData.mat; 
    
    % Load the computed Mean Wind SPeed, TI and Wind Shear from the filtered data
    load Step01_SiteConditions.mat
    
    % load the simulation data "Simdata.dat1" format
    load Step02_VTS_simulation.mat; 
    
    % load the sensor list
    load Step02_SensorlistInput.mat;
    
    % Load information from the excel file
    WS_bin_size  = WTG.WSBinSize;
    TI_bin_size = WTG.TIBinSize;
    TIQuantiles_bin_size = WTG.TIQuantileBinSize;
    Shear_bin_size = WTG.ShearBinSize;
    
    if isempty(WS_bin_size) || isempty(TI_bin_size) || isempty(TIQuantiles_bin_size) || isempty(Shear_bin_size)
        msg = 'Error: WTG.WSBinSize, WTG.TIBinSize, WTG.WSBinSize or WTG.WSBinSize are empty. Update the intput file with the bin size.';
        error(msg)
    end
    
    RhoRef = WTG.RhoRef;
    AreaSwept = (WTG.RotorDiameter/2)^2*pi();
   
    %Creating variable for Wind Direction binning
    WindDir = data.dat1.mean(:,9);
    BinRange = [90 60 30];
    MetMastLoc = 270;

%%%%%%%%%%%%% Input ends: ------------------------------------------------------------

%% ****** Main code starts here *********************************

%% Binning measurement
% Binning level 1
    % Turbulence binning
    [TI_bin] = Xbinning(TI,TI_bin_size,'TI',[],0);
    [TIQuantiles_bin] = Quantile_sep(TI, TIQuantiles_bin_size);


    % Shear binning
    [WShear_bin] = Xbinning(WindShear,Shear_bin_size, 'WShear', [],0);
    
    %Wind Direction binning
    [WDir_bin] = WinDirBinning(WindDir,BinRange,MetMastLoc,'WindDir',[]);

    % Wind speed binning and computation of the statistics
    %  For wind speed binning the normalised wind speed is to be considered for
    %  the distribution of the data
    if bin_Vn ==1 
        V_to_bin_index = find(strcmp(data.dat1.sensorname,'Wind speed normalised (m/s)')==1);
        V_to_bin = data.dat1.mean(:,V_to_bin_index);
    else
        V_to_bin_index = find(strcmp(data.dat1.sensorname,'Wind speed (m/s)')==1);
        V_to_bin = data.dat1.mean(:,V_to_bin_index);
    end
     

%  Binning level 2
    % Turbulence bin ranges - Second binning as function of ws
    for i = 1:length(TI_bin.name)
        temp = strcat('bin',string(i));
        %%%if using matlab < 2017b
        temp = char(temp);
        [WSpeed_bin_temp] = Xbinning(V_to_bin,WS_bin_size,'WS',TI_bin.index{i},1);
        TI_bin.ws_lowerbinlimit = WSpeed_bin_temp.lowerbinlimit;
        TI_bin.ws_upperbinlimit = WSpeed_bin_temp.upperbinlimit;
        TI_bin.(temp) = WSpeed_bin_temp.index;
    end
    clear WSpeed_bin_temp temp
    
    % Turbulence quantiles - Second binning as function of ws
    for i = 1:length(TIQuantiles_bin.name)
        temp = strcat('bin',string(i));
        %%%if using matlab < 2017b
        temp = char(temp);
        [WSpeed_bin_temp] = Xbinning(V_to_bin,WS_bin_size,'WS',TIQuantiles_bin.index{i},1);
        TIQuantiles_bin.ws_lowerbinlimit = WSpeed_bin_temp.lowerbinlimit;
        TIQuantiles_bin.ws_upperbinlimit = WSpeed_bin_temp.upperbinlimit;
        TIQuantiles_bin.(temp) = WSpeed_bin_temp.index;
    end
    clear WSpeed_bin_temp temp
    
    % Wind Shear - Second binning as function of ws
    for i = 1:length(WShear_bin.name)
        temp = strcat('bin',string(i));
        %%%if using matlab < 2017b
        temp = char(temp);
        [WSpeed_bin_temp] = Xbinning(V_to_bin,WS_bin_size,'WS',WShear_bin.index{i},1);
        WShear_bin.ws_lowerbinlimit = WSpeed_bin_temp.lowerbinlimit;
        WShear_bin.ws_upperbinlimit = WSpeed_bin_temp.upperbinlimit;
        WShear_bin.(temp) = WSpeed_bin_temp.index;
    end   
    clear WSpeed_bin_temp temp
    
    %Wind Direction - Second binning as function of ws
    for i = 1:length(WDir_bin.name)
        temp = strcat('bin',string(i));
        %%%if using matlab < 2017b
        temp = char(temp);
        [WDir_bin_temp] = Xbinning(V_to_bin,WS_bin_size,'WS',WDir_bin.index{i},1);
        WDir_bin.ws_lowerbinlimit = WDir_bin_temp.lowerbinlimit;
        WDir_bin.ws_upperbinlimit = WDir_bin_temp.upperbinlimit;
        WDir_bin.(temp) = WDir_bin_temp.index;
    end
    clear WDir_bin_temp temp
    
    % Wind speed binning in all data
    [WSpeed_bin] = Xbinning(V_to_bin,WS_bin_size,'WS',[],1);
    WSpeed_bin.bin1 = WSpeed_bin.index;
    WSpeed_bin.index={1};

%% computing the average within a bin

% Measurement 
[TI_bin] = BinStatComputation(data.dat1,TI_bin,'dat');
[TIQuantiles_bin] = BinStatComputation(data.dat1,TIQuantiles_bin,'dat');
[WShear_bin] = BinStatComputation(data.dat1,WShear_bin,'dat');
[WSpeed_bin] = BinStatComputation(data.dat1,WSpeed_bin,'dat');
[WDir_bin] = BinStatComputation(data.dat1,WDir_bin,'dat');

% Simulation
[TI_bin] = BinStatComputation(Simdata.dat1,TI_bin,'Simdat');
[TIQuantiles_bin] = BinStatComputation(Simdata.dat1,TIQuantiles_bin,'Simdat');
[WShear_bin] = BinStatComputation(Simdata.dat1,WShear_bin,'Simdat');
[WSpeed_bin] = BinStatComputation(Simdata.dat1,WSpeed_bin,'Simdat');
[WDir_bin] = BinStatComputation(Simdata.dat1,WDir_bin,'Simdat');

%% computing Cp for each Xbin

% Measurement
[TI_bin, SensorList_temp] = CpComputation(TI_bin, SensorList, V_to_bin_index, 'dat', RhoRef, AreaSwept);
[TIQuantiles_bin] = CpComputation(TIQuantiles_bin, SensorList, V_to_bin_index, 'dat', RhoRef, AreaSwept);
[WShear_bin] = CpComputation(WShear_bin, SensorList, V_to_bin_index, 'dat', RhoRef, AreaSwept);
[WSpeed_bin] = CpComputation(WSpeed_bin, SensorList, V_to_bin_index, 'dat', RhoRef, AreaSwept);
[WDir_bin] = CpComputation(WDir_bin, SensorList, V_to_bin_index, 'dat', RhoRef, AreaSwept);

% Simulation
[TI_bin] = CpComputation(TI_bin, SensorList, V_to_bin_index, 'Simdat', RhoRef, AreaSwept);
[TIQuantiles_bin] = CpComputation(TIQuantiles_bin, SensorList, V_to_bin_index, 'Simdat', RhoRef, AreaSwept);
[WShear_bin] = CpComputation(WShear_bin, SensorList, V_to_bin_index, 'Simdat', RhoRef, AreaSwept);
[WSpeed_bin] = CpComputation(WSpeed_bin, SensorList, V_to_bin_index, 'Simdat', RhoRef, AreaSwept);
[WDir_bin] = CpComputation(WDir_bin, SensorList, V_to_bin_index, 'Simdat', RhoRef, AreaSwept);


SensorList = SensorList_temp;
clear SensorList_temp
%% computing AEP for each Xbin

P_sens_no = find(strcmp('P',SensorList.sensorname(:,2)));

[WSpeed_bin.AEP_range]=AEP_WSPrange(WSpeed_bin, V_to_bin_index, P_sens_no, WTG, FlagInterpolAll);

%% Saving the data    
    save ('Step03_VTS_simulation_withBinning', 'Simdata');
    save ('Step03_Measurement_VTS_withBinning', 'data', 'Simdata', 'WShear_bin', 'TI_bin', 'TIQuantiles_bin', 'WSpeed_bin', 'WDir_bin');
    save ('Step03_SensorlistInput', 'SensorList');
%          if do_you_need_statisticalCompare ==1
%              save ('Step03_Statistical_comparison','Statdata');
%      end;
%     
%% clearing the work space
%clear all;
cd(curr);

end
