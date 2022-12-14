
function VSCoutToVTSclm(Outfile, extendbins,Component,WTGID, bSuppressDialogbox)
% Generates a VTS climate file based on a VSC *.out file
%
%Note: You will need to create a local copy of  ProbBin.m from the toolbox
%in order to run this function.
%
% Input:    VSC output file
%           'extendbins': optional input, default set to 0 (false)
%                         -only to be used when calculating extended
%                         cut-out wind speed
%                         -if set to 1 (true), the DETwind and ETM values
%                         are extrapolated to the higher wind speed bins
%                         above cut-out
% Output:   '*.clm' in the same folder as the VSC outfile and with the same
%           name as the VSC file.
%           'WTG_No_*_WSM.mat' in the same folder as the VSC outfile,only if
%           there is WSM implemented on the WTG used in NTM_Fat
%
% The script takes the worst loaded turbine in the VSC *.out file based
% on a user input. Based on the component of interest, the effective
% turbulence is choosen:
% 1. Fatigue Blade loads   	(m = 10)
%    Take the effective turbulence from the turbine with the highest blade loads.
% 2. Fatigue Nacelle loads	(m = 8)
%    Take the effective turbulence from the turbine with the highest nacelle loads.
% 3. Fatigue Tower loads   	(m = 4)
%    Take the effective turbulence from the turbine with the highest tower loads.
% 4. All components 		(m = 10)
%    Take the effective turbulence from the turbine with the worst loaded component.
%
% Turbulence levels not available in the VSC *.out file have been
% extrapolated, based on a linear fit to the turbulence standard deviation.
% This is based on the assumption also used in IEC61400-1, ed.3. The
% linear fit have been limited to not have a negative slope to avoid
% unrealistic levels in the extrapolated turbulence values.
%
% A minimums limit for the turbulence have been set.
%       DETwind  NTM_Fat  NTM_Ext  ETM
% Iref  0.08     0.08     0.08     0.08
%
% Example command:
% VSCoutToVTSclm('W:\SOURCE\TLtoolbox\dummy\101111dbart Wainfleet .out')
%
% DMS: 0028-7612
%
% V01   ALKJA   2012-02-03
% V01.1 WISOR   2012-06-19  Added WSM output
% V02	ALKJA	2012-08-24  Updated to reflect SVN and added information to the *.clm filename
% V03   CHMAJ   2019-09-16  Merged the scripts to write directional fatigue
% 

%%
% Minimum Iref values
%          DETwind   NTM_Fat   NTM_Ext   ETM     V50     LN
MinIref = [0.08      0.08      0.08      0.08    0.05    0.08];

%%
%Defaults 'extendbins' to zero if user does not provide explicit input
%otherwise.

if nargin < 2
    disp('Insufficient input Arguments. Exiting...')
    return
    
elseif nargin ==2
   % extendbins = 1;
    Component = 'E';
    WTGID = '';
    bSuppressDialogbox.bOption = false;    
elseif nargin ==3
   % Component = 'E';
    WTGID = '';
    bSuppressDialogbox.bOption = false;
elseif nargin ==4
   % WTGID = '';
    bSuppressDialogbox.bOption = false;
end

% unpack First Argument
if bSuppressDialogbox.bOption
    bSupress=true;
    PrintMode=bSuppressDialogbox.PrintMode;
    logNormalChoice = bSuppressDialogbox.logNormalChoice;
else
    bSupress=false;
end
    


%% Test files
% --- VSC.Classec tub file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang Tub_120217_123812.out';
% --- VSC.Classic i15 file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang i15_120217_123703.out';
% --- VSC.Classic IEC turb file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\SangWang Tub_120217_124326_IECturb.out';
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\V100 1.8MW LaPM test_120116_093405_i15.out';
% --- VSC.Classic Raw data file
% Outfile = 'W:\user\alkja\MatLab\VSCToClima\VSC.net Test Lincoln_120215_025203.out';
% --- VSC.net Raw data file
%Outfile = 'v:\3MW\V90.3000\Mk5\PP\Investigations\177\BlueTrail\Blue Trail_120607_095624.out';

%% Woehler in VSC eff turbulence
mwholer = [4 8 10 3.3 5.7 8.7];

%% Read VSC-Out file and store in C
VSCOut.Outfile = Outfile;
[VSCOut.PATHSTR,VSCOut.NAME,EXT] = fileparts(VSCOut.Outfile);
fid = fopen(VSCOut.Outfile,'r');
if fid ~= -1
    C = textscan(fid,'%s','delimiter',['\r', '\n']);
    fclose(fid);
    fid = fopen(VSCOut.Outfile,'r');
    for i = 1:12
        VSCOut.VSCTopInfo{i} = fgets(fid);
    end
    fclose(fid);
else
    disp(' Couldn''t Find /Open the File ');
    return;
end

%% Print Mode
if ~bSupress        
    PrintMode = questdlg('Please select .clm file format.  B : Base Format   D : Dirfat Format ','CLM OUTPUT FORMAT','B','D','B');     
    % Handle response
    if length(PrintMode) < 1
        disp('Wrong Response. Exiting...')
        return
    end
end

%% Get Project Name
key = 'Project Name:';
VSCOut.ProjectName = GetValueForKeyFromClmFile(C{1} , key);
%% Test the version of outfile (VSC.Classic or VSC.net)
key = 'DLL load files used in farm:';
pos = GetPosOfKeyFromClmFile(C{1} , key);
if isempty(pos)
    VSCOut.VSCnet = true;
    
    key = 'Version: ';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    LineData = textscan(C{1}{pos(1)},'%s %s %s');
    try 
    CalculationDate = datenum(LineData{3}{1},'YYYYmmdd');
    catch % if unable to read data in this format, it is assumed it is an old version
    CalculationDate = datenum('00000000','YYYYmmdd');    
    end
    NewOutPutFormatDate = datenum('20151208','YYYYmmdd');
    if (CalculationDate > NewOutPutFormatDate)
        VSCOut.VSCnetVersion = 2;
    else
        VSCOut.VSCnetVersion = 1;
    end
    
    key = 'MrTwrTop_Twr';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    VSCOut.extralinesaddedMrTT = 0;
    if length(pos) > 0 % Then Mr is available
        VSCOut.extralinesaddedMrTT = 1;
    end
    
    key = 'MrTwrBot_Twr';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    VSCOut.extralinesaddedMrTB = 4;
    if length(pos) > 0 % Then Mr is available
        VSCOut.extralinesaddedMrTB = 5;
    end
    
else
    VSCOut.VSCnet = false;
end

%% Read site variable
% air density, V50, Ve50, V50Turb
clc;
disp('--- VSCoutToVTSclm.m ------------------------------------------');
disp(' ')
disp('- Reading general Site data...')
VSCOut = ReadSiteVar(VSCOut,C);


%% Read Turbine Related Info
VSCOut = ReadTurbineData(VSCOut,C);

%% Read Windspeed Probability
VSCOut = ReadWSProb(VSCOut,C);

%% Read Turbine Label and turbulence of worst fatigue loaded turbine depending on input
% This is for NTM_Fat...
disp(' ')
disp('- Reading effective turbulence for fatigue load calculation...')
VSCOut = ReadNTMFat(VSCOut,C,Component,WTGID);


%% Read Turbine Label and turbulence of worst ambient turbulence
% This is for DETwind and NTM_Ext
disp(' ')
disp('- Reading ambient turbulence for extreme load calculation...')
disp('  (If large park, then this takes some minutes)')

priorityKey ='Normal turbulence for extreme loads';

pos = GetPosOfKeyFromClmFile(C{1} , priorityKey);
if isempty(pos)    
    VSCOut = ReadAmbTurb(VSCOut,C);    
    %check if wind sector management is used
    disp(' ');
    disp('- Reading key word for wind sector management...')
    VSCOut.WSMString = 'Keyword for wind sector managemnt not found';
    key = 'Wind Sector Management';
    VSCOut.WSMString = GetLinesFromClmFile(C{1} , key, 1, 1);
    disp('WSM key word found: ');
    disp(VSCOut.WSMString);
    if strcmpi(VSCOut.WSMString, '- None')>0
        disp ('WSM not used.');
    else
        disp ('WSM used');
    end
else
    VSCOut = fProcess_DETWind_Ext(VSCOut,C);
    disp('Normal turbulence for extreme loads - FOUND');
end


%% Read Turbine Label and turbulence of worst extreme turbulence
% This is for 'ETM'...
disp(' ')
disp('- Reading extreme turbulence for extreme load calculation...')
VSCOut = ReadETMTurb(VSCOut,C);
VSCOut = ReadCWTurb(VSCOut,Component,C);

%% Read Lognormal Mean and STD 

VSCOut.LNexists = false;
VSCOut.printLogNormal = false;
VSCOut.lognormalQuantile='';
VSCOut = LNTitle(VSCOut, C);
if VSCOut.LNexists
   if ~bSupress 
       logNormalChoice = questdlg('LogNormal Mean and Std.Dev available!   Do you want to Print them ?');
   end
    % Hard-coded as No for now to avoid misusage. See
    % http://task.tsw.vestas.net/browse/LMT-6201 for more details.
    %choice = 'No'
    switch lower(logNormalChoice)
        case 'yes'
            VSCOut.lognormalQuantile='3';
            disp(' ')
            disp('- Reading key word for lognormal...')
            disp('- Reading Log Normal distribution mean and standard deviation...')
            VSCOut = ReadLN(VSCOut, C);
            VSCOut.printLogNormal = true;
        case 'no'
            VSCOut.printLogNormal = false;
            VSCOut.lognormalQuantile='';
        case 'cancel'
            disp('No Selection Made. Exiting...')
            return
    end
    
    
end

%% %% check if LAPM is used
disp(' ')
disp('- Reading key word for load and power mode ..')
key = 'Advanced Wind Sector Management (Load and Power Modes)';
tableStart = GetLinesFromClmFile(C{1} , key, 2, 2);
if strcmp(tableStart{1},'- None') || strcmp(tableStart{2},'')
    VSCOut.LAPMString = 'Advanced Wind Sector Management (Load and Power Modes) is missing';
    disp('Load and Power mode table is missing!')
else
    VSCOut.LAPMString = 'Advanced Wind Sector Management (Load and Power Modes) has no errors.';
    try
        dataToTable = GetDataAsTableFromClmFile(C{1} , key, 4, 6, -1, 1);
        disp('Load and power mode table is found to be OK.');
    catch
        disp('Something is wrong in Load and Power mode table!!');
    end
    disp('LAPM looks like this');
    disp(char(GetLinesFromClmFile(C{1} , key, 0,4+length(dataToTable))));
end


%% FIND DESIGN LIFETIME
disp(' ')
disp('- Reading key word for design lifetime')
VSCOut.DesignLifetime = 20;
key = 'Design life time:';
try
    dataToTable = GetDataAsTableFromClmFile(C{1} , key, 0, 3, 1, 1);
    VSCOut.DesignLifetime = str2double(char(dataToTable{1}));
    disp(char(GetLinesFromClmFile(C{1} , key, 0, 1)));
catch
    disp('Something is wrong in the Design life time table'); 
end
%% FIND ICING HOURS
disp(' ')
disp('- Reading key word for icing hours')
VSCOut.IcingHours = 0.0;
key = 'Icing hours per year:';
try
    dataToTable = GetDataAsTableFromClmFile(C{1} , key, 0, 4, 1, 1);
    VSCOut.IcingHours = str2double(char(dataToTable{1}));
    disp(char(GetLinesFromClmFile(C{1} , key, 0, 1)));
catch
    disp('Something is wrong in the Icing hours per year table'); 
end
%% store turbilence for VTS climate file
DeltaWindSpeed = 2; % 2 m/s bin
VSCOut.WindSpeed = 2:DeltaWindSpeed:38; % Wind speeds 2 m/s - 38 m/s
VSCOut.VTSOut(1,:) = VSCOut.WindSpeed - DeltaWindSpeed/2; % start wind speed
VSCOut.VTSOut(2,:) = VSCOut.WindSpeed + DeltaWindSpeed/2; % end wind speed

