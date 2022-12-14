function [GenInfo,Xdata,Ydata,ErrorString] = readvdf(file,dataflag,channels,Tmin,Tmax)
% READVDF reads information from binary data file created by the VMP-tool collect (extension vdf)
%
% Syntax: [GenInfo,Xdata,Ydata,ErrorString] = readvdf(file,dataflag,Tmin,Tmax)
%
% Input and output parameters are defined as follows:
%
% GenInfo         :  General information from *.vdf file as a structure array.
%                    The fields in the structure array depends on the *.vdf file SW version.
%                    All 'raw' header information can be found in this array.
%
% Xdata           :  Vector with time values
%
% Ydata           :  Matrix with measurement data. 
%                    Data are gain- and offset-adjusted.
%                    
% ErrorString     :  Either:
%                    [] : No error
%                    'Specified input file could not be opened'
%                    'SW version x not supported' (where 'x' is a number between 1 and 5)
%                    'Header checksum error'
%
% file            :  *.vdf input file specification
% 
% dataflag        :  0: Data values are not read, only basic information is extracted from file (saves time)
%                    1: Data values are read, all available information from file is returned as output
%
% Tmin            :  Minimum time for the output data in seconds. Use [] if the whole file should be read.
%
% Tmax            :  Maximum time for the output data in seconds. Use [] if the whole file should be read.
%
%
% JEB,PBC 
% Last revision Aug.13, 2012

[fid, message] = fopen(file,'r','l');     % Open file the Intel way

if fid ~= -1       % If the file was successfully opened
    % common info for all vdf files:
    Release = fread(fid,1,'uint16');
    Version = fread(fid,1,'uint16');
    
    [HeaderInfo,ErrorString]=headerread(fid,Release,Version);
    
    % IS THERE AN ERROR IN SCALING FACTORS DURING FILE GENERATION ?
    if ~isempty(HeaderInfo)&(isempty(ErrorString))
        ScaleIx = HeaderInfo.Channel.Scale>1;
        if sum(ScaleIx)~=0
            s1 = 'Based on the vdf-files header information VDAT has identified that there';
            s2 = 'is an error in the scaling of signals (occurred during file generation) on (most likely all) standard channels.';
            s3 = ' ';
            s4 = 'This is a known bug in the vdf file generation and the only work-around is';
            s5 = 'to calibrate the signals (see VDAT manuals). Information on the header can';
            s6 = 'be found in the GenInfo.Channel.Scale variable in the file generated with';
            s7 = 'Matlab save from the VDAT GUI.';
            s8 = ' ';
            s9 = 'If the problems persist (in other vdf-files) contact the Technology R&D,';
            s10= 'SW application Dept, through the PMR system.';
            s = strvcat(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10);

            uiwait(warndlg(s ,'VDF-file generation Error','modal'));
        end
    end
        
        
    GenInfo=HeaderInfo;
    GenInfo.FullFileName=file;    % full name of file incl. path
    GenInfo.Type='VDF-measurement';
    GenInfo.FileExtension='vdf';
    
    if dataflag&&(isempty(ErrorString))
        [Xdata,Ydata,MissSampl,ChkSumErr] = dataread(fid, file, Tmin, Tmax, HeaderInfo.CrossrefTable, ...
            HeaderInfo.HeaderSize,HeaderInfo.SampleSize,HeaderInfo.NoOfSamples,HeaderInfo.Channel, ...
            HeaderInfo.SampleTime);
        
        GenInfo.MissSamples=MissSampl;
        GenInfo.ChkSumErr=ChkSumErr;
        GenInfo.NoOfValidSamples = length(Xdata);
        GenInfo.TsAvg=(Xdata(end) - Xdata(1)) / (GenInfo.NoOfValidSamples - 1);
    else
        Xdata=[]; Ydata=[];
    end
    AddOut=[];
    
    fseek(fid,0,'eof');
    GenInfo.FileSize = ftell(fid);
    
    st=fclose(fid);
    
else % if file was not succesfully opened
    GenInfo=[];
    Xdata=[];
    Ydata=[];
    ErrorString='Specified input file could not be opened';
    AddOut=[];
    
end

%================================================================================
% Function: headerread
%================================================================================
function [header,err_str]=headerread(fid,rel,ver)

switch ver
    
