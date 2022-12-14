function [geninfo, xdata, ydata, errorstring, addout] = readmat(file, dataflag, channels, tmin, tmax)
% Reads VDAT-compatible matfile, including error checking. 
% Internal VDAT function.
%
% Syntax :
%
% [geninfo, xdata, ydata, errorstring, addout] = readmat(file, dataflag, tmin, tmax)
% 
% file       : Name of file to load
% dataflag   : If 0, time vector and data matrix are not read
% tmin       : Time from which data should be read
% tmax       : Time until which data should be read
% 
% geninfo     : Struct containing general information about the data
% xdata       : Time vector
% ydata       : Data matrix
% errorstring : Is the empty matrix if file reading was succesfull. 
%               Otherwise contains a string with description of error.
% addout      : Additional output parameters found in file.
% 
%
% JEB, September 2, 2002

GenInfo=[]; 
Xdata=[]; Ydata=[]; AddOut=[];
SensorSym=[]; SensorDesc=[];

load(file);  % hopefully this contains GenInfo, Xdata, Ydata, SensorSym and SensorDesc

%--------------------------------------------------------------------------
% Error checking, make sure the right variables are loaded from *.mat file
%--------------------------------------------------------------------------
geninfo=[];xdata=[];ydata=[];addout=[];
errorstring=[]; 

%--- GenInfo -----
if isempty(GenInfo)
    errorstring = 'GenInfo variable not found in *.mat file';return;
else
    if ~isstruct(GenInfo)
        errorstring = 'GenInfo variable must be a struct';return;
    end        
end

%--- Xdata -----
if isempty(Xdata)
    errorstring = 'Xdata variable not found in *.mat file';return;
else
    if ~isnumeric(Xdata)
        errorstring = 'Xdata must be numeric';return;
    end
end

%--- Ydata -----
if isempty(Ydata)
    errorstring = 'Ydata variable not found in *.mat file';return;
    if ~isnumeric(Ydata)
        errorstring = 'Ydata must be numeric';return;
    end
end

%--- SensorSym -----
if isempty(SensorSym)
    errorstring = 'SensorSym variable not found in *.mat file';return;
else
    if ~ischar(SensorSym)
         errorstring = 'SensorSym must be a char array';return;
    end
end

%--- SensorDesc-----
if isempty(SensorDesc)
    errorstring = 'SensorDesc variable not found in *.mat file';return;
else
    if ~ischar(SensorDesc)
        errorstring = 'SensorDesc must be a char array';return;
    end
end



if isempty(errorstring)
    % --- GenInfo -----
    if (~isfield(GenInfo,'Tmin'))||(~isfield(GenInfo,'Tmax'))||...
            (~isfield(GenInfo,'FullFileName'))||(~isfield(GenInfo,'SampleTime'))||...
            (~isfield(GenInfo,'Type'))||(~isfield(GenInfo,'TsAvg'))||(~isfield(GenInfo,'NoOfSamples'))
        errorstring = 'GenInfo must contain the fields Tmin, Tmax, FullFileName, SampleTime, Type, TsAvg, NoOfSamples';return;
    end
    
    % ---- Xdata ------
    Xsize = size(Xdata);
    if (length(Xsize)~=2) || (Xsize(1)<2) || (Xsize(2)~=1)
        errorstring = 'Xdata must have size [m 1], where m > 1';return;
    end
    
    % ---- Ydata -----
    Ysize = size(Ydata);
    if (length(Ysize)~=2) 
        errorstring = 'Ydata must have size [m n], where m>1, n>1';return;
    else
        if (Ysize(1)~=Xsize(1)) 
            errorstring = 'Ydata must have size [m n], where m = no. of samples';return;
        else
            if (Ysize(2)<1) 
                errorstring = 'Ydata must have size [m n], where n = no. of channels';return;
            end
        end
    end
    
    % ---- SensorSym
    SensorSymSize=size(SensorSym);
    if (length(SensorSymSize)~=2) 
        errorstring = 'SensorSym must have size [n a], n>1, a>1';return;
    else
        if (SensorSymSize(1)~=Ysize(2)) 
            errorstring = 'SensorSym must have size [n a], where n = no. of channels';return;
        end
    end
    
    % ---- SensorDesc
    SensorDescSize=size(SensorDesc);
    if (length(SensorDescSize)~=2) 
        errorstring = 'SensorDesc must have size [n b], n>1, b>1';return;
    else
        if (SensorDescSize(1)~=Ysize(2)) 
            errorstring = 'SensorDesc must have size [n b], where n = no. of channels';return;
        end
    end
    