% Sector-wise NTM TI to be stored in 'VSCOut.VTSOutNTMsectorWise'
VSCOut.VTSOutNTMsectorWise(1,:) = VSCOut.WindSpeed - DeltaWindSpeed/2; % start wind speed
VSCOut.VTSOutNTMsectorWise(2,:) = VSCOut.WindSpeed + DeltaWindSpeed/2; % end wind speed

% Sector-wise LogNormal Mean to be stored in 'VSCOut.LNMeanSectorWise'
VSCOut.LNMeanSectorWise(1,:) = VSCOut.WindSpeed - DeltaWindSpeed/2; % start wind speed
VSCOut.LNMeanSectorWise(2,:) = VSCOut.WindSpeed + DeltaWindSpeed/2; % end wind speed

% Sector-wise LogNormal Std to be stored in 'VSCOut.LNStdSectorWise'
VSCOut.LNStdSectorWise(1,:) = VSCOut.WindSpeed - DeltaWindSpeed/2; % start wind speed
VSCOut.LNStdSectorWise(2,:) = VSCOut.WindSpeed + DeltaWindSpeed/2; % end wind speed

% --- Store the turbulence levels from VSC out file (4 m/s - 24 m/s)
for i = 1:11
    % Ambient turbulence
    TImin = NTM(MinIref(1),2*i+2);
    if VSCOut.MaxAmbTI90(i) > 0.0001
        VSCOut.VTSOut(3,i+1) = max(TImin,VSCOut.MaxAmbTI90(i));  % sum(( VSCOut.MeanAmbTurb(i,:) + 1.28 * VSCOut.StdAmbTurb(i,:) ) .* VSCOut.Prob)/sum(VSCOut.Prob);
    else
        VSCOut.VTSOut(3,i+1) = 0;
    end
    
    % NTM fatigue
    TImin = NTM(MinIref(2),2*i+2);
    Index = find(VSCOut.TIefftWholer == mwholer);
    if VSCOut.EffTurb(i,Index) > 0.0001
    	VSCOut.VTSOut(4,i+1) = max(TImin,VSCOut.EffTurb(i,Index)); %max(VSCOut.EffTurb(i,Index),VSCOut.MaxAmbTI90(i)); % m = VSCOut.TIefftWholer
    else
        VSCOut.VTSOut(4,i+1) = 0;
    end
    
    % NTM fatigue (directional)
    TImin = NTM(MinIref(2),2*i+2);    
    for nDir = 1 : size(VSCOut.EffTurb_SectorWise,2)
        if VSCOut.EffTurb_SectorWise(i,nDir) > 0.0001
            VSCOut.VTSOutNTMsectorWise(2+nDir,i+1) = max(TImin,VSCOut.EffTurb_SectorWise(i,nDir)); %max(VSCOut.EffTurb(i,Index),VSCOut.MaxAmbTI90(i)); % m = VSCOut.TIefftWholer
        else
            VSCOut.VTSOutNTMsectorWise(2+nDir,i+1) = 0;
        end
    end    
    
    % NTM extreme
    TImin = NTM(MinIref(3),2*i+2);
    if VSCOut.NTMext(i) > 0.0001
        VSCOut.VTSOut(5,i+1) = max(TImin,VSCOut.NTMext(i));      % As above   
    else
        VSCOut.VTSOut(5,i+1) = 0;   
    end
    
    % ETM 
    TImin = ETM(MinIref(4),2*i+2,VSCOut.MeanW,2);
    if VSCOut.MaxETM(i) > 0.0001
        VSCOut.VTSOut(6,i+1) = max(TImin,VSCOut.MaxETM(i));
    else
        VSCOut.VTSOut(6,i+1) = 0;   
    end
    
    % LN_Mean and LN_STD
    if VSCOut.printLogNormal
                                                
        [IEC_TI_LogNormal,iec_mean ,iec_std] = fLogNormalTI(MinIref(6),2*i+2);
                
        logNormal_TI = VSCOut.LogNormalMean(i)+1.28*VSCOut.LogNormalStd(i);
        
        for nSector = 1:size(VSCOut.LogNormalMeanSectorWise,2)-2
           if VSCOut.LogNormalMeanSectorWise(i,nSector) > 0.0001             
              LNMeanSectorWise = VSCOut.LogNormalMeanSectorWise(i,nSector+2) + 1.28 * VSCOut.LogNormalStdSectorWise(i,nSector+2); 
           %  VSCOut.LNMeanSectorWise(nSector+2,i+1) = max(IEC_TI_LogNormal,VSCOut.LNMeanSectorWise(nSector+2,i+1)); 
           else
              VSCOut.LNMeanSectorWise(nSector+2,i+1) = 0;
           end  
           
           if IEC_TI_LogNormal > LNMeanSectorWise  
             disp(['WARNING!! IEC_TI > LOGNORMAL_TI for WindSpeed : ' num2str(2*i+2) 'for sector:' ((360/(size(VSCOut.LogNormalMeanSectorWise,2)-2))*nSector)])           
             disp(['IEC_TI_LogNormal :' num2str(IEC_TI_LogNormal)])
             disp(['LOGNORMAL_TI :' num2str(logNormal_TI)]);  
             
             VSCOut.LNMeanSectorWise(nSector+2,i+1) = iec_mean;
             VSCOut.LNStdSectorWise(nSector+2,i+1) = iec_std;
           
           else
              VSCOut.LNMeanSectorWise(nSector+2,i+1) = VSCOut.LogNormalMeanSectorWise(i,nSector+2);
              VSCOut.LNStdSectorWise(nSector+2,i+1) = VSCOut.LogNormalStdSectorWise(i,nSector+2);            
           end
             
        end
                                
        if IEC_TI_LogNormal > logNormal_TI            
            disp(['WARNING!! IEC_TI > LOGNORMAL_TI for WindSpeed : ' num2str(2*i+2)])           
            disp(['IEC_TI_LogNormal :' num2str(IEC_TI_LogNormal)])
            disp(['LOGNORMAL_TI :' num2str(logNormal_TI)]);
            
            VSCOut.VTSOut(8,i+1) = iec_mean;
            VSCOut.VTSOut(9,i+1) = iec_std;
        else
            VSCOut.VTSOut(8,i+1) = VSCOut.LogNormalMean(i);
            VSCOut.VTSOut(9,i+1) = VSCOut.LogNormalStd(i);
        end
        
        VSCOut.VTSOut(7,i+1) = 1.0; % Fall Back Value
        
    end
    

           
end
 
% --- extrapolate turbulence in cells with turbulence under 0.0001 and wind
% speeds below 4 m/s and above 24 m/s.

% Add V50Turb
VSCOut.VTSOut(2,end) = max(round(VSCOut.V50+3),VSCOut.VTSOut(2,end)); 
IndexV50 = find(VSCOut.VTSOut(2,:)>VSCOut.V50);  
VSCOut.VTSOut(3:5,IndexV50) = max(MinIref(5),VSCOut.V50Turb); 

for i = 1: 4
    % minimum turbulence limit
    %%% i=1&2&3 => NTM ; i=4 => ETM; i=8 => Log_Normal_MEAN;  i=9 => Log_Normal_STD
   
    
    % minimum turbulence limit
    if i ~= 4   
        TImin = NTM(MinIref(i),VSCOut.WindSpeed);
    else
        TImin = ETM(MinIref(i),VSCOut.WindSpeed,VSCOut.MeanW,2);
    end
     
    
    % turbulence standard deviation
    Sigma = VSCOut.VTSOut(i+2,:) .* VSCOut.WindSpeed;
    
    % find turbulence std not to extrapolate
    Exp = find(Sigma > 0.001);
    
    % fit to the lowest/highest 5 values
    LowFit = Exp(1:5);
	HighFit = Exp(end-5:end-1); % EXCLUDING TI FROM V50 AS per LT comment during DNV certification. refer DMS:00285-7612.V02
    
    % low wind extrapolation based lowest 5 points
    p = polyfit(VSCOut.WindSpeed(LowFit),Sigma(LowFit),1);
    if p(1) < 0.0, p(1) = 0.0; end
    VSCOut.VTSOut(i+2,1:Exp(1)-1) = max(...
        polyval(p,VSCOut.WindSpeed(1:Exp(1)-1)) ./ VSCOut.WindSpeed(1:Exp(1)-1),...
        TImin(1:Exp(1)-1));
    
    % high wind extrapolation based highest 5 points
    p = polyfit(VSCOut.WindSpeed(HighFit),Sigma(HighFit),1);
    if p(1) < 0.0
        % if negative slope, then 'sigma' is set to the mean of the fit for
        % the higher wind speeds
        p(2) = mean(Sigma(HighFit));
        p(1) = 0.0;
    end
    Sigma = VSCOut.VTSOut(i+2,:) .* VSCOut.WindSpeed;
    ExpToFit = find(Sigma < 0.001);
    VSCOut.VTSOut(i+2,ExpToFit) = max(...
        polyval(p,VSCOut.WindSpeed(ExpToFit))  ./ VSCOut.WindSpeed(ExpToFit),...
        TImin(ExpToFit));
    clear Sigma
end

%% LN_Mean and LN_STD Extrapolation based on NTM_FAT Extrapolation values
if VSCOut.printLogNormal
           
    ntmFat = VSCOut.VTSOut(3,:); % Store NTM_Fat
    VSCOut.VTSOut(7,1) = 1;
    
    Exp_mean = find(VSCOut.VTSOut(8,:) > 0.001);
    Exp_std = find(VSCOut.VTSOut(9,:) > 0.001);
    
    % LowFit
    Lowfit_mean = Exp_mean(1:5);
    Lowfit_std = Exp_std(1:5);
    
%     Lowfit_mean = VSCOut.VTSOut(8,2:6);
%     Lowfit_std = VSCOut.VTSOut(9,2:6);
    
    %HighFit
    HighFit_mean = Exp_mean(end-5:end-1);
    HighFit_std = Exp_std(end-5:end-1);
%     HighFit_mean = VSCOut.VTSOut(8,end-5:end-1);
%     HighFit_std = VSCOut.VTSOut(9,end-5:end-1);
    
    % low wind extrapolation based lowest 5 points for LogNormal mean
    p = polyfit(VSCOut.WindSpeed(2:6),VSCOut.VTSOut(8,Lowfit_mean),1);
    VSCOut.VTSOut(8,1) = polyval(p,VSCOut.WindSpeed(1));
    % low wind extrapolation based lowest 5 points for LogNormal std
    p = polyfit(VSCOut.WindSpeed(2:6),VSCOut.VTSOut(9,Lowfit_std),1);
    VSCOut.VTSOut(9,1) = polyval(p,VSCOut.WindSpeed(1));
      
%     Iref = ntmFat(1)/(0.75+5.6/2);
%     
%     [~,ln_mean,ln_stdev]= fLogNormalTI(Iref,2);
%     VSCOut.VTSOut(8,1) = ln_mean;
%     VSCOut.VTSOut(9,1) = ln_stdev;
    
        
    % HighFit
    for i = 13 : length(ntmFat) % upto index 12 is already calculated
        
%         if ntmFat(i) >0
%             
%             Iref = ntmFat(i)/(0.75+5.6/(2*i));
%             
%             [ln_mean,ln_stdev]= fLogNormalTI(Iref,2*i);
%             
%             VSCOut.VTSOut(8,i) = ln_mean;
%             VSCOut.VTSOut(9,i) = ln_stdev;            
%         else
%             VSCOut.VTSOut(8,i) = 0;
%             VSCOut.VTSOut(9,i) = 0;                        
%         end   
        VSCOut.VTSOut(7,i) = 1;
        
       p = polyfit(VSCOut.WindSpeed(HighFit_mean),VSCOut.VTSOut(8,HighFit_mean),1); 
       VSCOut.VTSOut(8,i) = polyval(p,VSCOut.WindSpeed(i)); 
       
       p = polyfit(VSCOut.WindSpeed(HighFit_std),VSCOut.VTSOut(9,HighFit_std),1); 
       VSCOut.VTSOut(9,i) = polyval(p,VSCOut.WindSpeed(i)); 
    end
end

