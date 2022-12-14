function [ results, quickResults ] = calculateWhirlingComponents(filepath, LC, bandPassFilter, noTimeTraces, saveResultsInFile)

% Function for processing int files for use in BW and FW whirling component
% assessment
%
% !!! WARNING !!!
% This function is similar to LAC.timetrace.plotedgevib.
% Use it at your own risk
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUTS
% filepath          - Location of '\Loads\' Folder
% LC                - Load case identifier typically ^11, ^13 or ^94
% bandPassFilter	- Object LAC.timetrace.models.BandPassFilter() 
%                     containing whirlingLowPass, whirlingHighPass,
%					  edgeLowPass, edgeHighPass
% noTimeTraces      - if 1 then the time traces are not written out
% saveResultsInFile - if 1, save files in:
%                      1. [filepath '\fullResultsStabInt' LC(2:end) '.mat']
%                      2. [filepath '\quickResultsStabInt' LC(2:end) '.mat']
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUTS
% results       - full set of processed results including full processed 
%                 time traces of filtered signals
% quickResults  - reducted set of results containing key frequencies 
%                 and averages whirling load levels for fast reading
%                 and plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE
% LAC.timetrace.calculateWhirlingComponents(filepath, LC);
% LAC.timetrace.calculateWhirlingComponents(filepath, LC, LAC.timetrace.models.BandPassFilter());
% LAC.timetrace.calculateWhirlingComponents(filepath, LC, LAC.timetrace.models.BandPassFilter(), 1);
% LAC.timetrace.calculateWhirlingComponents(filepath, LC, LAC.timetrace.models.BandPassFilter(), 1, 1);

% NOTE: Hardcoded sensor names for PSI, edge root sensors, Rotor speed, Wind speed

% Created by:               IVSON, 28.05.2019
% Checked and released by:  JANOW, 28.05.2019
% Updated by:                  JANOW, 30.05.2019

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check input

if nargin < 2
    msg = 'Not enough input parameters! Please, provide';
    if nargin < 1
        msg = strcat(msg,' a filepath and');
    end
    msg = strcat(msg,' a LC.');
    error(msg)
	
elseif nargin < 3
    bandPassFilter = LAC.timetrace.models.BandPassFilter();
	
    noTimeTraces = 0;
    saveResultsInFile = 0;
	
elseif nargin < 4
    if ~isa(bandPassFilter,'LAC.timetrace.models.BandPassFilter')
		msg = 'A type of parameter bandPassFilter is not LAC.timetrace.models.BandPassFilter. Please, provide a correct object!';
		error(msg)
    end
    noTimeTraces = 0;
    saveResultsInFile = 0;
	
elseif nargin < 5
    if ~isa(bandPassFilter,'LAC.timetrace.models.BandPassFilter')
        msg = 'A type of parameter bandPassFilter is not LAC.timetrace.models.BandPassFilter. Please, provide a correct object!';
        error(msg)
    end
    saveResultsInFile = 0;
    
else
    msg = 'The number of parameters is incorrect!';
    error(msg)
end

if ~endsWith(filepath,filesep)
    filepath = strcat(filepath,filesep);
end

if ~exist(filepath, 'dir')
    msg = ['Directory ' filepath ' does not exist!'];
    error(msg)
end

%% Find Edge Frequency and blade mass moment
results.filepath = filepath;	% Save filepath for output

% Edge frequency from out file
outDirectory = dir([filepath 'OUT\*.out']);

% Check if OUT folder contains *.out files
if isempty(outDirectory)
    msg = ['Directory ' filepath 'OUT\ is empty!'];
    error(msg)
end

