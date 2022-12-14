function [GenInfo,Xdata,Ydata,ErrorString] = readint(file,dataflag,channels,Tmin,Tmax)

% READINTFILE reads data from binary data file created by Vestas measurement system or VTS (file extension int)
%
% Syntax: [GenInfo,Xdata,Ydata,ErrorString] = readint(file,dataflag,channels,Tmin,Tmax)
%
% Input and output parameters are defined as follows:
%
% GenInfo         :  General information from *.int file as a structure array with fields :
%                    ID               : ???
%                    FileDesc         : For IntFileSubType = 'VTS-sim'  : Description of file 
%                                       For IntFileSubType = 'MeasData' : Name of file
%                    NoOfChannels     : Number of channels
%                    Type             : File type, either 'VTS-sim' or 'MeasData'
%                    Tmin             : Minimum time in data in seconds (usually 0)
%                    Tmax             : Maximum time in data in seconds
%                    FullFileName     : Full file name, including path
%                    NoOfSamples      : Number of samples in file
%                    NoOfValidSamples : Number of valid samples in file
%                    TsAvg            : Average sample time in seconds
%                    Crossreftable   :  Cross-reference table.
%                                       Table defining crossreference between channel placement in Ydata and sensor no.
%
% Xdata           :  Vector with time values
% 
% Ydata           :  Matrix with measurement data. 
%
% ErrorString     :  If [] (empty) : No error
%                    Otherwise outputs a string with description of error
%
% file            :  *.int input file specification
%
% dataflag        :  If 0, time vector and data matrix are not read
%
% channels        :  Use [] if no selection.
% 
% Tmin            :  Minimum time for the output data in seconds. Use [] if the whole file should be read.
% 
% Tmax            :  Maximum time for the output data in seconds. Use [] if the whole file should be read.
%
% JEB 
% Last revision 13/12 2001

% Open file
[fid, message] = fopen(file,'r','l');     % the Intel way

% If the file was successfully opened
if fid ~= -1
    [GenInfo,Xdata,Ydata,ErrorString] = data_read(fid,dataflag,Tmin,Tmax);
    % the following line does not give path name if it is not specified in 'file'
    GenInfo.FullFileName=file;                    % full file name, including path
    GenInfo.FileExtension='int';
    
    fseek(fid,0,'eof');
    GenInfo.FileSize = ftell(fid);
    
    st=fclose(fid);
else
    GenInfo=[];Xdata=[];Ydata=[];
    ErrorString='Specified input file could not be opened'; 
end


% Function: data_read
function [geninfo,x,y,err_str]=data_read(fid,df,tmin,tmax)

% common info for all *.int files:
RL1 = fread(fid,1,'uint32');              %  4 bytes (6*4+40+8) = 72
ID = fread(fid,6,'uint32');               % 24 bytes UBL has used this : ID = fread(fid,24,'char');  % 24 bytes Contains the date of creation YY = ID(1)+2000, MM = ID(5), DD = ID(9) HH = ID(13) mm = ID(17) ss=ID(21)
FileDesc = char(fread(fid,40,'char'))';   % 40 bytes Text string from califile if file is from VDAQ
RL2 = fread(fid,1,'uint32');              %  4 bytes (6*4+40+8) = 72
RL3 = fread(fid,1,'uint32');              %  4 bytes (CH+1)*4+8;
No_ch = fread(fid,1,'uint32');            %  4 bytes Number of channels
Sens_no = fread(fid,No_ch,'uint32');      %  4*CH bytes Channel numbers from calilist
RL4 = fread(fid,1,'uint32');              %  4 bytes (CH+1)*4+8;
RL5 = fread(fid,1,'uint32');              %  4 bytes If "interger format" then equal 2, if "single format" then equal 12


geninfo.ID=ID;
geninfo.FileDesc=FileDesc;
geninfo.NoOfChannels=No_ch;
geninfo.CrossrefTable=Sens_no'; % PBC 050225 added, NOTE that it must be a row vector, required in FileInput.m

if (RL5 == 12) 
    IntFileSubType='VTS-sim';       % denoted 'AFM/KSH standard' in con_int.pas
else
    IntFileSubType='MeasData';      % denoted 'Komprimeret (integer)' in con_int.pas
end

geninfo.Type=IntFileSubType;

err_str=[];