% --- extrapolate turbulence in cells with turbulence under 0.0001 and wind
% speeds below 4 m/s and above 24 m/s (directional)
if strcmpi(PrintMode,'d')
    errorOccured = 0;
    for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)
        % minimum turbulence limit
        TImin = NTM(MinIref(2),VSCOut.WindSpeed);
        
        % turbulence standard deviation
        Sigma = VSCOut.VTSOutNTMsectorWise(nDir+2,:) .* VSCOut.WindSpeed;
        
        % find turbulence std not to extrapolate
        Exp = find(Sigma > 0.001);
        if isempty(Exp)
            continue;
            disp('Warning! Skiping directional turbulence intensities equal zero ' );
        end
        
        % fit to the lowest/highest 5 values
        szExp = size(Exp,2);
        
        if szExp < 5
            disp(' ');
            disp('Error!!! Needs at least 5 data points to predict 2m/s which is not the case ');
            errorOccured = 1;
            break;
        end
        
        LowFit = Exp(1:5);
        HighFit = Exp(end-4:end);
        
        % low wind extrapolation based lowest 5 points
        p = polyfit(VSCOut.WindSpeed(LowFit),Sigma(LowFit),1);
        if p(1) < 0.0, p(1) = 0.0; end
        VSCOut.VTSOutNTMsectorWise(nDir+2,1:Exp(1)-1) = max(...
            polyval(p,VSCOut.WindSpeed(1:Exp(1)-1)) ./ VSCOut.WindSpeed(1:Exp(1)-1),...
            TImin(1:Exp(1)-1));
        
        % high wind extrapolation based highest 5 points
        p = polyfit(VSCOut.WindSpeed(HighFit),Sigma(HighFit),1);
        if p(1) < 0.0
            % if negative slope, then 'sigma' is set to the mean of the fit for
            % the higher wind speeds
            p(2) = mean(Sigma(HighFit));
            p(1) = 0.0;
        end
        VSCOut.VTSOutNTMsectorWise(nDir+2,Exp(end)+1:end) = max(...
            polyval(p,VSCOut.WindSpeed(Exp(end)+1:end))  ./ VSCOut.WindSpeed(Exp(end)+1:end),...
            TImin(Exp(end)+1:end));
        clear Sigma
    end
    if errorOccured
        return;
    end
    % set NTM_Fat > 24 m/s to ambient turbulence in all directions
    for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)
        if (extendbins==0)
            % set NTM_Fat > 24 m/s to ambient turbulence
            VSCOut.VTSOutNTMsectorWise(nDir+2,[13:end]) = VSCOut.VTSOut(4,[13:end]);
        end
    end
  if VSCOut.printLogNormal    
    %extrapolate LN Meand and LN std to wind speeds below 4 m/s
    for nSector = 1:size(VSCOut.LogNormalMeanSectorWise,2)-2
         % LowFit         
         Exp_mean(nSector,:) = find(VSCOut.LNMeanSectorWise(nSector+2,:) > 0.001);
         Exp_std(nSector,:) = find(VSCOut.LNStdSectorWise(nSector+2,:) > 0.001);
          
         Lowfit_mean = Exp_mean(nSector,1:5);
         Lowfit_std = Exp_mean(nSector,1:5);
          
         % low wind extrapolation based lowest 5 points for LogNormal mean
         p = polyfit(VSCOut.WindSpeed(2:6),VSCOut.LNMeanSectorWise(nSector+2,Lowfit_mean),1);
         VSCOut.LNMeanSectorWise(nSector+2,1) = polyval(p,VSCOut.WindSpeed(1));
         % low wind extrapolation based lowest 5 points for LogNormal std
         p = polyfit(VSCOut.WindSpeed(2:6),VSCOut.LNStdSectorWise(nSector+2,Lowfit_std),1);
         VSCOut.LNStdSectorWise(nSector+2,1) = polyval(p,VSCOut.WindSpeed(1));
    end

    %extrapolate LN Meand and LN std to wind speeds above 24 m/s
    for ibin = 13: size(VSCOut.LNMeanSectorWise,2)
       for nSector = 1:size(VSCOut.LogNormalMeanSectorWise,2)-2
        % HighFit
          Exp_mean_high = find(VSCOut.LNMeanSectorWise(nSector+2,:) > 0.001);
          Exp_std_high = find(VSCOut.LNStdSectorWise(nSector+2,:) > 0.001);
          
          HighFit_mean = Exp_mean_high(end-5:end-1);
          HighFit_std = Exp_std_high(end-5:end-1);
          
          % High wind extrapolation based lowest 5 points for LogNormal mean
          p = polyfit(VSCOut.WindSpeed(HighFit_mean),VSCOut.LNMeanSectorWise(nSector+2,HighFit_mean),1);
          VSCOut.LNMeanSectorWise(nSector+2,ibin) = polyval(p,VSCOut.WindSpeed(ibin));
          % High wind extrapolation based lowest 5 points for LogNormal std
          p = polyfit(VSCOut.WindSpeed(HighFit_std),VSCOut.LNStdSectorWise(nSector+2,HighFit_std),1);
          VSCOut.LNStdSectorWise(nSector+2,ibin) = polyval(p,VSCOut.WindSpeed(ibin));
       end
    end
  end
    % Add V50Turb
    VSCOut.VTSOut(2,end) = max(round(VSCOut.V50+3),VSCOut.VTSOut(2,end));
    VSCOut.VTSOutNTMsectorWise(2,end) = max(round(VSCOut.V50+3),VSCOut.VTSOutNTMsectorWise(2,end));
    IndexV50 = find(VSCOut.VTSOut(2,:)>VSCOut.V50);
    VSCOut.VTSOut(4:5,IndexV50) = max(MinIref(5),VSCOut.V50Turb);
    for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)
        IndexV50 = find(VSCOut.VTSOutNTMsectorWise(2,:)>VSCOut.V50);
        VSCOut.VTSOutNMsectorWise(nDir+2,IndexV50) = max(MinIref(5),VSCOut.V50Turb);
    end
end

% --- Hardcoded data in Prep002v05.exe
PrepV50 = [50 42.5 37.5 30; 1 2 3 4];
pos=find(PrepV50(1,:) - VSCOut.V50 >= 0);
if isempty(pos)
    VSCOut.PrepI = 1;
else
    VSCOut.PrepI = PrepV50(2,pos(end));
end

%% Compare CW and ETM - Pick max if 1 or 50 year TI is present otherwise report CW
VSCOut = compare_CW_ETM(VSCOut); 

%% correct extreme wind speeds
VSCOut = correctETM(VSCOut); 

%% Print file

if strcmpi('d',PrintMode)
    PrintFile_Directional(VSCOut)
else
    PrintFile(VSCOut)
end


end

function Rho = CalcAirDensity(T,h)
% formulat : http://en.wikipedia.org/wiki/Density_of_air
p0 = 101325;    % pa
T0 = 288.15;    % K
g = 9.80665;    % m/s^2
L = 0.0065;     % K/m
R = 8.31447;    % J/(mol K)
M = 0.0289644;  % kg/mol

% Mean density
Temp = 273.15 + T;
p = p0 * ( 1 - ((L*h)/T0))^( (g*M)/(R*L) );
Rho = (p*M) / (R*Temp);
end

function Turb = NTM(Iref,Vhub)
Turb = Iref * ( 0.75 * Vhub + 5.6 ) ./ Vhub;
end

function Turb = ETM(Iref,Vhub,MeanW,c)
Turb = c*Iref*(0.072*((MeanW/c) + 3)*((Vhub/c) - 4) + 10) ./ Vhub;
end

 %% Calculation of log normal Parameters of TI 
function [TI,ExpectedValue,stdev]= fLogNormalTI(Iref,Vhub)
    
    ExpectedValue = Iref * ( 0.75 * Vhub + 3.8 )./Vhub;
    
    stdev = (Iref * 1.4)./Vhub;      
    
    TI = ExpectedValue + 1.28* stdev;
        
end

    
%% Read Turbine Label and turbulence of worst extreme turbulence
% This is for 'ETM'...
function VSCOut = ReadETMTurb(VSCOut,C)

VSCOut.IEC_ETM = false;
NoTurbine = VSCOut.Turbine_Count;
VSCOut.ETMWTGLabel = VSCOut.AmbWTGLabel;

% get full turbine label
key = 'Turbine distances';
pos = GetPosOfKeyFromClmFile(C{1} , key);
for Turbine = 1:NoTurbine
    Line = C{1}{pos+2+Turbine};
    StrTemp = textscan(Line,'%12c %*200c');
    if strncmpi(StrTemp{1},VSCOut.ETMWTGLabel{Turbine},length(VSCOut.ETMWTGLabel{Turbine}));
        VSCOut.ETMWTGLabel{Turbine} = deblank(StrTemp{1});
    end
end