case 1
    ValRange=10;
    err_str='SW version 1 not supported !';   
    header.Release=rel;
    header.Version=ver;
    header.Processor='CT4400';
    
    %Header=struct('uint16',release,'uint16',version,'uint16',Blocksize,'stamp',StartTime,...
    %   'char(79)',Comment,'char(10,25)',ValText,'double',Scale,'double',Offset);
    %SampleHeaderSize=length(Header)+4;
    %Footer=0; % no footer
    %% Hsync1=???? % betydning ?
    %% Fsync1=???? % betydning ?
case 2
    ValRange=19;
    err_str='SW version 2 not supported !';   
    header.Release=rel;
    header.Version=ver;
    header.Processor='CT4400';
    
    
case 3
    ValRange=19;
    err_str='SW version 3 not supported !';   
    header.Release=rel;
    header.Version=ver;
    if header.Release==1
        header.Processor='CT3500';
    else
        header.Processor='CT4400';
    end
    
    
case 4
    ValRange=19;
    err_str='SW version 4 not supported !';   
    header.Release=rel;
    header.Version=ver;
    header.Processor='CT3500';
    
    
case 5
    ValRange=28;
    err_str='SW version 5 not supported !';   
    header.Release=rel;
    header.Version=ver;
    header.Processor='CT3500';
    
    
