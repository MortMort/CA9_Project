function [geninfo, xdata, ydata, errorstring]=readTACIIxls(file,dataflag,channels,tmin,tmax);

% READTACIIXLS reads information of TACII data files, converts them into
% VDAT compatible mat-files and subsequently read them through readmat.m
%
% Syntax: [genInfo,xdata,ydata,errorstring] = readvdf(file,dataflag,Tmin,Tmax)

% Data collected using the TACII datalogger and VestasOnline from V82, 
% NM82/1500 and NM72 turbines is converted to a VDAT compatible mat-file. 

% The VestasOnline data must be copied into Sheet1 of Excel and saved 
% as an .xls file to a VDAT compatible .mat file

% Data are saved in a mat-file and then read through readmat.m.
% The data are automatically saved in *.mat where * is the same as for the
% file filename

% NOTE: The VestasOnline Excel output file must be of the correct format: 
%     The Table from the TACII data logger must be copied using the 
%     "copy to clipboard" button. 

%     The table must then be pasted into Excel on the 1st worksheet.

%     The "Pos" header cell must be located in Cell A1 

%     There should be nothing else in Sheet1 of the Excel file

%     VestasOnline has a minimum sample output = 50 samples, so if you have
%     collected less samples than this you will need to remove the excess
%     samples from the Excel file manually

%     If a sensor number that does not have a sensor assigned is accidentally
%     logged, the complete (empty) column must be deleted from the Excel
%     file before it is saved in .xls format.  An error is desplayed if
%     this is not carried out before running TACIIExcelRead.m

%     If the same sensor number logged in more than one channel, the 
%     duplicate column(s) must be completely deleted from the Excel
%     file before it is saved in .xls format.  An error is desplayed if
%     this is not carried out before running TACIIExcelRead.m

%SAVING THE EXCEL FILE IN .xls format 
%     The file name should contain everything required for referencing the 
%     data log.

%     For example:
%           Site name
%           Turbine number
%           Trigger
%           Reason for logging

% * An example (a section) of the Excel file is included below

% EXAMPLE OF REQUIRED Excel file format

%Pos	------ Time Stamp ------	1: 0007 Wind speed - 1 second average (x.x)	2: 0102 kW instantaneous (x.x)	3: 0103 kW 1 second average (x.x)	4: 4226 10 min wind speed high	5: 0067 Temperature gear bearing rear gen. side (1650 only)	6: 0071 Temperature yaw rim	7: 0099 Frequency L1 (x.x)
%1	2007-05-21 13:05:36:5700	7.3	406.5	398.2	0	0	0	50
%2	2007-05-21 13:05:36:6400	7.3	392.8	397.8	0	0	0	50
%3	2007-05-21 13:05:36:7100	7.3	408.7	397.8	0	0	0	50

%Terminology for 1: 0007 Wind speed - 1 second average (x.x) 
%1->Channel number; 0007->Sensor number; the rest->Description

% Syntax :
% TACIIExcelRead(file,dataflag,tmin,tmax)
% 
% Inputs :
% file : Name of .xls Excel file
%
% Example :
% TACIIExcelRead('G:\CHSPRs\VDAT\Excel\TACIIExcelEx')
%
% JEGOO, 22/05/2007

GenInfo=[]; Xdata=[]; Ydata=[]; AddOut=[];

% Read data
[numeric,txt]=xlsread(file,1);
Pos=numeric(:,1);

% if isnan(Pos(1))==1 %Check for unassigned sensor number logging
if (sum(strcmp(txt(1,:),''))>0 || sum(isnan(Pos))>0) % if either the sensor header is blank or else
                                                     % a sensor header with just sensor number without description                                                     % exist
    errortext=strvcat('You have logged an unassigned sensor number',...
                      'Please remove the column without a full description heading',...
                      'from the .xls file in Excel, resave and rerun VDAT');
    uiwait(errordlg(errortext ,'Input File Error','modal')); % display error message                
else
    %If all sensor numbers have descriptions continue making .mat file
    
    %Calculate number of sensors collected during datalogging
    SizeMat=size(numeric);
    NoOfSensors=SizeMat(2)-2;  % No. of sensors (no. of channels)

    % Measured data, in double precision
    Ydata=numeric(:,3:end);
end

if sum(sum(isnan(Ydata)))>=1 %Check for totally empty columns
    errortext=strvcat('You have an empty column in your .xls file.',...
                      'Please remove the blank column completely by cutting it from',...
                      'the .xls file in Excel, resave and rerun VDAT');
    uiwait(errordlg(errortext ,'Input File Error','modal')); % display error message