for Turbine = 1:NoTurbine
    
    % -- find the line number/index for the worst fatigue loaded turbine
    key = 'Wind Turbine number:';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    AllTurbines = size(pos,1);
    for i=1:AllTurbines
        Index = strfind(C{1}{pos(i)},'Label:');
        StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
        if strcmp(VSCOut.ETMWTGLabel{Turbine},StrTemp)
            WTGLine = pos(i);
            WTGIndex = i;
            break;
        elseif i == AllTurbines
            disp(['Turbine label: ' VSCOut.ETMWTGLabel{Turbine} ' - No found']);
            return;
        end
    end
    
    % -- extract wind distribution values
    UpdateOfLayoutClimate = false;
    key = 'Wind Distribution:';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    if isempty(pos) % update to outfile layout
        key = 'Climatic conditions:';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        UpdateOfLayoutClimate = true;
    end
    pos = pos(WTGIndex);
    if VSCOut.VSCnet
        if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end
    else skipLines = 4; end
    
    lineToRead = pos+skipLines;
    % - Vhub avg.
    StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
    MeanW = str2double(StrTemp{1}{4}); 
    % -- extract the extreme turbulence level
    % if do no exist then calc ETM based on climate data
    [fiftY_Ti_Data, fiftY_TI_Pos] = CheckTableData(C, WTGIndex,'Extreme 50 year ambient turbulence intensity');   %function to check the availability of 50 year TI table and data
    [fiftY_Ti_Data_1, fiftY_TI_Pos_1] = CheckTableData(C, WTGIndex,'Extreme Turbulence Intensities based on IEC 61400-1 ed.4');
    [Annual_Ti_Data, EATI_Pos] = CheckTableData(C, WTGIndex,'Extreme annual ambient turbulence intensity');       %function to check the availability of annual ambient TI table and data
    [Wake_Ti_Data, EWTI_Pos] = CheckTableData(C, WTGIndex,'Extreme annual wake turbulence intensity');            %function to check the availability of annual wake TI table and data
    if(fiftY_Ti_Data) || (fiftY_Ti_Data_1)
        if(fiftY_Ti_Data)
            lineToRead = fiftY_TI_Pos(WTGIndex)+2;
        else
            lineToRead = fiftY_TI_Pos_1(WTGIndex)+1;
        end
   
        for i = 1:11
            Strtmp = textscan(C{1}{lineToRead+i},'%s') ;    %scan entire row of extreme 50 year ambient turbulence intensity data
            for x = 3:length(Strtmp{1})                                    %iterate through each sector
               AmbientTurbInt(x-2)=str2num(Strtmp{1}{x});      
            end    
            ETMTurb(i) = max(AmbientTurbInt);
        end        
    elseif((Annual_Ti_Data) || (Wake_Ti_Data))     %Checking presence of annual/wake TI and the table is populated with data instead of "Not Calculated"
        if(Annual_Ti_Data)
            lineToRead = EATI_Pos(WTGIndex)+2;
        else
            lineToRead = EWTI_Pos(WTGIndex)+2;
        end
        Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        for i = 1:11
            Vhub = (2+2*i);
            Strtmp = textscan(C{1}{lineToRead+i},'%s') ;    %scan entire row of extreme annual ambient turbulence intensity data
            for x = 3:length(Strtmp{1})                                    %iterate through each sector
               AmbientTurbInt(x-2)=str2num(Strtmp{1}{x});      
            end    
            ETMTurb(i) = max(AmbientTurbInt) * (ETM(Iref,Vhub,MeanW,2)/ETM(Iref,Vhub,MeanW,1.7));
        end
    elseif (GetPosOfKeyFromClmFile(C{1,1} , 'Overall extreme annual wake turbulence and load')) % This is added for backward compatinily for old turbine (Pre M3E)
        key = 'Overall extreme annual wake turbulence and load';
        pos = GetPosOfKeyFromClmFile(C{1,1} , key);
        pos = pos(WTGIndex);
        skipLines = 1;
        lineToRead = pos+skipLines;
        Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        for i = 1:11
            Vhub = (2+2*i);
            StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
            ETMTurb(i) = str2num(StrTemp{1}{3}) * (ETM(Iref,Vhub,MeanW,2)/ETM(Iref,Vhub,MeanW,1.7));
        end  
    else
        % Iref = mean ambient turb at 15 m/s
        if VSCOut.NoSAmbTurb{1} == 1
            % Iref = mean(VSCOut.MeanAmbTurb{1}(6:7,1)); % - Old Implementation
            Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        elseif VSCOut.NoSAmbTurb{1} == VSCOut.NoSWindParameters
            % I14 = sum(( VSCOut.MeanAmbTurb{1}(6,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation
            % I16 = sum(( VSCOut.MeanAmbTurb{1}(7,:)) .* VSCOut.Prob)/sum(VSCOut.Prob); % - Old Implementation
            % Iref = mean([I14 I16]);                                                   % - Old Implementation
            Iref = mean(VSCOut.SiteTI90{Turbine}(6:7))/((0.75*15+5.6)/15); % calulation Iref based on 90% quintile of the ambient turbulence
        end
        c = 2;
        for i = 1:11
            Vhub = (2+2*i);
            ETMTurb(i) = ETM(Iref,Vhub,VSCOut.MeanW,c);
        end
        VSCOut.IEC_ETM = true;
    end
    
    
    for WindSpeed = 1:11
        if ETMTurb(WindSpeed) == 0
            VSCOut.MaxETM(WindSpeed) = 0.0;
            VSCOut.MaxETMLabel{WindSpeed} = '-';
        else
            if Turbine == 1
                VSCOut.MaxETM(WindSpeed) = ETMTurb(WindSpeed);
                VSCOut.MaxETMLabel{WindSpeed} = VSCOut.ETMWTGLabel{Turbine};
            else
                if ETMTurb(WindSpeed) > VSCOut.MaxETM(WindSpeed)
                    VSCOut.MaxETM(WindSpeed) = ETMTurb(WindSpeed);
                    VSCOut.MaxETMLabel{WindSpeed} = VSCOut.ETMWTGLabel{Turbine};
                end
            end
        end
    end
    
end;

end

function [IsDataPresent, pos] = CheckTableData(C, WTGIndex, TableTitle)      %function used to check availability of table and data
        pos = GetPosOfKeyFromClmFile(C{1} , TableTitle);
        if(pos)                  
            first_line = string(C{1}{pos(WTGIndex)+2});
            IsDataPresent = first_line ~= 'Not calculated';   %this returns true if the table has sectorwise data
        else      
            IsDataPresent = false;
        end
end
%% Read Turbine Label
function VSCOut = ReadTurbineData(VSCOut, C)
key = 'WTGLabelLongitude';
D = C;
for i = 1:length(C{1})
    D{1}{i} = C{1}{i}(find(~isspace(C{1}{i}))); %crunched all line to read exact string
end
pos = GetPosOfKeyFromClmFile(D{1} , key);
linesListFromClmFile = GetLinesListFromClmFile_fromPOS(C{1} , pos, 0, -1);
[nRowofTable , mTurbines] = size(linesListFromClmFile);
temp = 1;
for i= 1:nRowofTable
    singleLine = strsplit_LMT(linesListFromClmFile{i,1},'	');
    LineToTable = singleLine(strcmpi(singleLine(1:end), '')==0);
    if strcmpi(LineToTable(1, 5), 'New')
        dataTable{temp,1} = char(LineToTable(1, 1));
        temp =temp+1;
    end
end
VSCOut.AmbWTGLabel = dataTable';
VSCOut.Turbine_Count = size(dataTable,1);
end

%% Read Turbine Label and turbulence of worst ambient turbulence
% This is for DETwind and NTM_Ext
function VSCOut = ReadAmbTurb(VSCOut,C)

NoTurbine = VSCOut.Turbine_Count;


wtgKey = 'Wind Turbine number:';

wtgPos = GetPosOfKeyFromClmFile(C{1} , wtgKey);

for Turbine = 1:NoTurbine
    
    % -- find the line number/index for the worst fatigue loaded turbine    
    Index = strfind(C{1}{wtgPos(Turbine)},'Label:');
    StrTemp = strtrim(C{1}{wtgPos(Turbine)}(Index+7:end));
    WTGIndex = find(strcmpi(VSCOut.AmbWTGLabel,StrTemp));
    
    
    % -- extract the mean ambient turbulence
    key = 'Distribution of Mean Ambient';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    pos = pos(WTGIndex);
    if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
    lineToRead = pos+skipLines;
    for i = 1:11
        StrTemp = textscan(C{1}{lineToRead+i},'%s');
        if (size(StrTemp{1},1)==15 || size(StrTemp{1},1)==39 || size(StrTemp{1},1)==19), startline = 4; else startline = 3; end
        for j = startline:size(StrTemp{1},1)
            VSCOut.MeanAmbTurb{Turbine}(i,j-(startline-1)) = str2num(StrTemp{1}{j});
        end
    end
    VSCOut.NoSAmbTurb{Turbine} = size(VSCOut.MeanAmbTurb{Turbine},2);
    
    % -- extract the std of the ambient turbulence
    key = 'Distribution of Std. Dev. of Ambient';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    pos = pos(WTGIndex);
    if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
    lineToRead = pos+skipLines;
    for i = 1:11
        StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
        if (size(StrTemp{1},1)==15 || size(StrTemp{1},1)==39 || size(StrTemp{1},1)==19), startline = 4; else startline = 3; end
        for j = startline:size(StrTemp{1},1)
            VSCOut.StdAmbTurb{Turbine}(i,j-(startline-1)) = str2num(StrTemp{1}{j});
        end
    end
    
    
    % NTM_EXT
    key = 'Directional Turbulence Intensities m = 1';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    WohlerM1IsAvailable = false;
    if length(pos) > 2
        if pos(2)-pos(1) < 20
            WohlerM1IsAvailable = true;
        end
    end
    VSCOut.EffTIm1Read = false;
    if length(pos) > NoTurbine
        if WohlerM1IsAvailable
            % read wohler m=1
            VSCOut.EffTIm1Read = true;
            pos = pos(2*WTGIndex);
            if VSCOut.VSCnet, skipLines = 1; else skipLines = 1; end
            lineToRead = pos+skipLines;
            for i = 1:11
                StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
                VSCOut.EffTIm1{Turbine}(i) = str2num(StrTemp{1}{2});
            end
        else
            % read wohler m=4
            VSCOut.EffTIm1Read = true;
            key = 'Effective Turbulence Intensities in Wind Farm';
            pos = GetPosOfKeyFromClmFile(C{1} , key);
            pos = pos(WTGIndex);
            if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
            lineToRead = pos+skipLines;
            for i = 1:11
                StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
                VSCOut.EffTIm1{Turbine}(i) = str2num(StrTemp{1}{2});
            end
        end;
    end

    
%     % Read wohler m=1
%     key = 'Directional Turbulence Intensities m = 1';
%     pos = GetPosOfExactWordKeyFromClmFile(C{1} , key);
%     if isempty(pos)        
%         % read wohler m=4
%         key = 'Effective Turbulence Intensities in Wind Farm';
%         pos = GetPosOfExactWordKeyFromClmFile(C{1} , key);
%         
%     end
%      
%     VSCOut.EffTIm1Read = false;    
%     if ~isempty(pos) && length(pos) == NoTurbine
%         VSCOut.EffTIm1Read = true;
%         pos = pos(WTGIndex);
%         if VSCOut.VSCnet && strcmp(key,'Effective Turbulence Intensities in Wind Farm')
%             skipLines = 2;
%         else
%             skipLines = 1;
%         end
%         lineToRead = pos+skipLines;
%         for i = 1:11
%             StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
%             VSCOut.EffTIm1{Turbine}(i) = str2double(StrTemp{1}{2});
%         end
%     end
    
   
    % --- calculation the 90% quantile of the ambient turbulence on site (LT) - Based on one prob per direction per wind speed
    for i = 1:11
        Mean_a(i) = sum(VSCOut.MeanAmbTurb{Turbine}(i,:) .* (VSCOut.AmbProbWS{Turbine}(i,:)/sum(VSCOut.AmbProbWS{Turbine}(i,:))));
        Std_a(i)  = sqrt( sum( (VSCOut.AmbProbWS{Turbine}(i,:)/sum(VSCOut.AmbProbWS{Turbine}(i,:))) .* (VSCOut.MeanAmbTurb{Turbine}(i,:).^2 + VSCOut.StdAmbTurb{Turbine}(i,:).^2) ) - Mean_a(i)^2);
        VSCOut.SiteTI90{Turbine}(i) = Mean_a(i) + 1.28*Std_a(i);
    end
    
    for WindSpeed = 1:11
        if Turbine == 1
            % Save ambinet turbulence
            VSCOut.MaxAmbTI90(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
            VSCOut.MaxAmbTI90Label{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            % save NTM_Ext (if EffTIm=1 exist use this else background turb)
            if VSCOut.EffTIm1Read
                VSCOut.NTMext(WindSpeed) = VSCOut.EffTIm1{Turbine}(WindSpeed);
                VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            else
                VSCOut.NTMext(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            end
        else
            % Save ambinet turbulence
            if VSCOut.SiteTI90{Turbine}(WindSpeed) > VSCOut.MaxAmbTI90(WindSpeed)
                VSCOut.MaxAmbTI90(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                VSCOut.MaxAmbTI90Label{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
            end
            % save NTM_Ext (if EffTIm=1 exist use this else background turb)
            if VSCOut.EffTIm1Read
                if VSCOut.EffTIm1{Turbine}(WindSpeed) > VSCOut.NTMext(WindSpeed)
                    VSCOut.NTMext(WindSpeed) = VSCOut.EffTIm1{Turbine}(WindSpeed);
                    VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
                end
            else
                if VSCOut.SiteTI90{Turbine}(WindSpeed) > VSCOut.NTMext(WindSpeed)
                    VSCOut.NTMext(WindSpeed) = VSCOut.SiteTI90{Turbine}(WindSpeed);
                    VSCOut.NTMextLabel{WindSpeed} = VSCOut.AmbWTGLabel{Turbine};
                end
            end
        end
    end
    
end
end


%% Read Windspeed Probability
function VSCOut = ReadWSProb(VSCOut,C)
    NoTurbine = VSCOut.Turbine_Count;

    for Turbine = 1 : NoTurbine
                
        % -- find the line number/index for the worst fatigue loaded turbine
        key = 'Wind Turbine number:';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        AllTurbines = size(pos,1);
        for i=1:AllTurbines
            Index = strfind(C{1}{pos(i)},'Label:');
            StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
            if strcmp(VSCOut.AmbWTGLabel{Turbine},StrTemp)
                WTGLine = pos(i);
                WTGIndex = i;
                break;
            elseif i == AllTurbines
                disp(['Turbine label: ' VSCOut.AmbWTGLabel{Turbine} ' - No found']);
                return;
            end
        end
        
         % Get probablity
        VSCOut = fWindSpeedProb(VSCOut,C,Turbine,WTGIndex);
        
        
        % -- Extract the Wind Sector Management parameters, if applicable
        key = 'Wind sector management  :';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        pos = pos(WTGIndex);
        WSMtest1 = pos + 2;
        WSMtest2 = pos + 3;
        VSCOut.WSMAvilable(Turbine) = false;
        if VSCOut.VSCnet
            if (isempty(C{1}{WSMtest1})==0) && (isempty(C{1}{WSMtest2})==0)
                if C{1}{WSMtest2}
                    lineToRead = WSMtest1;
                    kk=1;
                    for i=1:4
                        if ~isempty(C{1}{lineToRead+i})
                            StrTemp = textscan(C{1}{lineToRead+i},'%s');
                            if size(StrTemp{1},1) == 3 | size(StrTemp{1},1) == 4
                                for j = 1:3%size(StrTemp{1},1)
                                    VSCOut.WSMTurb{Turbine}(kk,j) = str2num(StrTemp{1}{j});
                                    VSCOut.WSMAvilable(Turbine) = true;
                                end
                                kk=kk+1;
                            end
                        end
                    end
                end
            end
        end
        
        % reduce wind destribution according to WSM
        if VSCOut.WSMAvilable(Turbine)
            for j = 1:size(VSCOut.WSMTurb{Turbine},1)
                bin_spacing = 360/size(VSCOut.AmbProb{Turbine},2);
                bin_center = 0:bin_spacing:359;
                n_bin = 360/bin_spacing;
                
                WSM_start =VSCOut.WSMTurb{Turbine}(j,1);
                if WSM_start > bin_center(end)+bin_spacing/2; WSM_start = WSM_start -360; end;
                WSM_end   =VSCOut.WSMTurb{Turbine}(j,2);
                if WSM_end > bin_center(end)+bin_spacing/2; WSM_end = WSM_end -360; end;
                
                AllTheWayAround = false;
                if (WSM_start == WSM_end) | (WSM_start == 0 & WSM_end == 360)
                    AllTheWayAround = true;
                end
                
                WSM_WS    =VSCOut.WSMTurb{Turbine}(j,3);
                
                [~, index_start] = min(abs(bin_center-WSM_start));
                [~, index_end] = min(abs(bin_center-WSM_end));
                if index_end < index_start
                    index = [index_start:n_bin 1:index_end];
                elseif AllTheWayAround
                    index = 1:n_bin;
                else
                    index = index_start:index_end;
                end
                
                firstFind = true;
                for i = 1:11
                    WS_start = 1 + i*2;
                    WS_end = 3 + i*2;
                    if j == 1
                        %VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.AmbProb{Turbine};
                        VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.WeibullProbWSandDir(i,:);
                    end
                    
                    if WS_end > WSM_WS
                        if firstFind
                            WSM_probWS = ((WS_end - WSM_WS) / 2);
                            firstFind = false;
                        else
                            WSM_probWS = 1;
                        end
                        for jj = index
                            if jj == index_start
                                WSM_probdir = 1-((bin_center(jj)+bin_spacing/2)-WSM_start) / bin_spacing;
                            elseif jj == index_end
                                WSM_probdir = 1-(WSM_end - (bin_center(jj)-bin_spacing/2)) / bin_spacing;
                            else
                                WSM_probdir = 0;
                            end
                            if WSM_probdir == 1
                                WSM_probdirTot = WSM_probdir;
                            else
                                WSM_probdirTot = WSM_probdir * WSM_probWS;
                            end
                            if AllTheWayAround, WSM_probdir = 0; end
                            
                            VSCOut.AmbProbWS{Turbine}(i,jj) = VSCOut.AmbProbWS{Turbine}(i,jj) * WSM_probdirTot;
                        end
                    end
                end
            end
        else
            for i = 1:11
                %VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.AmbProb{Turbine};
                VSCOut.AmbProbWS{Turbine}(i,:) = VSCOut.WeibullProbWSandDir(i,:);
            end
        end
        
    end

end
%% Read Turbine Label and turbulence of worst fatigue loaded turbine depending on input
% This is for NTM_Fat...
function VSCOut = ReadNTMFat(VSCOut,C,Component,WTGID)
%default option is 'E'
default = false;
% Component = input('Select letter above (default = E) : ','s');
if isempty(Component)
    Component = 'E';
    default = true;
end;

result = strfind('abcdef',lower(Component));
if ~default
    while isempty(result)
        Component = input('Error in input. Please select letter above (a, b, c, d, e, or f) : ','s');
        result = strfind('abcdef',lower(Component));
    end
end

% Read data from Worst case relative loads
switch lower(Component)
    case 'a'
        VSCOut.FileNameExtemsion = '_m=10';
        type = '_m=10';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        skipLines = 3;
        lineToRead = pos(1) + skipLines;
        MaxRelLoad = 0;
        for i = 1:4
            if VSCOut.VSCnet
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %*s %*s %f %10c %[^#]');
            else
                [RelLoad{i,1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %f %10c %[^#]');
            end
            if RelLoad{i}{1} > MaxRelLoad
                MaxRelLoad = RelLoad{i}{1};
                Index = i;
            end
            lineToRead = lineToRead + 1;
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{Index}{2});
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = 'Worst fatigue blade loads';
    case 'b'
        % Hub, DriveTrain, Nacelle
        VSCOut.FileNameExtemsion = '_m=8';
        typePos = 3;% '_m=8';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        
        posPart= GetPosOfKeyAfterKeyFromClmFile(C{1} ,'Hub',pos(1));
        posSensor = 2:3;
        lineToRead = posPart+posSensor;
        
        posTower = GetPosOfKeyAfterKeyFromClmFile(C{1} ,'DriveTrain',pos(1));
        posSensor = 2:4;
        lineToRead = [lineToRead,posTower+posSensor];
        
        posTower = GetPosOfKeyAfterKeyFromClmFile(C{1} ,'Nacelle',pos(1));
        posSensor = 2:5;
        lineToRead = [lineToRead,posTower+posSensor];
        
        
        RelLoad = cell(0);
        for i=lineToRead
            if VSCOut.VSCnet
                RelLoad = [RelLoad;textscan(C{1}{i},'%*s %f %10c %f %10c %[^#]');];
            else
                RelLoad = [RelLoad;textscan(C{1}{i},'%*28c %f %10c %f %10c %[^#]')];
            end
        end
       
        RelLoad(cellfun(@isempty,RelLoad)) = {0};
        [~,maxWTGi] = max([RelLoad{:,typePos}]);
             
        VSCOut.FatWLTLabel = deblank(RelLoad{maxWTGi,typePos+1});  
        VSCOut.TIefftWholer = 8;
        VSCOut.FatTopText = 'Worst fatigue Hub, DriveTrain, Nacelle loads';
    case 'c'
        % Tower
        VSCOut.FileNameExtemsion = '_m=4';
        typePos = 1;%'_m=4';
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        posPart = GetPosOfKeyAfterKeyFromClmFile(C{1} ,'Tower',pos(1));
        posSensor = 2:6;
        lineToRead = posPart+posSensor;
        
        RelLoad = cell(0);
        for i=lineToRead
            if VSCOut.VSCnet
                RelLoad = [RelLoad;textscan(C{1}{i},'%*s %f %10c %[^#]')];
            else
                RelLoad = [RelLoad;textscan(C{1}{i},'%*s %*s %*s %*s %f %10c %[^#]')];
            end
        end
        
        RelLoad(cellfun(@isempty,RelLoad)) = {0};
        [~,maxWTGi] = max([RelLoad{:,typePos}]);
     
        VSCOut.FatWLTLabel = deblank(RelLoad{maxWTGi,typePos+1});      
        VSCOut.TIefftWholer = 4;
        VSCOut.FatTopText = 'Worst fatigue tower loads';
    case 'd' %%WTG index is wrong, cause of hardcoding 
        VSCOut.FileNameExtemsion = '_TWR_m=8';
        type = '_TWR_m=8'; 
        
        key = '*** RELATIVE LOADS [%] ***';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        if VSCOut.VSCnet, skipLines = 38 + VSCOut.extralinesaddedMrTT + VSCOut.extralinesaddedMrTB; else skipLines = 28; end
        lineToRead = pos(1) + skipLines;
        if VSCOut.VSCnet
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %f %10c %f %10c');
        else
            [RelLoad{1}] = textscan(C{1}{lineToRead},'%*s %*s %*s %*s %f %10c %[^#]');
        end
        VSCOut.FatWLTLabel = deblank(RelLoad{1}{4});
        VSCOut.TIefftWholer = 8;
        VSCOut.FatTopText = 'Worst fatigue tower loads';
    case 'e'
        VSCOut.FileNameExtemsion = '_WorstCase';
        type = '_WorstCase';
        
        key = 'Effective turbulence intensities for the highest loaded turbines - ';
        pos = GetPosOfKeyFromClmFile(C{1} , key);
        if (VSCOut.VSCnet)
            if VSCOut.VSCnetVersion == 1, skipLines = 2; else skipLines = 1; end
        else skipLines = 1; 
        end   
        lineToRead = pos + skipLines;
        Dummy = textscan(C{1}{lineToRead},'%*s WTG No. %10c WTG No. %10c WTG No. %10c WTG No. %10c'); 
        if isempty(Dummy{1}) % 1.5.6 Updated 
            Dummy = textscan(C{1}{lineToRead},'%*s %10c %10c  %10c  %10c'); 
        end  
        Dummy = strtrim(Dummy);
        VSCOut.FatWLTLabel = strtrim(Dummy{1});
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = 'Worst fatigue loaded turbine';
    case 'f'
        if isempty(WTGID)
            disp(' ');
            disp('Turbine labels:')
            % list the turbine labels
            NoTurbine = VSCOut.Turbine_Count;
            FatWTGLabel = VSCOut.AmbWTGLabel;
            for i=1:NoTurbine
                fprintf(' %12s ',[FatWTGLabel{i}]);
                if mod(i,5) == 0
                    fprintf('\n');
                end
            end
            disp(' ');
            WTGID = input('Please enter the WTG Label of the turbine you want to analyze: ','s');
        end
        VSCOut.FileNameExtemsion = ['_WTG_', WTGID];
        
        VSCOut.FatWLTLabel = WTGID;
        VSCOut.TIefftWholer = 10;
        VSCOut.FatTopText = ['WTG Label',WTGID];
        
end

%% Read VSC output for worst loaded turbine
% -- find the line number/index for the worst fatigue loaded turbine
key = 'Wind Turbine number:';
pos = GetPosOfKeyFromClmFile(C{1} , key);
NoTurbines = size(pos,1);
VSCOut.PosChoosenTurbine= [];


if(strcmp(lower(Component),'d') && isempty(VSCOut.FatWLTLabel))
    VSCOut.FatWLTLabel = 'T8';
end
for i=1:NoTurbines
    Index = strfind(C{1}{pos(i)},'Label:');
    StrTemp = strtrim(C{1}{pos(i)}(Index+7:end));
    if strcmp(VSCOut.FatWLTLabel,StrTemp)
        WTGLine = pos(i);
        WTGIndex = i;
        VSCOut.PosChoosenTurbine = i;
        break;
    elseif i == NoTurbines
        disp(['Turbine label: ' VSCOut.FatWLTLabel ' - No found']);
        
    end
end
% -- extract the effective turbulence at different wh�ler values
% Effective Turbulence Intensities in Wind Farm
% Vhub  m = 4.0   m = 8.0   m = 10.0  m = 3.3   m = 5.7   m = 8.7

key = 'Effective Turbulence Intensities in Wind Farm';
pos = GetPosOfKeyFromClmFile(C{1} , key);
pos = pos(WTGIndex);
if VSCOut.VSCnet, skipLines = 2; else skipLines = 1; end
lineToRead = pos+skipLines;
for i = 1:11
    StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
    for j = 2:size(StrTemp{1},1)
        VSCOut.EffTurb(i,j-1) = str2num(StrTemp{1}{j});
    end
end


% -- extract the sectorwise effective turbulence at different wholer values
% Directional Turbulence Intensities m = *
% Vhub  m = 4.0   m = 8.0   m = 10.0  m = 3.3   m = 5.7   m = 8.7

key = (['Directional Turbulence Intensities m = ' num2str(VSCOut.TIefftWholer,'%.0f')]);
pos = find(strncmpi(key,C{1},length(key)) == 1);
pos = pos(WTGIndex);
if VSCOut.VSCnet, skipLines = 1; else skipLines = 1; end
lineToRead = pos+skipLines;
for i = 1:11
    StrTemp = textscan(C{1}{lineToRead+i},'%s') ;
    for j = 3:size(StrTemp{1},1)
        VSCOut.EffTurb_SectorWise(i,j-2) = str2num(StrTemp{1}{j});
    end
end

% -- extract wind distribution values
UpdateOfLayoutClimate = false;
key = 'Wind Distribution:';
pos = GetPosOfKeyFromClmFile(C{1} , key);
if isempty(pos) % update to outfile layout
    key = 'Climatic conditions:';
    pos = find(strncmpi(key,C{1},length(key)) == 1);
    UpdateOfLayoutClimate = true;
end
pos = pos(WTGIndex);
if VSCOut.VSCnet
    if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end
else skipLines = 4; end

lineToRead = pos+skipLines;
% - Probability
StrTemp = textscan(C{1}{lineToRead},'%s') ;
for j = 4:size(StrTemp{1},1)
    VSCOut.Prob(j-3) = str2double(StrTemp{1}{j}); end
VSCOut.NoSWindParameters = size(VSCOut.Prob,2);
% - Vhub avg.
StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
VSCOut.MeanW = str2double(StrTemp{1}{4});
for j = 5:size(StrTemp{1},1)
    VSCOut.SecMeanW(j-4) = str2double(StrTemp{1}{j}); end
% - Weibull A
StrTemp = textscan(C{1}{lineToRead+2},'%s') ;
VSCOut.WeibA = str2double(StrTemp{1}{4});
for j = 5:size(StrTemp{1},1)
    VSCOut.SecWeibA(j-4) = str2double(StrTemp{1}{j}); end
% - Weibull k
StrTemp = textscan(C{1}{lineToRead+3},'%s') ;
VSCOut.Weibk = str2double(StrTemp{1}{4});
for j = 5:size(StrTemp{1},1)
    VSCOut.SecWeibk(j-4) = str2double(StrTemp{1}{j}); end
% - Inflow
StrTemp = textscan(C{1}{lineToRead+4},'%s') ;
for j = 3:size(StrTemp{1},1)
    VSCOut.Inflow(j-2) = str2double(StrTemp{1}{j}); end
% - Wind Shear
StrTemp = textscan(C{1}{lineToRead+5},'%s') ;
for j = 4:size(StrTemp{1},1)
    VSCOut.WindShear(j-3) = str2double(StrTemp{1}{j}); end



end

%% Read site variable
% air density, V50, Ve50, V50Turb
function VSCOut = ReadSiteVar(VSCOut,C)

% -- Mean hub height
key = 'Summary of climatic conditions';
pos = GetPosOfKeyFromClmFile(C{1} , key);
StrTemp = textscan(C{1}{pos+4},'%*s %*s %*s %f');
VSCOut.HubHeightAvg = StrTemp{1};


% -- air density
key = 'Height above sea level';
pos = GetPosOfKeyFromClmFile(C{1} , key);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %f %*s %f');
VSCOut.SiteHeightAvg = mean([StrTemp{1} StrTemp{2}]);
VSCOut.SiteHeightMin = min([StrTemp{1} StrTemp{2}]);

key = 'Average annual ambient temperature';
pos = GetPosOfKeyFromClmFile(C{1} , key);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.TempAvg = StrTemp{1};
StrTemp = textscan(C{1}{pos+1},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.TempMin = StrTemp{1};

if VSCOut.VSCnet
    key = 'Air density - average';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %f');
    VSCOut.RhoAvg = StrTemp{1};
    StrTemp = textscan(C{1}{pos+1},'%*s %*s %*s %*s %*s %f');
    VSCOut.RhoMax = StrTemp{1};
else
    % Mean density
    VSCOut.RhoAvg = CalcAirDensity(VSCOut.TempAvg,VSCOut.SiteHeightAvg + VSCOut.HubHeightAvg);
    
    % Max density
    % add 25 [deg c] as per new guideline
    VSCOut.RhoMax = CalcAirDensity(VSCOut.TempMin + 25,VSCOut.SiteHeightMin + VSCOut.HubHeightAvg);
end

% compensate for high density
VSCOut.RhoAvgFat = VSCOut.RhoAvg;
VSCOut.RhoAvgExt = VSCOut.RhoMax;
if VSCOut.RhoMax > VSCOut.RhoAvg
    VSCOut.RhoAvgExt = VSCOut.RhoAvg;
end

% -- V50
VSCOut.keyV50 = 'Maximum 10 min. average wind speed';
pos = GetPosOfKeyFromClmFile(C{1} , VSCOut.keyV50);
StrTemp  = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %*s %f');
VSCOut.V50 = StrTemp{1};

% -- Ve50
VSCOut.keyVe50 = 'Static gust wind speed';
pos = GetPosOfKeyFromClmFile(C{1} , VSCOut.keyVe50);

if isempty(pos)
    disp('WARNING! Can not find "Static gust wind speed" keyword');
end

VSCOut.keyVe50 = strip(extractBefore(C{1}{pos},'[m/s]'),'right');
%StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %*s %*s %f');
StrTemp = regexp(C{1}{pos},'[\d\.]+\s*$','match');
StrTemp{1} = str2double(StrTemp{1});
VSCOut.Ve50 = StrTemp{1};

% -- Ve50
keyV50Turb = 'Turbulence at extreme wind speed';
pos = GetPosOfKeyFromClmFile(C{1} , keyV50Turb);
StrTemp = textscan(C{1}{pos},'%*s %*s %*s %*s %*s %*s %f');
VSCOut.V50Turb = StrTemp{1}/100;

end

% Compare CW and ETM - Pick max if 1 or 50 year TI is present otherwise report CW
function [VSCOut] = compare_CW_ETM(VSCOut) 
ETMpos = 6;
for i = 1:size(VSCOut.WindSpeed,2)
    if VSCOut.IEC_ETM
        VSCOut.VTSOut(ETMpos,i) = VSCOut.MaxCW(i) ;
        if i > 1 && i < 13
            VSCOut.MaxETMLabel{i-1} = VSCOut.MaxCWLabel{i-1} ;      
        end
    else
        if VSCOut.MaxCW(i) > VSCOut.VTSOut(ETMpos,i)
            VSCOut.VTSOut(ETMpos,i) = VSCOut.MaxCW(i) ;
            if i > 1 && i < 13
                VSCOut.MaxETMLabel{i-1} = VSCOut.MaxCWLabel{i-1} ;      
            end
        end
    end
end  
end


function [VSCOut] = correctETM(VSCOut) 
% %position of ETM and NTM turb in the structutre
ETMpos = 6;
NTMpos = 5;
windSpeedLowerPos = 1;
windSpeedUpperPos = 2;
B = 5.6; % B CONSTANT AS per IEC ED3 EQ.11
C = 2; % C CONSTANT AS per IEC ED3 EQ.19
for i = 1:size(VSCOut.WindSpeed,2)
% check if ETM is lesser than NTM
  if VSCOut.VTSOut(ETMpos,i) < VSCOut.VTSOut(NTMpos,i)
      windSpeed = (VSCOut.VTSOut(windSpeedLowerPos,i)+ VSCOut.VTSOut(windSpeedUpperPos,i))/2;
      TI = max(VSCOut.VTSOut(3:6,i));
      % calculate IREF as per IECed3 Eq. 11
      Iref = TI*windSpeed/(0.75*windSpeed+	B);
      % calculate ETM AS per IEC ED3 EQ.19
      VSCOut.VTSOut(ETMpos,i) = C * Iref*(0.072*((VSCOut.MeanW/C)+3)* (((windSpeed/C)-4))+10);  
      VSCOut.VTSOut(ETMpos,i) = VSCOut.VTSOut(ETMpos,i)/windSpeed;
  end   
end  
end


%% Print file
function PrintFile(VSCOut)
Filename = strrep(VSCOut.NAME,' ','_');
fid = fopen(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']),'wt+');
fprintf(fid,'Vestas Site Check Project Name: ''%s'' - %s is turbine label: ''%s'' - NTM_Fat: m = %4.2f\n',VSCOut.ProjectName, VSCOut.FatTopText, VSCOut.FatWLTLabel, VSCOut.TIefftWholer);
fprintf(fid,'ieced3  %i                              reference standard, windpar\n',VSCOut.PrepI);
fprintf(fid,'ieced3  %i 0.01 2                       iecgust windpar, iecgust turbpar, a (dummy if IECed3)\n',VSCOut.PrepI);
if VSCOut.printLogNormal
    fprintf(fid,'LNTable  0.01  %i 2  %s                     Turbulence standard, turbpar, a (dummy if IECed3), additional factor, No. of Quantiles\n',VSCOut.PrepI,VSCOut.lognormalQuantile);
else
    fprintf(fid,'VSCTable  0.01 %i 2                     Turbulence standard, turbpar, a (dummy if IECed3), additional factor\n', VSCOut.PrepI);
end
fprintf(fid,'0.0  0.0  0.0  0.0                     Iparked Ipark0, row spacing, park spacing\n');
fprintf(fid,'0.7   0.5                              I2,I3\n');
fprintf(fid,'%-5.1f                                  Terrain slope\n',sum(VSCOut.Inflow(2:end).* VSCOut.Prob)/100);
fprintf(fid,'%5.2f                                  Wind shear exponent\n',sum(VSCOut.WindShear(2:end).* VSCOut.Prob)/100);
fprintf(fid,'%5.3f %5.3f                            rhoext rhofat\n',VSCOut.RhoAvgExt,VSCOut.RhoAvgFat);
fprintf(fid,'%5.2f  %4.2f  %2.1f                        Vav  k  lifetime (for Weibull Calculation)\n',VSCOut.MeanW,VSCOut.Weibk, VSCOut.DesignLifetime);
fprintf(fid,'\n');
fprintf(fid,'SiteTurb\n');
fprintf(fid,'Vhub    	DETwind   	NTM_Fat   	NTM_Ext   	ETM       	WS_Prob     LN_MEAN     LN_STD      \n');
    
if VSCOut.printLogNormal
    for i = 1:size(VSCOut.WindSpeed,2)
        fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t\n',VSCOut.VTSOut(:,i));
    end
else
    for i = 1:size(VSCOut.WindSpeed,2)
        fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t\n',VSCOut.VTSOut(:,i));
    end
end

fprintf(fid,'-1\n\n');
fprintf(fid,'Input for *.txt file: (copy beneath 4 lines into the text-file)\n');
fprintf(fid,'V50             %5.1f           based in VSC outfile: ''%s''\n',VSCOut.V50,VSCOut.keyV50);
fprintf(fid,'Ve50            %5.1f           based in VSC outfile: ''%s''\n',VSCOut.Ve50,VSCOut.keyVe50);
fprintf(fid,'V1              %5.1f           (0.80 x V50)\n',VSCOut.V50*0.8);
fprintf(fid,'Ve1             %5.1f           (0.80 x Ve50)\n',VSCOut.Ve50*0.8);
fprintf(fid,'\n\n');
fprintf(fid,'Based on VSCoutfile: %s\n',VSCOut.Outfile);
fprintf(fid,'*** VSCoutfile information ****************************\n');
for i = 1:length(VSCOut.VSCTopInfo)
    fprintf(fid,'%s\n',deblank(VSCOut.VSCTopInfo{i}));
end
fprintf(fid,'\n');
fprintf(fid,'Information on which turbine the turbulences are from:\n');
fprintf(fid,'Vhub    	   DETwind     NTM_Fat    NTM_Ext   	ETM        LogNormal\n');
if VSCOut.printLogNormal
for i = 1:11
    fprintf(fid,'%2i      \t%9s \t%9s \t%9s \t%9s \t%9s\n',2+(i*2),VSCOut.MaxAmbTI90Label{i},VSCOut.FatWLTLabel,VSCOut.NTMextLabel{i},VSCOut.MaxETMLabel{i},VSCOut.FatWLTLabel);
end
else
    for i = 1:11
    fprintf(fid,'%2i      \t%9s \t%9s \t%9s \t%9s\n',2+(i*2),VSCOut.MaxAmbTI90Label{i},VSCOut.FatWLTLabel,VSCOut.NTMextLabel{i},VSCOut.MaxETMLabel{i});
    end
end
    
fprintf(fid,'\n******************************************************\n\n');

fprintf(fid,'Created by VSCoutToVTSclm.m MatLab-Script V01.010. DIRFAT beta \n');
fclose(fid);

disp(' ');
disp('VTS climate file created:');
disp(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']))

end    

%% Print file
function PrintFile_Directional(VSCOut)
Filename = strrep(VSCOut.NAME,' ','_');
fid = fopen(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']),'wt+');
fprintf(fid,'Vestas Site Check Project Name: ''%s'' - %s is turbine label: ''%s'' - NTM_Fat: m = %4.2f\n',VSCOut.ProjectName, VSCOut.FatTopText, VSCOut.FatWLTLabel, VSCOut.TIefftWholer);
%fprintf(fid, 'DirectionalDLC 2 11 12                     DLCs to be used for directional fatigue calculations \n');                     
fprintf(fid,'ieced3  %i                             reference standard, windpar\n',VSCOut.PrepI);
fprintf(fid,'ieced3  %i 0.01 2                      iecgust windpar, iecgust turbpar, a (dummy if IECed3)\n',VSCOut.PrepI);
if VSCOut.printLogNormal
    fprintf(fid,'LNTable  0.01 %i 2 %s                  Turbulence standard, turbpar, a (dummy if IECed3), additional factor, No. of Quantiles\n',VSCOut.PrepI,VSCOut.lognormalQuantile);
else
    fprintf(fid,'Dirfat 0.01 %i 2 1                           Turbulence standard, turbpar, a (dummy if IECed3), additional factor\n',VSCOut.PrepI);
end

fprintf(fid,'0.0  0.0  0.0  0.0                     Iparked Ipark0, row spacing, park spacing\n');
fprintf(fid,'0.7   0.5                              I2,I3\n');
fprintf(fid,'Dirfat  %-5.1f                         Terrain slope\n',sum(VSCOut.Inflow(2:end).* VSCOut.Prob)/100);
fprintf(fid,'Dirfat  %5.2f                          Wind shear exponent\n',sum(VSCOut.WindShear(2:end).* VSCOut.Prob)/100);
fprintf(fid,'%5.3f %5.3f                            rhoext rhofat\n',VSCOut.RhoAvgExt,VSCOut.RhoAvgFat);
fprintf(fid,'Dirfat %5.2f  %4.2f  %2.1f             Vav  k  lifetime (for Weibull Calculation)\n',VSCOut.MeanW,VSCOut.Weibk, VSCOut.DesignLifetime);
fprintf(fid,'\n');
fprintf(fid,'WINDROSE\n');
fprintf(fid,'%-15s','Sector');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(360/size(VSCOut.EffTurb_SectorWise,2)*(nDir-1))]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','Probability');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.Prob(1,nDir),'%.4f')]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','Weibull_A');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.SecWeibA(1,nDir),'%.2f')]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','Weibull_k');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.SecWeibk(1,nDir),'%.2f')]);
end

% VEXP output
fprintf(fid,'\n-1\n\n');
fprintf(fid,'%-15s','VEXP');
fprintf(fid,'\n');
fprintf(fid,'%-15s','WS_Start');
fprintf(fid,'%-10s','WS_End');
fprintf(fid,'%-10s','Offset');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(360/size(VSCOut.EffTurb_SectorWise,2)*(nDir-1))]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','0.0');
fprintf(fid,'%-10s','3.0');
fprintf(fid,'%-10s','0.0');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.WindShear(1,1+nDir))]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','3.0');
fprintf(fid,'%-10s','50.0');
fprintf(fid,'%-10s','0.0');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.WindShear(1,1+nDir))]);
end

% SLOPE output
fprintf(fid,'\n-1\n\n');
fprintf(fid,'%-15s','SLOPE');
fprintf(fid,'\n');
fprintf(fid,'%-15s','WS_Start');
fprintf(fid,'%-10s','WS_End');
fprintf(fid,'%-10s','Offset');
% fprintf(fid,'\n-1\n\nSLOPE\nWS_Start\tWS_End');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(360/size(VSCOut.EffTurb_SectorWise,2)*(nDir-1))]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','0.0');
fprintf(fid,'%-10s','3.0');
fprintf(fid,'%-10s','0.0');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.Inflow(1,1+nDir))]);
end
fprintf(fid,'\n');
fprintf(fid,'%-15s','3.0');
fprintf(fid,'%-10s','50.0');
fprintf(fid,'%-10s','0.0');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(VSCOut.Inflow(1,1+nDir))]);
end
% fprintf(fid,'\n\t0\t50\t0');
fprintf(fid,'\n-1\n\n');
fprintf(fid,'%-15s','TURB');
fprintf(fid,'\n');
fprintf(fid,'%-15s','WS_Start');
fprintf(fid,'%-10s','WS_End');