if strcmp(IntFileSubType,'MeasData')==1
    Temp = fread(fid,2+No_ch,'float');
    DT = Temp(2);
    T0 = Temp(1) - DT;
    
    for n=1:No_ch
        Scale(n)=Temp(n+2);
    end
    
    HeaderSize=ftell(fid);
    fseek(fid,0,'eof');
    FileSize=ftell(fid);
    MeasDataSize=FileSize - HeaderSize;
    fseek(fid,HeaderSize,'bof');   % move file position pointer to beginning of data
    
    No_samples = floor(MeasDataSize/(2*No_ch));
    geninfo.NoOfSamples=No_samples;
    geninfo.NoOfValidSamples=No_samples;
    
    if df
        DataMatrix_uncalib = fread(fid,[No_ch, No_samples], 'int16=>int16')';        % read all measurement values as 16 bit integers
        y = double(DataMatrix_uncalib) .* repmat(Scale,[No_samples 1]); % Scale data, vectorized for speed
        clear DataMatrix_uncalib;
    else
        y=[];
    end
    TimeVector = DT+T0 :DT: No_samples*DT + T0;
    
    % round to 4 decimal places (0.1 ms resolution)
    TimeVectorMs=round(10000*TimeVector);
    x = TimeVectorMs/10000;
    geninfo.Tmin=x(1);
    geninfo.Tmax=x(end);
    geninfo.TsAvg=(x(end)-x(1))/(No_samples - 1);   % actual average sampletime
    geninfo.SampleTime = geninfo.TsAvg;             % expected sampletime (no check-sum errors or missing samples here)
    geninfo.NoOfSamples = length(x);
        
    clear TimeVectorMs TimeVector;
    
    % throw away samples outside range between tmin and tmax
    if (isempty(tmin)|(tmin<0.0)|(tmin>x(end-1)))
        tmin=0.0;
    end
    if (isempty(tmax)|(tmax>x(end))|(tmax<=tmin))
        tmax=x(end);
    end
    TimeIndex=find((x>=tmin)&(x<=tmax));
    if df
        x=x(TimeIndex)';
        y=y(TimeIndex,:);
    else
        x=[];
        y=[];
    end
        
end

if strcmp(IntFileSubType,'VTS-sim')==1
    HeaderSize=ftell(fid) - 4;   % RL5 is not part of the header
    fseek(fid,0,'eof');                 % move file position pointer to end of file
    FileSize=ftell(fid);
    MeasDataSize=FileSize - HeaderSize;
    fseek(fid,HeaderSize,'bof');   % move file position pointer to beginning of data
    
    No_samples = floor(MeasDataSize/(4*(No_ch + 5)));
    geninfo.NoOfSamples=No_samples;
    geninfo.NoOfValidSamples=No_samples;
    
    if df
        % DataVector = fread(fid,'float');        % read all measurement values as 32 bit float
        DataMatrix = fread(fid,[No_ch + 5, No_samples], 'float32=>float32')';   % read all measurement values as 32 bit float
        TimeVector = double(DataMatrix(:,2));
        y = double(DataMatrix(:,5:No_ch+4));
    else
        %  timematrix=fread(file_id,[3 nos],'3*uint16=>uint16',ss-6)'; % 48 bits (3 * uint16 or 6 bytes) are used for timestamp in each sample
        fseek(fid,HeaderSize + 4,'bof');   % move file position pointer to beginning of time values
        TimeVector = double(fread(fid,[1, No_samples],'float32=>float32', 4*(No_ch+4)))'; %
        y=[];
    end
    
    
    
    % round to 4 decimal places (E-1 ms resolution)
    TimeVectorMs=round(10000*TimeVector);
    x = TimeVectorMs/10000;
    
    geninfo.Tmin=x(1);
    geninfo.Tmax=x(end);
    geninfo.TsAvg=(x(end)-x(1))/(No_samples - 1);   % actual average sampletime
    geninfo.SampleTime = geninfo.TsAvg;             % expected sampletime (no check-sum errors or missing samples here)
    geninfo.NoOfSamples = length(x);
    
    clear TimeVector TimeVectorMs DataMatrix;
    
    % throw away samples outside range between tmin and tmax
    if (isempty(tmin)|(tmin<0.0)|(tmin>x(end-1)))
        tmin=0.0;
    end
    if (isempty(tmax)|(tmax>x(end))|(tmax<=tmin))
        tmax=x(end);
    end
    TimeIndex=find((x>=tmin)&(x<=tmax));
    if df
        x=x(TimeIndex);
        y=y(TimeIndex,:);
    else
        x=[];
        y=[];
    end
end


% end of sub function: data_read