else
    %If there are no completely blank columns continue making .mat file   

    %Read the header lines
    Header=txt(1,3:end);

    % Read actual Sensor descriptions from the file
    SenDesc = Header;
    SenSym = Header;

    % Generate appropriate sensor symbols by mapping sensor number from 
    % sensor description with sensor symbol corresponding to standard
    % sensor number available in TACIIstdsensdef.mat
    VDATConfig = shared.lib.VDATInfo.instance();
    load([VDATConfig.ReadOnlyPath '\private\TACIIstdsensdef.mat']); % loading mat file with standard sensor symbols and descriptions    
    
    Desc = char(SenDesc);
    Desc(:,1:3)=[]; %Remove channel number
    for i=1:NoOfSensors
        n = min(findstr(' ',Desc(i,:))); % placement of first space in the description after sensor number
        SenNum=str2num(Desc(i,1:n-1)); % sensor number
        j=1;
        while (j<=StdSensCfg.TotalSensors)
            if (StdSensCfg.Number(j,1)==SenNum)
                SenDesc(1,i)=StdSensCfg.Desc(j,1);
                SenSym(1,i)=StdSensCfg.Symbol(j,1);
                break;
            else
            end
            j=j+1;
        end
    end
    SensorDesc = char(SenDesc);
    SensorSym = char(SenSym);
    
    %Display error message if channels contain the same sensor number
    CellSensorSym=cellstr(SensorSym);
    %Create matrix contains 1s if channel number matches another and 0 if not
    for i=1:NoOfSensors 
       same(:,i)=strcmp(CellSensorSym(i), CellSensorSym);
    end
    %If sum of matrix > number of channels collected send error
    if sum(sum(same))>NoOfSensors 
        errortext=strvcat('Two or more of the data channels logged are the same.',...
                          'Please remove duplicate columns from the .xls file in Excel, resave and rerun VDAT');
        uiwait(errordlg(errortext ,'Input File Error','modal')); % display error message
    else
        
        %Shorten descriptions to 40 characters (as specified by VDAT manual)
        SensorDesc(:,41:end)=[];

        %Calculate time between samples
        Date=txt(2:end,2);
        DateMat=cell2mat(Date);
        %Remove final millisecond number (VestasOnline only logs at a rate of up to 
        %10ms, so rounding to 0.001 should not be a problem
        DateMat(:,24)=[]; 
        N=datenum(DateMat,'yyyy-mm-dd HH:MM:SS:FFF');
        TimeConst=1/(24*60*60*100); %10ms as proportion of 1day
        samples=size(Pos); %Number of samples
        SampleTime=(round(mean(((N(end)-N(1))/(samples(1)-1))/TimeConst)))/100; %In seconds

        Xdata=[0:SampleTime:(samples(1)*(SampleTime))-SampleTime]'; % Time vector
        
        % to know the path of '.mat file in correct format of VDAT 
        ExtRip=file;
        n = max(findstr('.',file)); % to find out the index of last comming '.' in the string
        ExtRip(n:end)=[]; % .xls is ripped off
              
        %.mat file in correct format for VDAT is stored in same location as the
        %original VestasOnline .XLS file
        OutFile=[ExtRip '.mat'];
        % end

        %To be plotted within graph header information
        StartTime = datestr(datenum(DateMat(1,:), 'yyyy-mm-dd HH:MM:SS'),0);
        EndTime = datestr(datenum(DateMat(end,:), 'yyyy-mm-dd HH:MM:SS'),0);
        DataDuration = [StartTime ' till ' EndTime ' (' num2str((N(end)-N(1))*24*3600) '[s])'];

        % create the GenInfo struct 
        GenInfo.FileExtension='xls';
        GenInfo.Type = 'TAC II data copied from VestasOnline and saved to Excel.';
        GenInfo.FullFileName = file;
        GenInfo.FirstDataTimeString = StartTime;
        GenInfo.LastDataTimeString = EndTime;
        GenInfo.NoOfSamples = samples(1);
        GenInfo.Tmin = Xdata(1);
        GenInfo.Tmax = Xdata(end);
        GenInfo.SampleTime = SampleTime;
        GenInfo.TsAvg = SampleTime;
        GenInfo.Header(1) = { GenInfo.Type };
        GenInfo.Header(2) = { [GenInfo.FullFileName ' ; ' DataDuration] };
%         GenInfo.Header(3) = { StartTime };

        %save Xdata Ydata SensorSym SensorDesc GenInfo
        save(OutFile, 'Xdata', 'Ydata', 'SensorSym', 'SensorDesc', 'GenInfo');
        
        %Say program has run successfully
        disp(['A VDAT compatible mat-file called ' GenInfo.FullFileName ' has been created'])
    end
end

% READ the saved *.mat file
[geninfo, xdata, ydata, errorstring, addout] = readmat(OutFile, dataflag, tmin, tmax);