% fprintf(fid,'\n-1\n\nTURB\nWS_Start\tWS_End');
for nDir = 1:size(VSCOut.EffTurb_SectorWise,2)    
    fprintf(fid,'%-10s',[num2str(360/size(VSCOut.EffTurb_SectorWise,2)*(nDir-1))]);
end
fprintf(fid,'\n');
for nWSBins = 1:size(VSCOut.VTSOutNTMsectorWise,2)
    fprintf(fid,'%-15s',[num2str(VSCOut.VTSOutNTMsectorWise(1,nWSBins))]);
    fprintf(fid,'%-10s',[num2str(VSCOut.VTSOutNTMsectorWise(2,nWSBins))]);
    for nDir = 1 : size(VSCOut.VTSOutNTMsectorWise,1) - 2
        fprintf(fid,'%-10s',[num2str(VSCOut.VTSOutNTMsectorWise(nDir+2,nWSBins),'%.4f')]);
    end
    fprintf(fid,'\n');    
end

if VSCOut.printLogNormal 
  % LN Mean sector wise outptu
  fprintf(fid,'\n-1\n\n');
  fprintf(fid,'%-15s','LN Mean');
  fprintf(fid,'\n');
  fprintf(fid,'%-15s','WS_Start');
  fprintf(fid,'%-10s','WS_End');

  for nDir = 1:size(VSCOut.LNMeanSectorWise,1)-2  
     fprintf(fid,'%-10s',[num2str(360/(size(VSCOut.LNMeanSectorWise,1)-2)*(nDir-1))]);
  end
  fprintf(fid,'\n');
  for nWSBins = 1:size(VSCOut.LNMeanSectorWise,2)
    fprintf(fid,'%-15s',[num2str(VSCOut.LNMeanSectorWise(1,nWSBins))]);
    fprintf(fid,'%-10s',[num2str(VSCOut.LNMeanSectorWise(2,nWSBins))]);
    for nDir = 1 : size(VSCOut.LNMeanSectorWise,1) - 2
        fprintf(fid,'%-10s',[num2str(VSCOut.LNMeanSectorWise(nDir+2,nWSBins),'%.4f')]);
    end
    fprintf(fid,'\n');    
  end

  % LN Std sector wise outptu
  fprintf(fid,'\n-1\n\n');
  fprintf(fid,'%-15s','LN Std');
  fprintf(fid,'\n');
  fprintf(fid,'%-15s','WS_Start');
  fprintf(fid,'%-10s','WS_End');

  for nDir = 1:size(VSCOut.LNStdSectorWise,1)-2 
    fprintf(fid,'%-10s',[num2str(360/(size(VSCOut.LNStdSectorWise,1)-2)*(nDir-1))]);
  end
  fprintf(fid,'\n');
  for nWSBins = 1:size(VSCOut.LNStdSectorWise,2)
    fprintf(fid,'%-15s',[num2str(VSCOut.LNStdSectorWise(1,nWSBins))]);
    fprintf(fid,'%-10s',[num2str(VSCOut.LNStdSectorWise(2,nWSBins))]);
    for nDir = 1 : size(VSCOut.LNStdSectorWise,1) - 2
        fprintf(fid,'%-10s',[num2str(VSCOut.LNStdSectorWise(nDir+2,nWSBins),'%.4f')]);
    end
    fprintf(fid,'\n');    
  end