case {6 7}   % version 6 and 7 are almost identical
    ValRange=28;
    
    header=struct('Release',rel,'Version',ver,'TurbineType',fread(fid,1,'uint16'),...
        'TurbineNo',fread(fid,1,'uint16'),'ParkNo',fread(fid,1,'uint16'),...
        'HeaderSize',fread(fid,1,'uint16'),'SampleSize',fread(fid,1,'uint16'),...
        'FooterSize',fread(fid,1,'uint16'),'NoOfSamples',fread(fid,1,'uint16')...
        );
    header.StartTime=struct('Day',fread(fid,1,'ubit5'),'Month',fread(fid,1,'ubit4'),...
        'Year',fread(fid,1,'ubit7'),'Minute',fread(fid,1,'ubit16'),...
        'Msec',fread(fid,1,'ubit16')...
        );
    header.SampleTime=fread(fid,1,'uint16')/1000;  % sampletime is returned in seconds, not ms
    header.ErrorNo=fread(fid,1,'uint16');
    header.Par1=fread(fid,1,'int16');
    header.Par2=fread(fid,1,'int16');
    header.SourceNo=fread(fid,1,'uint16');
    header.TrigValue=fread(fid,1,'int16');
    header.TrigTime=struct('Day',fread(fid,1,'ubit5'),'Month',fread(fid,1,'ubit4'),...
        'Year',fread(fid,1,'ubit7'),'Minute',fread(fid,1,'ubit16'),...
        'Msec',fread(fid,1,'ubit16')...
        );
    header.Trigged=fread(fid,1,'uint8');
    header.Armed=fread(fid,1,'uint8');
    
    for ChNo=1:ValRange,
        header.Channel.SampleEnable(ChNo) = fread(fid,1,'uint8');
        header.Channel.TrigEnable(ChNo) = fread(fid,1,'uint8');
        header.Channel.Dest(ChNo) = fread(fid,1,'uint16');
        header.Channel.Max(ChNo) = fread(fid,1,'int16');
        header.Channel.Min(ChNo) = fread(fid,1,'int16');
        header.Channel.Type(ChNo) = fread(fid,1,'uint8');
        switch header.Channel.Type(ChNo)
        case 0 % Predefined channel
            header.Channel.SampleType(ChNo) = 0;
            dummy=fread(fid,4,'uint8');  % shifts file position indicator 4 bytes
        case 1 % SysState channel
            header.Channel.SampleType(ChNo) = fread(fid,1,'uint16');
            dummy=fread(fid,2,'uint8');  % shifts file position indicator 2 bytes
        case 2 % Adress channel
            header.Channel.SampleType(ChNo) = fread(fid,1,'uint32');
        otherwise % unknown channel
            header.Channel.SampleType(ChNo) = 0;
            dummy=fread(fid,4,'uint8');  % shifts file position indicator 4 bytes
        end
        header.Channel.Scale(ChNo) = fread(fid,1,'double');
        header.Channel.Offset(ChNo) = fread(fid,1,'double');
    end
    
    header.FileName=char(fread(fid,8,'uint8'));
    if ver==7
        header.ControlType=fread(fid,1,'uint16');   % this is the only difference between ver 6 and 7
    else
        header.ControlType=[];   % controltype must be present in header structure
    end
    header.Chk=fread(fid,1,'uint16');
    
    % do some corrigations
    % NoOfSamples might be 0 in the header information, if it is unknown
    fseek(fid,0,'eof'); % set file position indicator to end-of-file
    header.NoOfSamples=floor((ftell(fid) - header.HeaderSize - header.FooterSize)/header.SampleSize);

    
    % Now add some additional information to structure
    % First a checksum check for the header information
    CheckSumOk=CheckCheckSum(fid,header.HeaderSize,header.Chk);
    if CheckSumOk~=1
        err_str='Header checksum error';    
    else
        err_str=[];    % no errors
    end
    % PBC120809: Addtional header sanity check: due to header error seen in 
    % 28364	MK8	Kent Hills	V90 VCRS-3000kW-1000V-60Hz	VMP 6000	2011-11-30 03:14	3.10.98	151	High temp. Gen bearing _:___°C	\\dkrkbfile01\v-vmp\vmp\28364\VDF\11113000.VDF
    % Y:\_Data\LAC\Control\FagProjekter\Vdat\VDATTest\VDF\FromLPH\VMP 6000 60HZ V90-3MW software 3.10.98\
    if header.StartTime.Day==0 | header.StartTime.Month==0
        err_str='Header error; header.StartTime.Day and/or header.StartTime.Month invalid value'; 
        return
    end
    % Next add some reasonable time format for start- and trig time
    header.StartTimeString=TimeString(header.StartTime.Year,header.StartTime.Month,...
        header.StartTime.Day,header.StartTime.Minute,header.StartTime.Msec);
    header.TrigTimeString=TimeString(header.TrigTime.Year,header.TrigTime.Month,...
        header.TrigTime.Day,header.TrigTime.Minute,header.TrigTime.Msec);
    
    % Finally find the length of the measurement in seconds 
    
    % make sure the first sample is without checksum errors that could have affected the time stamp
    TimeIxMin=1;
    while TimeIxMin<header.NoOfSamples
        fseek(fid,header.HeaderSize + (TimeIxMin-1)*header.SampleSize,'bof');   % set file position indicator 
        CurrentSampleSum=sum(fread(fid,header.SampleSize-2,'uint8=>uint8'));
        CurrentChkSum=fread(fid,1,'uint16=>uint16');
        if double(CurrentSampleSum)==double(CurrentChkSum)
            break
        end
        TimeIxMin=TimeIxMin+1;
    end
    % make sure the last sample is without checksum errors that could have affected the time stamp
    TimeIxMax=header.NoOfSamples;
    while TimeIxMax>TimeIxMin
        fseek(fid,header.HeaderSize + (TimeIxMax-1)*header.SampleSize,'bof');   % set file position indicator 
        CurrentSampleSum=sum(fread(fid,header.SampleSize-2,'uint8=>uint8'));
        CurrentChkSum=fread(fid,1,'uint16=>uint16');
        if double(CurrentSampleSum)==double(CurrentChkSum)
            break
        end
        TimeIxMax=TimeIxMax-1;
    end
    % set file position indicator at the first timestamp, that we know is without checksum errors
    fseek(fid,header.HeaderSize + (TimeIxMin - 1)*header.SampleSize,'bof');   
    firstday = fread(fid,1,'ubit5');
    firstmonth = fread(fid,1,'ubit4');
    firstyear = fread(fid,1,'ubit7');
    firstminute = fread(fid,1,'uint16');
    firstmsec = fread(fid,1,'uint16');
    % set file position indicator at the last timestamp, that we know is without checksum errors
    fseek(fid,header.HeaderSize + (TimeIxMax - 1)*header.SampleSize,'bof');   
    lastday = fread(fid,1,'ubit5');
    lastmonth = fread(fid,1,'ubit4');
    lastyear = fread(fid,1,'ubit7');
    lastminute = fread(fid,1,'uint16');
    lastmsec = fread(fid,1,'uint16');
    
    header.FirstDataTimeString=TimeString(firstyear,firstmonth,firstday,firstminute,firstmsec);
    header.LastDataTimeString=TimeString(lastyear,lastmonth,lastday,lastminute,lastmsec);
        
    header.Tmin=0.0;   % per definition
    header.Tmax=relative_time(firstyear,firstmonth,firstday,firstminute,firstmsec,...
        lastyear,lastmonth,lastday,lastminute,lastmsec);
    if header.Trigged==1
        header.Ttrig=relative_time(firstyear,firstmonth,firstday,firstminute,firstmsec,...
            header.TrigTime.Year,header.TrigTime.Month,header.TrigTime.Day,header.TrigTime.Minute,header.TrigTime.Msec);
    else
        header.Ttrig=[];
    end
    
    % find cross reference table for (channels in vdf-file) -> (sensorlist no.)
    for m=1:ValRange
        %if header.Channel(m).SampleEnable==1
            if header.Channel.SampleEnable(m) == 1
            % header.CrossrefTable(header.Channel(m).Dest)=m;
            header.CrossrefTable(header.Channel.Dest(m))=m;
        end
    end
   
    if (ver==6) % Probably no turbines are running/generating VDF files with this VDF format release, but there can be old VDF files which need to be analysed  
        if header.Release>17 % At this VMP SW rel. we changed to VDF header version 7 according to HMR in turbine applications
            header.Processor='CT3500';
        else
            header.Processor='CT5000.01';     % No 5000.02 processors existed at this time
        end
    else    % i.e. if ver==7
        VMPSWRelIsModified=0; % initilisation
        if header.Release<1000 % then the release is e.g. header.Release=205 and not e.g. 20434 Note the release cannot have 4 digits
            % modify the header.Release number because the field names in the stdsensdef.mat assume 5 digits
            header.Release=header.Release*100; 
            VMPSWRelIsModified=1; 
        end
        
        switch header.ControlType
        case {1, 2}
            header.Processor='CT4400';
        case {3, 4, 5}
            header.Processor='CT3500';
        case 8
            if header.Release>=30000           % sw-release 3.00.00 or later
                header.Processor='CT6000';
            elseif header.Release>=20000       % sw-release between 2.00.00 and 2.99.99
                header.Processor='CT5000.02';
            else                               % sw-release 1.99.99 or before
                header.Processor='CT5000.01';
            end
        case 9
            header.Processor='CT5000.02';
        case 10
            header.Processor='CT6000';
        otherwise
            header.Processor='unknown';
        end
        if VMPSWRelIsModified
            % then set it back for it to compatible (correct format)in e.g. FindSysStateDesc.m
            header.Release=header.Release/100;
        end
        
    end
    
    % end version 6 and 7
    