outFile = LAC.vts.convert([outDirectory(1).folder '\' outDirectory(1).name], 'OUT');
results.edgeFRQ = outFile.blade.edge1.freq;

% Blade mass moment
bldPath = [filepath 'PARTS\BLD\*'];
bldDirectory = dir(bldPath);
bldDirFlags = [bldDirectory.isdir];
bldDirectory = bldDirectory(~bldDirFlags);

% Check if BLD folder contains blade files
if isempty(bldDirectory)
    msg = ['Directory ' filepath 'PARTS\BLD\ is empty!'];
    error(msg)
end

bladeProps = LAC.vts.convert([filepath 'PARTS\BLD\' bldDirectory(1).name],'BLD');   % What if, for some reason, there will be more than 1 BLD file in the directory?
bladeMassProps = bladeProps.computeMass;
results.Smom1 = bladeMassProps.Smom1; %Blade Mass Moment - should be the same as the one from the VTS *.OUT file approx. line 180-190

%% Find index of specific set of sensors
sensFile = [filepath 'INT\sensor'];	
if ~isfile(sensFile)
    msg = ['Sensor file ' sensFile ' does not exist!'];
    error(msg)
end

sensDat = LAC.vts.convert(sensFile);	% read in sensor file
sensors.PSI = find(strcmp(sensDat.name, 'PSI'));
sensors.A = find(strcmp(sensDat.name, 'My11r'));
sensors.B = find(strcmp(sensDat.name, 'My31r'));
sensors.C = find(strcmp(sensDat.name, 'My21r'));
sensors.RPM = find(strcmp(sensDat.name, 'Omega'));
sensors.WS = find(strcmp(sensDat.name, 'Vhfree'));

% If Vhfree unavailable Vhub will be acceptable
if isempty(sensors.WS)
    sensors.WS = find(strcmp(sensDat.name, 'Vhub'));
end

% GIVE STATUS ON WHETHER SENSORS WERE FOUND!
% NOTE, THAT SENSOR NAMINGS ARE TYPICALLY NOT THE SAME IN HAWC2 - SO
% CONSIDER HARDCODING!

%% Time Trace processing
frqDirectory = dir([filepath,'INPUTS\*.frq']);	% find path to frq file

% Check if INPUTS folder contains a *.frq file
if isempty(frqDirectory)
    msg = ['Directory ' filepath 'INPUTS\ does not have FRQ file!'];
    error(msg)
end

frqobj = LAC.vts.convert([frqDirectory(1).folder '\' frqDirectory(1).name], 'FRQ');   % extract data in frq file

dlcIdxC = regexp(frqobj.LC,LC,'match');     % Find index of DLCs matching the selected LCs
dlcIdx  = (not(cellfun('isempty',dlcIdxC)));    % ??
results.ws = unique(frqobj.V(dlcIdx));  % Unique set of wind speeds in the selected LCs

% Extract whirling loads binned into mean wind speed
for i = 1:length(results.ws)
    
	disp(['Read ws ' num2str(i) ' of ' num2str(length(results.ws))])
    intIdx = and(frqobj.V == results.ws(i),dlcIdx);	% Index of load cases with given mean wind speed
	fileList_ws = frqobj.LC(intIdx);	% Load case file list for given mean wind speed
    
	% Extract whirling loads for given mean wind speed
    %for j =1:min(length(fileList_ws), 12)
    for j =1:length(fileList_ws)        
		disp(['Wsp = ' num2str(results.ws(i)) 'm/s file: ' fileList_ws{j}])
		% Read time trace
        if ~isfile([filepath 'INT\' fileList_ws{j}])
            msg = ['INT file ' fileList_ws{j} ' in ' filepath 'INT\ does not exist!'];
            error(msg)
        end
        
        [~,Xdata,Ydata,~] = LAC.timetrace.int.readint([filepath 'INT\' fileList_ws{j}],1,[],[],[]);
        
		% Extract selected data and put into out-variable
        results.T = Xdata;
        results.meanRPM(i,j)    = mean(Ydata(:,sensors.RPM));
        results.oneP.avg(i,j)   = results.meanRPM(i,j)/60;
        results.oneP.min    = min(Ydata(:,sensors.RPM))/60;
        results.oneP.max    = max(Ydata(:,sensors.RPM))/60;
        results.BW(i,j)     = results.edgeFRQ - results.oneP.avg(i,j);	% First estimate of 1st edge BW frequency
        results.FW(i,j)     = results.edgeFRQ + results.oneP.avg(i,j);	% First estimate of 1st edge FW frequency
        
        dTime = Xdata(2)-Xdata(1);
        NFFT=round(60/dTime);
        results.psi(i,j,:)=LAC.deg2rad(Ydata(:,sensors.PSI));
        results.My1(i,j,:)=Ydata(:,sensors.A);	% saving full time trace... might not be needed
        results.My2(i,j,:)=Ydata(:,sensors.C);
        results.My3(i,j,:)=Ydata(:,sensors.B);
        
		% Fourier transform (amplitude) of unfiltered, untransformed blade signal
        [results.frq,results.fft_My1(i,j,:)]=LAC.signal.fftcalc(Xdata,Ydata(:,sensors.A),NFFT);
        [~,results.fft_My3(i,j,:)]=LAC.signal.fftcalc(Xdata,Ydata(:,sensors.B),NFFT);
        [~,results.fft_My2(i,j,:)]=LAC.signal.fftcalc(Xdata,Ydata(:,sensors.C),NFFT);
        
        % Index of frequencies within a specified frequency band around the estimated 1st edge frequency
        edge_Guess = find(and(results.frq>results.edgeFRQ.*0.75, results.frq<results.edgeFRQ.*1.25));
        
		% Index of edge frequency (through peak finding)
        [~, idx] = max(results.fft_My1(i,j,edge_Guess));
        
		% Updated estimate of the whirling frequency
        results.edgeFRQ_corrected(i,j) = results.frq(idx+edge_Guess(1)-1);
        results.BW(i,j)     = results.edgeFRQ_corrected(i,j) - results.oneP.avg(i,j);
        results.FW(i,j)     = results.edgeFRQ_corrected(i,j) + results.oneP.avg(i,j);
        
        disp(['		Edge Frequency correction ratio = ' num2str(results.edgeFRQ_corrected(i,j)/results.edgeFRQ) ])
        
        % Multiblade transformation
        [results.a(i,j,:),results.b(i,j,:),results.c(i,j,:)]=LAC.rot2fix(LAC.deg2rad(Ydata(:,sensors.PSI)),Ydata(:,sensors.A),Ydata(:,sensors.B),Ydata(:,sensors.C));
		
		% Fourier transform of unfiltered, transformed signals
        [~,results.fft_a(i,j,:)]=LAC.signal.fftcalc(Xdata,results.a(i,j,:),NFFT);   % collective
        [~,results.fft_b(i,j,:)]=LAC.signal.fftcalc(Xdata,results.b(i,j,:),NFFT);	% cosine
        [~,results.fft_c(i,j,:)]=LAC.signal.fftcalc(Xdata,results.c(i,j,:),NFFT);	% sine
        
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Filtering
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
		% Frequency limits for bandpass filters
        oneP.low_pass      = 0;
        oneP.high_pass     = results.oneP.max*1.75;
        BW.low_pass          =  bandPassFilter.whirlingLowPass * results.BW(i,j);
        BW.high_pass         =  bandPassFilter.whirlingHighPass * results.BW(i,j);
        FW.low_pass          =  bandPassFilter.whirlingLowPass * results.FW(i,j);
        FW.high_pass         =  bandPassFilter.whirlingHighPass * results.FW(i,j);
        if BW.low_pass < oneP.high_pass % warning flag if overlap between BW and FW filters
            warndlg('BW Frequency low filter limit Less than oneP Low Pass Frequency')
        end
        edge.low_pass        = bandPassFilter.edgeLowPass * results.edgeFRQ_corrected(i,j);
        edge.high_pass       = bandPassFilter.edgeHighPass * results.edgeFRQ_corrected(i,j);
        
        Fs = 1/(results.T(2) - results.T(1)) ;  % Sampling Frequency (Hz)
        
        disp(['		BW high:' num2str(BW.high_pass) '	FW low:' num2str(FW.low_pass)])
        
        % Disclude first and last 25 seconds to avoid filter transients
        T_start = 25;
        T_end = 575;
        
        T_start_ind = find(results.T==T_start);
        T_end_end = find(results.T==T_end);
        
        % Filtering of relevant sensors
        [results.My1_oneP(i,j,:)] = filterer(oneP.low_pass, oneP.high_pass,results.My1(i,j,:), Fs);	% edge load content at 1p - blade 1
        [results.My1_edgeFrq(i,j,:)] = filterer(edge.low_pass, edge.high_pass,results.My1(i,j,:), Fs);	% edge load content at 1st edge - blade 1
        
        [results.My2_oneP(i,j,:)] = filterer(oneP.low_pass, oneP.high_pass,results.My2(i,j,:), Fs);	% --- blade 2
        [results.My2_edgeFrq(i,j,:)] = filterer(edge.low_pass, edge.high_pass,results.My2(i,j,:), Fs);	% --- blade 2
        
        [results.My3_oneP(i,j,:)] = filterer(oneP.low_pass, oneP.high_pass,results.My3(i,j,:), Fs);	% --- blade 3
        [results.My3_edgeFrq(i,j,:)] = filterer(edge.low_pass, edge.high_pass,results.My3(i,j,:), Fs);	% --- blade 3
        
        [results.BW_b(i,j,:)] = filterer(BW.low_pass, BW.high_pass,results.b(i,j,:), Fs);	% edge load content at BW edge - fixed frame - cosine
        [results.BW_c(i,j,:)] = filterer(BW.low_pass, BW.high_pass,results.c(i,j,:), Fs);	% edge load content at BW edge - fixed frame - sine
        
        [results.FW_b(i,j,:)] = filterer(FW.low_pass, FW.high_pass,results.b(i,j,:), Fs);	% edge load content at FW edge - fixed frame - cosine
        [results.FW_c(i,j,:)] = filterer(FW.low_pass, FW.high_pass,results.c(i,j,:), Fs);	% edge load content at FW edge - fixed frame - sine
                
        % Inverse Coleman Transformation - whirling contents now in rotational frame (back on the blades)
        [results.bw1(i,j,:), results.bw3(i,j,:), results.bw2(i,j,:)] = LAC.fix2rot(LAC.deg2rad(Ydata(:,sensors.PSI)), zeros(1, length(Ydata(:,sensors.PSI))), results.BW_b(i,j,:), results.BW_c(i,j,:));
        [results.fw1(i,j,:), results.fw3(i,j,:), results.fw2(i,j,:)] = LAC.fix2rot(LAC.deg2rad(Ydata(:,sensors.PSI)), zeros(1, length(Ydata(:,sensors.PSI))), results.FW_b(i,j,:), results.FW_c(i,j,:));
        
		% Define statistics and save to out-variable - for each time series
        results.My1_oneP_load(i,j) = sqrt(2)*std(results.My1_oneP(i,j,T_start_ind:T_end_end));
        results.My1_edgeFrq_load(i,j) = sqrt(2)*std(results.My1_edgeFrq(i,j,T_start_ind:T_end_end));
        results.My2_oneP_load(i,j) = sqrt(2)*std(results.My2_oneP(i,j,T_start_ind:T_end_end));
        results.My2_edgeFrq_load(i,j) = sqrt(2)*std(results.My2_edgeFrq(i,j,T_start_ind:T_end_end));
        results.My3_oneP_load(i,j) = sqrt(2)*std(results.My3_oneP(i,j,T_start_ind:T_end_end));
        results.My3_edgeFrq_load(i,j) = sqrt(2)*std(results.My3_edgeFrq(i,j,T_start_ind:T_end_end));
        results.BW_b_load(i,j) = sqrt(2)*std(results.BW_b(i,j,T_start_ind:T_end_end));
        results.BW_c_load(i,j) = sqrt(2)*std(results.BW_c(i,j,T_start_ind:T_end_end));
        results.FW_b_load(i,j) = sqrt(2)*std(results.FW_b(i,j,T_start_ind:T_end_end));
        results.FW_c_load(i,j) = sqrt(2)*std(results.FW_c(i,j,T_start_ind:T_end_end));
        results.BW1_load(i,j) = sqrt(2)*std(results.bw1(i,j,T_start_ind:T_end_end));
        results.FW1_load(i,j) = sqrt(2)*std(results.fw1(i,j,T_start_ind:T_end_end));
        results.BW2_load(i,j) = sqrt(2)*std(results.bw2(i,j,T_start_ind:T_end_end));
        results.FW2_load(i,j) = sqrt(2)*std(results.fw2(i,j,T_start_ind:T_end_end));
        results.BW3_load(i,j) = sqrt(2)*std(results.bw3(i,j,T_start_ind:T_end_end));
        results.FW3_load(i,j) = sqrt(2)*std(results.fw3(i,j,T_start_ind:T_end_end));
        
        results.My1_oneP_loadMax(i,j)       = 0.5*peak2peak(results.My1_oneP(i,j,T_start_ind:T_end_end));
        results.My1_edgeFrq_loadMax(i,j)    = 0.5*peak2peak(results.My1_edgeFrq(i,j,T_start_ind:T_end_end));
        results.My2_oneP_loadMax(i,j)       = 0.5*peak2peak(results.My2_oneP(i,j,T_start_ind:T_end_end));
        results.My2_edgeFrq_loadMax(i,j)    = 0.5*peak2peak(results.My2_edgeFrq(i,j,T_start_ind:T_end_end));
        results.My3_oneP_loadMax(i,j)       = 0.5*peak2peak(results.My3_oneP(i,j,T_start_ind:T_end_end));
        results.My3_edgeFrq_loadMax(i,j)    = 0.5*peak2peak(results.My3_edgeFrq(i,j,T_start_ind:T_end_end));
        
        results.BW_b_loadMax(i,j) = 0.5*peak2peak(results.BW_b(i,j,T_start_ind:T_end_end));
        results.BW_c_loadMax(i,j) = 0.5*peak2peak(results.BW_c(i,j,T_start_ind:T_end_end));
        results.FW_b_loadMax(i,j) = 0.5*peak2peak(results.FW_b(i,j,T_start_ind:T_end_end));
        results.FW_c_loadMax(i,j) = 0.5*peak2peak(results.FW_c(i,j,T_start_ind:T_end_end));
        
        results.BW1_loadMax(i,j) = 0.5*peak2peak(results.bw1(i,j,T_start_ind:T_end_end));
        results.FW1_loadMax(i,j) = 0.5*peak2peak(results.fw1(i,j,T_start_ind:T_end_end));
        results.BW2_loadMax(i,j) = 0.5*peak2peak(results.bw2(i,j,T_start_ind:T_end_end));
        results.FW2_loadMax(i,j) = 0.5*peak2peak(results.fw2(i,j,T_start_ind:T_end_end));
        results.BW3_loadMax(i,j) = 0.5*peak2peak(results.bw3(i,j,T_start_ind:T_end_end));
        results.FW3_loadMax(i,j) = 0.5*peak2peak(results.fw3(i,j,T_start_ind:T_end_end));
    end
    
    % Define statistics and save to out-variable - average over seeds in given wind speed
    results.avg.fft_My1(i,:) =  mean(results.fft_My1(i,:,:), 2);
    results.avg.fft_My2(i,:) =  mean(results.fft_My2(i,:,:), 2);
    results.avg.fft_My3(i,:) =  mean(results.fft_My3(i,:,:), 2);
    
    results.avg.fft_a(i,:) =  mean(results.fft_a(i,:,:), 2);
    results.avg.fft_b(i,:) =  mean(results.fft_b(i,:,:), 2);
    results.avg.fft_c(i,:) =  mean(results.fft_c(i,:,:), 2);
    
    results.avg.oneP(i)  = mean(results.oneP.avg(i,:),2);
    results.avg.edgeFRQ_corrected(i)    = mean(results.edgeFRQ_corrected(i,:));
    results.avg.BW(i)    = results.avg.edgeFRQ_corrected(i) - results.avg.oneP(i);
    results.avg.FW(i)    = results.avg.edgeFRQ_corrected(i) + results.avg.oneP(i);
    
    results.avg.My1_oneP_load(i)        = mean( results.My1_oneP_load(i,:));
    results.avg.My1_edgeFrq_load(i)     = mean( results.My1_edgeFrq_load(i,:));
    results.avg.My2_oneP_load(i)        = mean( results.My2_oneP_load(i,:));
    results.avg.My2_edgeFrq_load(i)     = mean( results.My2_edgeFrq_load(i,:));
    results.avg.My3_oneP_load(i)        = mean( results.My3_oneP_load(i,:));
    results.avg.My3_edgeFrq_load(i)     = mean( results.My3_edgeFrq_load(i,:));
    results.avg.BW_b_load(i)        = mean(results.BW_b_load(i,:));
    results.avg.BW_c_load(i)        = mean(results.BW_c_load(i,:));
    results.avg.FW_b_load(i)        = mean(results.FW_b_load(i,:));
    results.avg.FW_c_load(i)        = mean(results.FW_c_load(i,:));
    results.avg.BW1_load(i)         = mean(results.BW1_load(i,:));
    results.avg.FW1_load(i)         = mean(results.FW1_load(i,:));
    results.avg.BW2_load(i)         = mean(results.BW2_load(i,:));
    results.avg.FW2_load(i)         = mean(results.FW2_load(i,:));
    results.avg.BW3_load(i)         = mean(results.BW3_load(i,:));
    results.avg.FW3_load(i)         = mean(results.FW3_load(i,:));
    
    % Max of max results
    results.avg.My1_oneP_loadMax(i)         = max( results.My1_oneP_loadMax(i,:));
    results.avg.My1_edgeFrq_loadMax(i)      = max( results.My1_edgeFrq_loadMax(i,:));
    results.avg.My2_oneP_loadMax(i)         = max( results.My2_oneP_loadMax(i,:));
    results.avg.My2_edgeFrq_loadMax(i)      = max( results.My2_edgeFrq_loadMax(i,:));
    results.avg.My3_oneP_loadMax(i)         = max( results.My3_oneP_loadMax(i,:));
    results.avg.My3_edgeFrq_loadMax(i)      = max( results.My3_edgeFrq_loadMax(i,:));
    results.avg.BW_b_loadMax(i)        = max(results.BW_b_loadMax(i,:));
    results.avg.BW_c_loadMax(i)        = max(results.BW_c_loadMax(i,:));
    results.avg.FW_b_loadMax(i)        = max(results.FW_b_loadMax(i,:));
    results.avg.FW_c_loadMax(i)        = max(results.FW_c_loadMax(i,:));
    results.avg.BW1_loadMax(i)         = max(results.BW1_loadMax(i,:));
    results.avg.FW1_loadMax(i)         = max(results.FW1_loadMax(i,:));
    results.avg.BW2_loadMax(i)         = max(results.BW2_loadMax(i,:));
    results.avg.FW2_loadMax(i)         = max(results.FW2_loadMax(i,:));
    results.avg.BW3_loadMax(i)         = max(results.BW3_loadMax(i,:));
    results.avg.FW3_loadMax(i)         = max(results.FW3_loadMax(i,:));
    
    % Mean of max results
    results.avg.My1_oneP_loadMaxMean(i)         = mean(results.My1_oneP_loadMax(i,:));
    results.avg.My1_edgeFrq_loadMaxMean(i)      = mean(results.My1_edgeFrq_loadMax(i,:));
    results.avg.My2_oneP_loadMaxMean(i)         = mean(results.My2_oneP_loadMax(i,:));
    results.avg.My2_edgeFrq_loadMaxMean(i)      = mean(results.My2_edgeFrq_loadMax(i,:));
    results.avg.My3_oneP_loadMaxMean(i)         = mean(results.My3_oneP_loadMax(i,:));
    results.avg.My3_edgeFrq_loadMaxMean(i)      = mean(results.My3_edgeFrq_loadMax(i,:));
    results.avg.BW_b_loadMaxMean(i)        = mean(results.BW_b_loadMax(i,:));
    results.avg.BW_c_loadMaxMean(i)        = mean(results.BW_c_loadMax(i,:));
    results.avg.FW_b_loadMaxMean(i)        = mean(results.FW_b_loadMax(i,:));
    results.avg.FW_c_loadMaxMean(i)        = mean(results.FW_c_loadMax(i,:));
    results.avg.BW1_loadMaxMean(i)         = mean(results.BW1_loadMax(i,:));
    results.avg.FW1_loadMaxMean(i)         = mean(results.FW1_loadMax(i,:));
    results.avg.BW2_loadMaxMean(i)         = mean(results.BW2_loadMax(i,:));
    results.avg.FW2_loadMaxMean(i)         = mean(results.FW2_loadMax(i,:));
    results.avg.BW3_loadMaxMean(i)         = mean(results.BW3_loadMax(i,:));
    results.avg.FW3_loadMaxMean(i)         = mean(results.FW3_loadMax(i,:));
    
end

% Delete variables in results struct (to make results file size smaller)
fields = {'fft_My1','fft_My2','fft_My3','a','b','c','fft_a','fft_b','fft_c','BW_b','BW_c','FW_b','FW_c','psi','My1_oneP','My2_oneP','My3_oneP'};
results = rmfield(results,fields);

if noTimeTraces % then the time traces are not written out
	fields = {'My1','My2','My3','My1_edgeFrq','My2_edgeFrq','My3_edgeFrq','bw1','bw2','bw3','fw1','fw2','fw3'};
	results = rmfield(results,fields);
end

%% Summary results saved in quickResults Variable
quickResults.avg = results.avg;
quickResults.ws  = results.ws;
quickResults.Smom1 = results.Smom1;
quickResults.edgeFRQ = results.edgeFRQ;
quickResults.edgeFRQ_corrected = results.edgeFRQ_corrected;

if saveResultsInFile
    save([filepath '\fullResultsStabInt' LC(2:end) '.mat'],'results')
    save([filepath '\quickResultsStabInt' LC(2:end) '.mat'],'quickResults')
end

    function [sig_filt] = filterer(low, high, sig, Fs)
        
        Fn = Fs/2;
        
        if low<0.15 % if low filter less than 0.15 Hz then only use low pass filter
            
            [B,A] = butter(4,[high]./Fn);
            
        else % use bandpass filter
            
            [B,A] = butter(4,[low  high]./Fn);
            
        end
        
        sig_filt = filtfilt(B, A, sig);
        
    end

end