end

fprintf(fid,'-1\n\n');  
fprintf(fid,'SiteTurb\n');
fprintf(fid,'Vhub    	DETwind   	NTM_Fat   	NTM_Ext   	ETM       	WS_Prob     LN_MEAN     LN_STD      \n');
if VSCOut.printLogNormal
    for i = 1:size(VSCOut.WindSpeed,2)
        fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f \n',VSCOut.VTSOut(:,i));
    end
else
    for i = 1:size(VSCOut.WindSpeed,2)
        fprintf(fid,'%2i  %2i  \t%-9.4f \t%-9.4f \t%-9.4f \t%-9.4f\n',VSCOut.VTSOut(:,i));
        
    end
end

fprintf(fid,'-1\n\n');
fprintf(fid,'Input for *.txt file: (copy beneath 4 lines into the text-file)\n');
fprintf(fid,'V50             %5.1f           based in VSC outfile: ''%s''\n',VSCOut.V50,VSCOut.keyV50);
fprintf(fid,'Ve50            %5.1f           based in VSC outfile: ''%s''\n',VSCOut.Ve50,VSCOut.keyVe50);
fprintf(fid,'V1              %5.1f           (0.80 x V50)\n',VSCOut.V50*0.8);
fprintf(fid,'Ve1             %5.1f           (0.80 x Ve50)\n',VSCOut.Ve50*0.8);
fprintf(fid,'\n\n');
fprintf(fid,'Based on VSCoutfile: %s\n',VSCOut.Outfile);
fprintf(fid,'*** VSCoutfile information ****************************\n');
for i = 1:length(VSCOut.VSCTopInfo)
    fprintf(fid,'%s\n',deblank(VSCOut.VSCTopInfo{i}));