otherwise
    err_str='SW version not supported, data file may be corrupt';
    header=[];
    
end  % end switch statement

% end of sub function: headerread


%================================================================================
% Function: ChkSumOk
% Calculates checksum for the header
%================================================================================
function ChkSumOk=CheckCheckSum(file_id,hs,CheckSum);

OrigFilePointerPos = ftell(file_id); % get the current file position indicator
fseek(file_id,0,'bof');  % rewind file to start
header_sum=sum(fread(file_id,hs-2,'uint8'));
switch header_sum-CheckSum
case 0
    ChkSumOk=1;
otherwise
    ChkSumOk=0;
end
fseek(file_id,OrigFilePointerPos,'bof'); % rewind file position indicator to orig. position

% end sub function ChkSumOk


%================================================================================
% Function: TimeString
%================================================================================
function TimeFormat=TimeString(Year,Month,Day,Minute,Msec);

if Year<80   % not likely that any *.vdf files exists before 1980
    Year_text=int2str(2000+Year);
else
    Year_text=int2str(1900+Year);
end
Month_def={'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};
Month_text=char(Month_def(Month));

Hour_temp=floor(Minute/60);
Minute_temp=Minute-Hour_temp*60;
Second_temp=floor(Msec/1000);
Msec_temp=Msec-Second_temp*1000;
Day_temp=Day;

if Day_temp<10
    Day_text=(['0',int2str(Day_temp)]);
else
    Day_text=int2str(Day_temp);
end

if Hour_temp<10
    Hour_text=(['0',int2str(Hour_temp)]);
else
    Hour_text=int2str(Hour_temp);
end

if Minute_temp<10
    Minute_text=(['0',int2str(Minute_temp)]);
else
    Minute_text=int2str(Minute_temp);
end

if Second_temp<10
    Second_text=(['0',int2str(Second_temp)]);
else
    Second_text=int2str(Second_temp);
end

TimeFormat=([Year_text,'-',Month_text,'-',Day_text,' ',Hour_text,':',Minute_text,':',Second_text]);

% end sub function TimeFormat



%================================================================================
% Function: dataread
%================================================================================
function [X,Y,misssampl,chksumerr]=dataread(file_id,filename,tmin,tmax,Crossref,hs,ss,nos,chinfo,tsideal)

% find time stamps, first 6 bytes in each sample
fseek(file_id,hs,'bof');   % set file position indicator where the data begins
timematrix=fread(file_id,[3 nos],'3*uint16=>uint16',ss-6)'; % 48 bits (3 * uint16 or 6 bytes) are used for timestamp in each sample
day=double(bitshift(bitshift(timematrix(:,1),11),-11));     % day is bit no. 1-5 in the first uint16 colomn
month=double(bitshift(bitshift(timematrix(:,1),7),-12));    % month is bit no. 6-10 in the first uint16 colomn
year=double(bitshift(timematrix(:,1),-9));                  % year is bit no. 11-16 in the first uint16 colomn
minute=double(timematrix(:,2));                             % minute is the second uint16 colomn
msec=double(timematrix(:,3));                               % msec is the third uint16 colomn
clear timematrix

% calculate time vector for the whole measurement length
X=relative_time(year(1),month(1),day(1),minute(1),msec(1),year,month,day,minute,msec);

clear day month year minute msec

% do some error checking on input parameters tmin and tmax
if (isempty(tmin)|(tmin<0.0)|(tmin>X(end-1)))
    tmin=0.0;
end
if (isempty(tmax)|(tmax>X(end))|(tmax<=tmin))
    tmax=X(end);
end

TimeIndex=find((X>=tmin)&(X<=tmax));  % not yet taken account for checksum errors

% make sure the first sample in TimeIndex is without checksum errors
TimeIxMin=TimeIndex(1);
while TimeIxMin<TimeIndex(end)
    fseek(file_id,hs + (TimeIxMin-1)*ss,'bof');   % set file position indicator 
    CurrentSampleSum=sum(fread(file_id,ss-2,'uint8=>uint8'));
    CurrentChkSum=fread(file_id,1,'uint16=>uint16');
    if double(CurrentSampleSum)==double(CurrentChkSum)
        break
    end
    TimeIxMin=TimeIxMin+1;
end
% make sure the last sample in TimeIndex is without checksum errors
TimeIxMax=TimeIndex(end);
while TimeIxMax>TimeIxMin
    fseek(file_id,hs + (TimeIxMax-1)*ss,'bof');   % set file position indicator 
    CurrentSampleSum=sum(fread(file_id,ss-2,'uint8=>uint8'));
    CurrentChkSum=fread(file_id,1,'uint16=>uint16');
    if double(CurrentSampleSum)==double(CurrentChkSum)
        break
    end
    TimeIxMax=TimeIxMax-1;
end

TimeIndex=TimeIxMin:TimeIxMax; % it is now certain that the first and the last sample is without checksum errors
NoOfSamplesToRead=length(TimeIndex);
FirstSampleToRead=TimeIndex(1);
X=X(TimeIndex);           % throw away any samples outside interval tmin->tmax
clear CurrentSampleSum CurrentChkSum TimeIxMin TimeIxMax TimeIndex

% find no of active channels in vdf-file. 
active_ch=(ss-8)/2;  % 6 bytes goes to timestamp, 2 bytes to checksum. Each channel data value is 2 byte (16 bit)

% calculation of sum of samples 
fseek(file_id,hs + (FirstSampleToRead-1)*ss,'bof');   % set file position indicator at start for data values
dummy_matrix8=fread(file_id,[ss,NoOfSamplesToRead],'uint8=>uint8')';   % read data as 8 bit unsigned integers in a matrix
dummy_matrix8=dummy_matrix8(:,1:ss-2);     % remove the checksums from the matrix
%samplesum=sum(dummy_matrix8,2);            % samplesum for interval tmin -> tmax

% summation in blocks, originally made by MRK. JEB 031227
[mrow, ncol] = size(dummy_matrix8);
if mrow > 50e3 % if more than 50.000 samples or file size approx 3 MB (50.000 samples * 28 channels * 2 bytes/sample)
  samplesum=block_sum(dummy_matrix8);            % samplesum for interval tmin -> tmax
else
  samplesum=sum(dummy_matrix8,2);            % samplesum for interval tmin -> tmax
end  
clear dummy_matrix8;
% end summation in blocks

% read data in a time-optimised way
fseek(file_id,hs + (FirstSampleToRead-1)*ss,'bof');   % set file position indicator at start for data values
dummy_matrix16=fread(file_id,[ss/2, NoOfSamplesToRead],'int16=>int16')';  % read data as 16 bit integers in a matrix

% scaling
Y=zeros(NoOfSamplesToRead,active_ch);           % pre-allocate memory
for n=1:active_ch
    %    if chinfo(Crossref(n)).Type==0   % scaling only if predefined channel
    %        Y(:,n)=(double(dummy_matrix16(:,n+3)) + chinfo(Crossref(n)).Offset) * chinfo(Crossref(n)).Scale;
    if chinfo.Type(Crossref(n))==0   % scaling only if predefined channel
        Y(:,n)=(double(dummy_matrix16(:,n+3)) + chinfo.Offset(Crossref(n))) * chinfo.Scale(Crossref(n));
    else
        Y(:,n)=double(dummy_matrix16(:,n+3));
    end
end

% read the checksums
chksum=dummy_matrix16(:,ss/2);  % read the checksums
clear dummy_matrix16; % not needed anymore
chksumdiff=double(chksum)-samplesum;
clear chksum samplesum;   % not needed anymore
chksumerr=length(find(chksumdiff~=0));  % no of checksum errors, for interval tmin -> tmax

% remove checksum errors
I=find(chksumdiff==0);    % find all the good samples
X=X(I);    % checksum errors removed from time vector !
Y=Y(I,:);  % checksum errors removed from data matrix !
clear I

% find no. of missing samples for interval tmin -> tmax
LastGoodData=find(diff(X)>1.5*tsideal);  % first find indices where data starts to be missing
if ~isempty(LastGoodData)
    for n=1:length(LastGoodData)   % find the number of missing samples after each 'LastGoodDataIndex'
        MissSampl(n)=round(( X(LastGoodData(n)+1) - X(LastGoodData(n)) )/tsideal - 1); 
    end
    TotMissSampl=sum(MissSampl);  % including check-sum errors
    misssampl=TotMissSampl - chksumerr; % do not include check-sum errors in missing samples
else
    misssampl=0;
end

% end sub function dataread



%================================================================================
% Function: relative_time
% Finds time difference between 2 times defined by year,month,day,minute,msec.
% The year must be given in a 2-digit number, e.g. 01 for 2001
% The year is assumed to be between 1980 and 2079. The time difference is given in seconds.
% year1,month1 etc. must be size 1x1. year2, month2 etc must be colomn vectors (size n x 1)
%================================================================================
function t_diff=relative_time(year1,month1,day1,minute1,msec1,year2,month2,day2,minute2,msec2)

if ~((year1==year2(1)) & (sum(diff(year2))==0) & (month1 == month2(1)) & (sum(diff(month2)) == 0))
    
    % do the calculations in a very generalised way 
    % (this is unfortunately more time consuming than the simple way)
    
    % From time
    if year1<80 % not likely that any *.vdf files exists before 1980
        year1 = year1+2000;
    else
        year1 = year1+1900;
    end
    % To time
    Ix=find(year2<80);
    year2 = year2+1900;
    year2(Ix)=year2(Ix)+100;
    
    whole_days1=datenum(year1,month1,day1);
    whole_days2=datenum(year2,month2,day2);
    
    sec_in_day1=minute1*60 + msec1/1000;
    sec_in_day2=minute2*60 + msec2/1000;
    
    t_diff = (whole_days2-whole_days1)*86400 + sec_in_day2 - sec_in_day1;
    
else
    % do the calculations the simple and fast way
    % when it is certain that the year and month is the same for the 2 times
    
    t_diff=(day2-day1)*86400 + (minute2-minute1)*60 + (msec2-msec1)/1000;
    
end

% end of sub-function relative_time

% ===============================================================================
% Function: block_sum 
% Summation of large 8-bit matrix in blocks
% This help to keep the memory consumption low
% ===============================================================================

function Result = block_sum(x)

[mrow,ncol] = size(x);
nblock = 50e3; % note: mrow must be larger than nblock !

Result = zeros(mrow,1);  
for i=1:nblock:mrow-nblock
    ii=i:i+nblock-1;
    Result(ii)=sum(x(ii,:)');
end
ii=ii(end)+1:mrow;
Result(ii)=sum(x(ii,:)');

% end of sub-function block_sum