end


%--------------------------------------------------------------
% End Error checking
%--------------------------------------------------------------

%--------------------------------------------------------------
% Making GenInfo Format for mat files exported from Vestas Online Toolkit
% as for VDF (to ensure transparency and reuse code) 
%--------------------------------------------------------------
fileInfo = dir(file);
GenInfo.FileSize = fileInfo.bytes;
GenInfo.FileExtension='mat';

if isfield(GenInfo,'TriggerTime') % rename the field
    GenInfo.Ttrig=GenInfo.TriggerTime;  
    GenInfo = rmfield(GenInfo,'TriggerTime');
end
%%% Note! the data placed in GenInfo.TurbineType: 'V90 2MW' for VOT < 4.1
%%% cannot be trusted since this is taken from the users phone book and not
%%% the turbine !!
% if isfield(GenInfo,'TurbineType') && ischar(GenInfo.TurbineType) % for VOT release   >4:          TurbineType: 'V90 2MW', make
%     GenInfo.TurbineTypeString=GenInfo.TurbineType;
%     GenInfo.TurbineType=str2num(deblank(GenInfo.TurbineType(2:5)) % convert to number
% end

% for VOT rel. < 4 GenInfo.Type="V80" where it should have said
% 'VMPglobalHdf5'
if strmatch(lower(GenInfo.FullFileName(end-4:end)),'.hdf5','exact')  % then mat file exported from VOT     REALLY STRANGE THAT THIS DOES NOT WORK: strmatch(lower(GenInfo.FullFileName),'.hdf5','exact')
    if isfield(GenInfo,'VOTRelease') % then make matfile info avaiable in FullFileName and create source file info
        GenInfo.SrcFullFileName=GenInfo.FullFileName;
        GenInfo.FullFileName=file;
        
        if isempty(GenInfo.Release) % chosen not to use str2double(GenInfo.VOTRelease(1:3))<4.1
            GenInfo.Release='N/A';
        end
        GenInfo.UniqueDataTs=unique(GenInfo.XdataTsVec); % ID the unique sample rates present in the data file
        GenInfo.UniqueDataFs=1./GenInfo.UniqueDataTs;
        if length(GenInfo.UniqueDataTs)>1
            GenInfo.DataHasBeenUpsampled=1;
            GenInfo.UpsampledToFs=max(GenInfo.UniqueDataFs);
            GenInfo.Notes = ['NOTE! Some channels has been upsampled to ' num2str(GenInfo.UpsampledToFs)  'Hz (outside VDAT). ' ...
                             'If orginal sample rate info is needed load data into matlab (GenInfo.XdataTsVec)'];
        else
            GenInfo.DataHasBeenUpsampled=0;
            %GenInfo.UpsampledToFs='N/A';
        end
    else % information is not avaiable
        GenInfo.VOTRelease='N/A'; 
        GenInfo.Release='N/A';
        GenInfo.SrcFullFileName=GenInfo.FullFileName;
        GenInfo.FullFileName=file;
    end
end


% in future VOT release parameters are taken directly from the turbine
% e.g. .TurbineType and then it should be displayed
% TurbineTypeString and make TurbineType double because it is used for
% making code in e.g. VDAT tools and VDAtstatistics turbine type dependent

%--------------------------------------------------------------
% End GenInfo formating 
%--------------------------------------------------------------

if isempty(errorstring)
    geninfo=GenInfo;
    if ~isempty('AddOut')
        addout=AddOut;
    end
    if ~dataflag % if dataflag = 0, only return GenInfo
        xdata=[];
        ydata=[];
    else         % if dataflag = 1, return also Xdata and Ydata
        if isempty(tmin)||isempty(tmax)     
            xdata=double(Xdata); % make sure to return a double type
            ydata=double(Ydata); % make sure to return a double type
        else
            TimeIx=find((double(Xdata)<=tmax)&(double(Xdata)>=tmin));
            xdata=double(Xdata(TimeIx));   % make sure to return a double type
            ydata=double(Ydata(TimeIx,:)); % make sure to return a double type
        end
    end
else
    geninfo=[];
    xdata=[];
    ydata=[];
end  