end
fprintf(fid,'\n');
fprintf(fid,'Information on which turbine the turbulences are from:\n');
fprintf(fid,'Vhub    	DETwind   	NTM_Fat   	NTM_Ext   	ETM    \n');
for i = 1:11
    fprintf(fid,'%2i      \t%9s \t%9s \t%9s \t%9s\n',2+(i*2),VSCOut.MaxAmbTI90Label{i},VSCOut.FatWLTLabel,VSCOut.NTMextLabel{i},VSCOut.MaxETMLabel{i});
end
fprintf(fid,'\n******************************************************\n\n');

fprintf(fid,'Created by VSCoutToVTSclm.m MatLab-Script V01.010. DIRFAT beta \n');
fclose(fid);

disp(' ');
disp('VTS climate file created:');
disp(fullfile(VSCOut.PATHSTR,[Filename VSCOut.FileNameExtemsion '.clm']))

end

%%helpers
function Cprob = CumulativeWeibull(weibullA, weibullK, v)
Cprob = 1 - exp(-(v / weibullA)^weibullK);
end

function prob = WeibullBinProbability(v, dV, weibullA, weibullK)
prob = (CumulativeWeibull(weibullA, weibullK, v + dV / 2) - CumulativeWeibull(weibullA, weibullK, v - dV / 2));
end

function temp = checkkeyexists(outFileAsChar,key)
pos_find = GetPosOfKeyFromClmFile(outFileAsChar , key);
temp = ~isempty(pos_find);
end

function pos = GetPosOfKeyFromClmFile(outFileAsChar , key)
pos = find(strncmpi(key,outFileAsChar,length(key)) == 1);
end

function pos = GetPosOfExactWordKeyFromClmFile(outFileAsChar , key)
pos = find(strcmpi(key,outFileAsChar) == 1);
end

function pos = GetPosOfKeyAfterKeyFromClmFile(outFileAsChar , key, pos0)
pos_find = find(strncmpi(key,outFileAsChar(pos0:end),length(key)) == 1);
pos = pos_find(1)+pos0-1;
end


function linesFromClmFile = GetLinesFromClmFile(outFileAsChar , key, nRowsToSkip, nRowsToRead)
linesFromClmFile{1,1} = '';
pos = GetPosOfKeyFromClmFile(outFileAsChar , key);

if pos>0
    posStart = pos(1) + nRowsToSkip;
    posEnd = posStart;
    if nRowsToRead>0
        posEnd = posStart + nRowsToRead;
        for i=posStart:posEnd-1
            linesFromClmFile{i-posStart+1,1} = outFileAsChar{i}(1:end);
        end;
    end;
    if nRowsToRead == -1
        i = posStart;
        while i<=length(outFileAsChar)
            lineRead = outFileAsChar{i}(1:end);
            if isempty(lineRead)
                break;
            end
            linesFromClmFile{i-posStart+1,1} = lineRead;
            i=i+1;
        end;
    end;
    
end;
end

function valuePair = GetValueForKeyFromClmFile(outFileAsChar , key)
valuePairLine = char(GetLinesFromClmFile(outFileAsChar , key, 0, 1));
valuePair = '';
if length(valuePairLine)>length(key)
    valuePair = char(strtrim(valuePairLine(length(key)+1:end)));
end
end

function dataTable = GetDataAsTableFromClmFile(outFileAsChar , key, nRowsToSkip, nColumnsToSkip, nRowsToRead, nColumnsToRead)
linesFromClmFile = GetLinesFromClmFile(outFileAsChar , key, nRowsToSkip, nRowsToRead);

for i= 1:length(linesFromClmFile)
    singleLine = strsplit_LMT(linesFromClmFile{i},' ');
    LineToTable = singleLine(strcmpi(singleLine(1:end), '')==0);
    ctr =1;
    startPos = 1+nColumnsToSkip;
    
    if nColumnsToRead < 0
        nColumnsToRead = length(LineToTable) - nColumnsToSkip;
    end
    
    endPos  = startPos + nColumnsToRead -1;
    for j = startPos:endPos
        dataTable{i,ctr}  = char(LineToTable(1, j));
        ctr=ctr+1;
    end
    
end
end

function dataTable = Get3DDataTableFromClmFile(outFileAsChar , key, nRowsToSkip, nColumnsToSkip, nRowsToRead, nColumnsToRead)
linesListFromClmFile = GetLinesListFromClmFile(outFileAsChar , key, nRowsToSkip, nRowsToRead);
[nRowofTable , mTurbines] = size(linesListFromClmFile);

for j = 1:mTurbines
    for i= 1:nRowofTable
        singleLine = strsplit_LMT(linesListFromClmFile{i,j},' ');
        LineToTable = singleLine(strcmpi(singleLine(1:end), '')==0);
        ctr =1;
        startPos = 1+nColumnsToSkip;

        if nColumnsToRead < 0
            nColumnsToRead = length(LineToTable)- nColumnsToSkip;
        end

        endPos  = startPos+nColumnsToRead-1;
        for k=startPos:endPos
            oneDataTable{i,ctr}  = char(LineToTable(1, k));
            ctr=ctr+1;
        end

    end
   dataTable(:,:,j) = str2double(oneDataTable);
   clear oneDataTable;
end
end

function linesListFromClmFile = GetLinesListFromClmFile(outFileAsChar , key, nRowsToSkip, nRowsToRead)
pos = GetPosOfKeyFromClmFile(outFileAsChar , key);

if size(pos,1)
    for i= 1:size(pos,1)
        posStart = pos(i) + nRowsToSkip ;
        
        if nRowsToRead == -1
            posEnd = length(outFileAsChar);
        else
            posEnd = posStart + nRowsToRead ;
        end
        
        for j=posStart:posEnd-1
            lineRead = outFileAsChar{j}(1:end);
            if isempty(lineRead) && nRowsToRead == -1
                break;
            end
            linesListFromClmFile{j-posStart+1,i} = lineRead;
        end
    end
end
end

function linesListFromClmFile = GetLinesListFromClmFile_fromPOS(outFileAsChar , pos, nRowsToSkip, nRowsToRead)
if size(pos,1)
    for i= 1:size(pos,1)
        posStart = pos(i) + nRowsToSkip ;
        
        if nRowsToRead == -1
            posEnd = length(outFileAsChar);
        else
            posEnd = posStart + nRowsToRead ;
        end
        
        for j=posStart:posEnd-1
            lineRead = outFileAsChar{j}(1:end);
            if isempty(lineRead) && nRowsToRead == -1
                break;
            end
            linesListFromClmFile{j-posStart+1,i} = lineRead;
        end
    end
end
end

function colData = Get2DColDataTableFromClmFile(outFileAsChar , key, nRowsToSkip, nColumnsToSkip, nRowsToRead, nColumnsToRead)
    dataTable3D = Get3DDataTableFromClmFile(outFileAsChar , key, nRowsToSkip, nColumnsToSkip, nRowsToRead, nColumnsToRead);
    [dataTable2D,I] = max(dataTable3D,[],3);
    colData = max(dataTable2D,[],2);
end




function VSCOut =  fWindSpeedProb(VSCOut,C,Turbine,WTGIndex)
    % -- extract wind distribution values
    UpdateOfLayoutClimate = false;
    key = 'Wind Distribution:';
    pos = GetPosOfKeyFromClmFile(C{1} , key);
    if isempty(pos) % update to outfile layout
        key = 'Climatic conditions:';
        pos = find(strncmpi(key,C{1},length(key)) == 1);
        UpdateOfLayoutClimate = true;
    end
    pos = pos(WTGIndex);
    if VSCOut.VSCnet
        if UpdateOfLayoutClimate, skipLines = 3; else skipLines = 5; end
    else skipLines = 4; end

    lineToRead = pos+skipLines;
    % - Probability
    StrTemp = textscan(C{1}{lineToRead},'%s') ;
    for j = 4:size(StrTemp{1},1)
        VSCOut.AmbProb{Turbine}(j-3) = str2double(StrTemp{1}{j});
    end
    % - Mean wind
    StrTemp = textscan(C{1}{lineToRead+1},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.MeanWindDir{Turbine}(j-4) = str2double(StrTemp{1}{j});
    end
    % - WeibullA
    StrTemp = textscan(C{1}{lineToRead+2},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.WeibullADir{Turbine}(j-4) = str2double(StrTemp{1}{j});
    end
    % - Weibullk
    StrTemp = textscan(C{1}{lineToRead+3},'%s') ;
    for j = 5:size(StrTemp{1},1)
        VSCOut.WeibullkDir{Turbine}(j-4) = str2double(StrTemp{1}{j});
    end
    % calculate wind speed probability based on weibull parameter
    for i = 1:11
        for dir = 1:length(VSCOut.MeanWindDir{Turbine})
            v = 2 + i*2;
            VSCOut.WeibullProbWSandDir(i,dir) = WeibullBinProbability(v, 2, VSCOut.WeibullADir{Turbine}(dir), VSCOut.WeibullkDir{Turbine}(dir)) * VSCOut.AmbProb{Turbine}(dir);
        end
    end
end



%% Read DETWind and NTM_Ext
function VSCOut = fProcess_DETWind_Ext(VSCOut,C)
    % Read Data into 3D Matrix
    key = 'Normal turbulence for extreme loads';
    ntm_ExtremeLoads = Get3DDataTableFromClmFile(C{1} , key, 2, 0, -1, -1);
    [pWindbins,qColumns,rTurbines]= size(ntm_ExtremeLoads);
    
    % Process DetWind
    % Wind sector management

    bWSM_Available = false;
    key = 'Wind sector management  (yes/no/NA):';
    WSM_Value = GetValueForKeyFromClmFile(C{1} , key);
    if strcmpi(WSM_Value,'Yes')
        bWSM_Available = true;
    end
    
    %select column based on WSM availability
    if bWSM_Available
        ntm_det_col_no = 3;   
    else
        ntm_det_col_no = 4;
    end
    
    detWind2D = reshape(ntm_ExtremeLoads(:,ntm_det_col_no,:),pWindbins,rTurbines);
    [detWind1D,indDet] = max(detWind2D,[],2);
    VSCOut.MaxAmbTI90Label = VSCOut.AmbWTGLabel(indDet);
    
      
    % OUTPUT - DetWind
    VSCOut.MaxAmbTI90 = detWind1D;


    % Process NTM_Ext

    ntm_Ext_2D = reshape(ntm_ExtremeLoads(:,2,:),pWindbins,rTurbines);

    [ntm_Ext_1D,indExt] = max(ntm_Ext_2D,[],2);
    VSCOut.NTMextLabel = VSCOut.AmbWTGLabel(indExt);
    

    % OUTPUT - NTM_Ext
    VSCOut.NTMext = ntm_Ext_1D;

    
    % Backward Compatibility    
    VSCOut.NoSAmbTurb = {1};
    for i = 1:rTurbines
        VSCOut.SiteTI90{i} = detWind2D(:,i);
    end
    
end

%Cneter wake (Max of all the sectors and then maximum from all turbine)
function VSCOut = ReadCWTurb(VSCOut,Component, C)
    key = 'Centre Wake Turbulence Intensities';
    CW_TI_3D = Get3DDataTableFromClmFile(C{1} , key, 2, 2, -1, -1);
    [pWindbins,qColumns,rTurbines]= size(CW_TI_3D);
    CW_TI_2D = max(CW_TI_3D,[],2);
    CW_TI_2D = reshape(CW_TI_2D,pWindbins,rTurbines);
    if ~strcmp(Component,'F')
        [CW_TI_1D,indCW] = max(CW_TI_2D,[],2);
        VSCOut.MaxCWLabel = VSCOut.AmbWTGLabel(indCW);
    else
        [CW_TI_1D] = CW_TI_2D(:,VSCOut.PosChoosenTurbine);
        indCW = VSCOut.PosChoosenTurbine;
        VSCOut.MaxCWLabel(1:size(CW_TI_1D)) = VSCOut.AmbWTGLabel(indCW); 
    end
    CW_TI_1D(size(CW_TI_1D)+1:11) = 0;            % Assign CW = 0 for missing data below 24 m/s.
    [row_size, col_size] = size(VSCOut.MaxCWLabel(1,:));
    VSCOut.MaxCWLabel(1,col_size+1:11) = {'-'};    % Assign CW label as - in case if data is not present.
    VSCOut.MaxCW(2:12) = CW_TI_1D';
    VSCOut = ExtrapolateCW(VSCOut);               % linear extrapolation for windspeed less then 4m/s and more then 24 m/s.
end

% linear extrapolation for windspeed less then 4m/s and more then 24 m/s.
function VSCOut = ExtrapolateCW(VSCOut)
    for i = 1:11
        x(i) = i*2 + 2;
        y(i) = VSCOut.MaxCW(i+1)*x(i);
    end
    VSCOut.MaxCW(1) = interp1(x,y,2,'linear','extrap')/2;
    for i = 13:19
        VSCOut.MaxCW(i) = interp1(x,y,i*2,'linear','extrap')/(i*2); 
    end
end


function VSCOut = ReadLN(VSCOut, C)
   
    % Read Data into 3D Matrix

    LogNormalMeanDistribution3D = Get3DDataTableFromClmFile(C{1} , VSCOut.key_mean, 2, 0, -1, -1); 
    LogNormalStdDistribution3D  = Get3DDataTableFromClmFile(C{1} , VSCOut.key_SD, 2, 0, -1, -1);
    
    % Get size of the Data
    [pWindbins,~,rTurbines]= size(LogNormalMeanDistribution3D);
            
    % Reshape 3D into 2D
    meanDistribution2D =reshape(LogNormalMeanDistribution3D(:,2,:),pWindbins,rTurbines); 
    
    stdDistribution2D = reshape(LogNormalStdDistribution3D(:,2,:),pWindbins,rTurbines); 
    
    % Filter ChosenTurbine
    VSCOut.LogNormalMean = meanDistribution2D(:,VSCOut.PosChoosenTurbine);
    VSCOut.LogNormalStd = stdDistribution2D(:,VSCOut.PosChoosenTurbine);
    
    %Filter ChosenTurbine for sector wise mean and std
    VSCOut.LogNormalMeanSectorWise = LogNormalMeanDistribution3D(:,:,VSCOut.PosChoosenTurbine);
    VSCOut.LogNormalStdSectorWise = LogNormalStdDistribution3D(:,:,VSCOut.PosChoosenTurbine);
       
end

%% Read LN_mean and LN_SD Table title and return VSCOut.LNexists as true if data exist
function VSCOut = LNTitle(VSCOut, C)
    ids = [1,2,3,4,5,6];
    id = 0;
    title = {'Log Normal distribution, mean','Log Normal distribution, standard deviation','Distribution of Log Normal Mean Turbulence for Extreme Loads','Distribution of Log Normal Std. Dev. of Turbulence for Extreme Loads','Distribution of Log Normal Mean Effective Turbulence','Distribution of Log Normal Std. Dev. of Effective Turbulence'};
    Map = containers.Map(ids,title);
    for i = 1 : 2 : length(ids)
        if checkkeyexists(C{1},title{i})
            id = i;
            break
        end
    end
    if id ~= 0 , VSCOut.LNexists = true; else, return; end
    VSCOut.key_mean = Map(id);
    VSCOut.key_SD = Map(id+1);
end
